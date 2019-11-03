library sky_core;

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:skyscrapeapi/src/message.dart';

import 'src/skyward_utils.dart';
import 'src/authenticator.dart';
import 'src/gradebook.dart';
import 'src/assignment.dart';
import 'data_types.dart';
import 'src/assignment_info.dart';
import 'src/parent_account_manager.dart';
import 'src/history.dart';

/// Skyward API Core is the heart of the API. It is essentially the only class you need to really use the API.
///
/// Skyward API Core uses your [_user] and your [_pass] to retrieve your [loginSessionRequiredBodyElements] from your [_baseURL] to get a login session.
/// [_baseURL] is a private value and cannot be modified after it is created.
class SkywardAPICore {
  /// Login session requirements retrieved
  Map<String, String> loginSessionRequiredBodyElements;

  /// Base URL to use for skyward page navigation
  ///
  /// You may just enter your login URL for skyward, though it is recommended to use a base URL.
  /// The API will automatically remove anything that comes after wsEAplus in your URL.
  ///
  /// If your base URL requires wsEAplus, contact the developer at hunter.han@gmail.com and he will help you
  String _baseURL;

  /// SkyMobile will automatically attempt to log back in if your session expired or too many requests were sent at once and skyward is refusing to respond.
  ///
  /// If you would like to disable this convenient feature, then you may do so in the constructor.
  /// If you would like the change the amount of times skyscrapeapi attempts to refresh your account, look at [refreshTimes]
  bool shouldRefreshWhenFailedLogin;

  /// Refresh Times will be useless if [shouldRefreshWhenFailedLogin] is false.
  ///
  /// The amount of times to refresh skyward authentication.
  /// If this value is set to a value less than 1, then skyscrapeapi will throw an error.
  /// If this value is set too high and something went wrong with your server/app or the API, skyscrapeapi will not stop, it'll keep trying for a looooooong time.
  int refreshTimes;

  /// Storing username and password for refresh when session expires
  String _user, _pass;

  /// Children accounts if account is a parent. If account is not parent then [children] and [_currentAccount] will stay null.
  List<SkywardAccount> children;
  SkywardAccount _currentAccount;

  /// The name of the current user.
  String currentUser;

  /// Constructor that instantiates [_baseURL].
  ///
  /// If [_baseURL] contains extra materials, it'll be cut down to the last "/"
  SkywardAPICore(this._baseURL,
      {this.shouldRefreshWhenFailedLogin = true, this.refreshTimes = 10}) {
    if (this.shouldRefreshWhenFailedLogin && this.refreshTimes < 1)
      throw SkywardError('Refresh times cannot be set to a value less than 1');
    if (!this._baseURL.endsWith('/')) {
      this._baseURL =
          this._baseURL.substring(0, this._baseURL.lastIndexOf('/') + 1);
    }
    if (_baseURL.contains("wsEAplus"))
      _baseURL = _baseURL.substring(
              0, _baseURL.indexOf('wsEAplus') + 'wsEAplus'.length) +
          "/";
  }

  /// If logging into Skyward succeeded
  ///
  /// [u] is the username and [p] is the password. The function uses these two parameters to login to skyward and retrieve the necessary items to continue skyward navigation.
  /// If the operation succeeded and the login requirements were successfully retrieved, the function returns true. If not, the function returns false.
  ///
  /// Resets parent accounts and current account names if the username and password applied are different than what was stored before.
  ///
  /// **TIP**
  /// You should call [initNewAccount] if you are initializing a new account, unless you are sure that the account you will be using is a student account.
  getSkywardAuthenticationCodes(String u, String p, {int timesRan = 0}) async {
    if (timesRan > refreshTimes) throw SkywardError('Maintenence error.');
    if (_user != u || _pass != p) {
      _user = u;
      _pass = p;
      children = null;
      _currentAccount = null;
      currentUser = null;
    }
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(_user, _pass, _baseURL);
    if (loginSessionMap != null) {
      loginSessionRequiredBodyElements = loginSessionMap;
      return true;
    } else if (shouldRefreshWhenFailedLogin) {
      return getSkywardAuthenticationCodes(u, p, timesRan: timesRan + 1);
    } else
      return false;
  }

  /// Initializes messages, children accounts, and student name.
  ///
  /// WIP: Messages not implemented yet.
  /// The function checks for children accounts and initializes them if found. It also automatically initializes Skyward messages for you.
  initNewAccount({int timesRan = 0}) async {
    List a = await _useSpecifiedFunctionsToRetrieveHTML('sfhome01.w', (html) {
      Document doc = parse(html);
      String delim = "sff.sv('sessionid', '";
      int startInd = html.indexOf(delim) + delim.length;
      String scrapedSessionid = html.substring(startInd, html.indexOf("'", startInd));
      loginSessionRequiredBodyElements['sessionid'] = scrapedSessionid;
      return [
        ParentAccountUtils.checkForParent(doc),
        doc
            .getElementById('sf_UtilityArea')
            ?.querySelector('.sf_utilUser')
            ?.text
            ?.trim()
      ];
    }, timesRan);
    children = a[0];
    currentUser = a[1];
  }

  getMessages({int timesRan = 0}) async {
    List<Message> messages = [];
    await _useSpecifiedFunctionsToRetrieveHTML('sfhome01.w', (html) {
      Document doc = parse(html);
      String delim = "sff.sv('sessionid', '";
      int startInd = html.indexOf(delim) + delim.length;
      String scrapedSessionid = html.substring(startInd, html.indexOf("'", startInd));
      loginSessionRequiredBodyElements['sessionid'] = scrapedSessionid;
      var tmp = doc.getElementById('MessageFeed')?.querySelectorAll('.feedItem.allowRemove');
      if(tmp != null && tmp.length >= 1){
        messages.addAll(MessageParser.parseMessage(html));
        return true;
      }
      return false;
    }, timesRan);

    if(messages.length > 0){
      int prevLen = 0;
      while(prevLen != messages.length){
        prevLen = messages.length;
        messages.addAll(await _useSpecifiedFunctionsToRetrieveHTML('sfhome01.w', MessageParser.parseMessage, timesRan, modifyLoginSess: (Map bodyElem){
          bodyElem['ishttp'] = 'true';
          bodyElem['lastMessageRowId'] = messages.last.dataId;
          bodyElem['action'] = 'moreMessages';
        }));
      }
    }

    for(Message m in messages){
      if(m.title?.attachment?.link != null){
        m.title.attachment = Link(_baseURL + m.title.attachment.link, m.title.attachment.text);
      }
    }

    return messages;
  }

  /// Switches the private [_currentAccount], if the operation failed, then false would be returned, else it would be false.
  bool switchUserIndex(int newIndex) {
    if (children == null || newIndex >= children.length) {
      return false;
    } else {
      _currentAccount = children[newIndex];
      return true;
    }
  }

  SkywardAccount retrieveAccountIfParent(){
    if(children != null) return _currentAccount;
    else return null;
  }

  _useSpecifiedFunctionsToRetrieveHTML(
      String page, Function parseHTML, timesRan,
      {Function(Map) modifyLoginSess}) async {
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Still could not retrieve correct information from assignments');
    var html;

    if (_currentAccount?.dataID == '0')
      throw SkywardError('Cannot use index 0 of children. It is ALL STUDENTS.');
    try {
      Map postcodes = Map.from(loginSessionRequiredBodyElements);
      if (_currentAccount != null)
        postcodes['studentId'] = _currentAccount.dataID;
      if (modifyLoginSess != null) {
        modifyLoginSess(postcodes);
      }
      html = await attemptPost(_baseURL + page, postcodes);

      if (parseHTML != null) {
        return parseHTML(html);
      } else {
        if (html == null) throw SkywardError('HTML Still Null');
        return html;
      }
    } catch (e, s) {
      print(s.toString());
      if (shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(_user, _pass);
        return _useSpecifiedFunctionsToRetrieveHTML(
            page, parseHTML, timesRan + 1,
            modifyLoginSess: modifyLoginSess);
      } else {
        throw SkywardError(
            'Something went wrong while trying to go to $page with ${parseHTML.toString()} which ran $timesRan times. Full trace error: ${e.toString()}');
      }
    }
  }

  List _gradeBookList;

  /// Initializes and scrapes the grade book HTML
  ///
  /// [timeRan] is the number of times the function ran. To avoid infinite loops, the function will throw an error if [timeRan] reaches a value greater than 10.
  /// The function will attempt to log back in when your session expires or an errors occurs.
  /// The function initializes the grade book HTML for parsing use.
  _initGradeBook({int timeRan = 0}) async {
    _gradeBookList = GradebookAccessor.initGradebookAndGradesHTML(
        await _useSpecifiedFunctionsToRetrieveHTML(
            'sfgradebook001.w', null, timeRan));
  }

  /// The terms retrieved from the grade book HTML. Returns a list of [Term].
  getGradeBookTerms() async {
    await _initGradeBook();
    return GradebookAccessor.getTermsFromDocCode(_gradeBookList);
  }

  /// The grade boxes retrieved from grade book HTML. Returns a list of [GridBox].
  getGradeBookGrades(List<Term> terms) async {
    try {
      await _initGradeBook();
      return GradebookAccessor.getGradeBoxesFromDocCode(_gradeBookList, terms);
    } catch (e) {
      throw SkywardError('Cannot parse gradebook grades.' + e.toString());
    }
  }

  /// The assignments from a specific term. Returns a list of [AssignmentsGridBox].
  getAssignmentsFromGradeBox(GradeBox gradeBox, {int timesRan = 0}) async {
    return await _useSpecifiedFunctionsToRetrieveHTML(
        'sfgradebook001.w', AssignmentAccessor.getAssignmentsDialog, timesRan,
        modifyLoginSess: (codes) {
      codes['action'] = 'viewGradeInfoDialog';
      codes['fromHttp'] = 'yes';
      codes['ishttp'] = 'true';
      codes['corNumId'] = gradeBox.courseNumber;
      codes['bucket'] = gradeBox.term.termName;
    });
  }

  /// The assignment info boxes from a specific assignment. Returns a list of [AssignmentInfoBox].
  getAssignmentInfoFromAssignment(Assignment assignment,
      {int timesRan = 0}) async {
    return await _useSpecifiedFunctionsToRetrieveHTML(
        'sfdialogs.w',
        AssignmentInfoAccessor.getAssignmentInfoBoxesFromHTML,
        timesRan, modifyLoginSess: (codes) {
      codes['action'] = 'dialog';
      codes['ishttp'] = 'true';
      codes['assignId'] = assignment.assignmentID;
      codes['gbId'] = assignment.gbID;
      codes['type'] = 'assignment';
      codes['student'] = assignment.studentID;
    });
  }

  /// Attempts to go to sfAcademicHistory if it's available. If not, it'll throw an error or return null.
  ///
  /// Returns a list of [SchoolYear].
  getHistory({int timesRan = 0}) async {
    return await _useSpecifiedFunctionsToRetrieveHTML(
      'sfacademichistory001',
      HistoryAccessor.parseGradebookHTML,
      timesRan,
    );
  }
}
