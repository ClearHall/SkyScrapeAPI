library sky_core;

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:skyscrapeapi/src/student_related/student_info.dart';

import 'src/skyward_utils.dart';
import 'src/authenticator.dart';
import 'src/gradebook/gradebook.dart';
import 'src/gradebook/assignment.dart';
import 'data_types.dart';
import 'src/gradebook/assignment_info.dart';
import 'src/student_related/parent.dart';
import 'src/student_related/history.dart';
import 'src/student_related/message.dart';

/// Skyward API Core is the heart of the API. It is essentially the only class you need to really use the API.
///
/// Skyward API Core uses your [_user] and your [_pass] to retrieve your [_loginCache] from your [_baseURL] to get a login session.
/// [_baseURL] is a private value and cannot be modified after it is created.
class SkyCore {
  static Future<User> login(String username, String pass, String url,
      {refreshTimes: 10, shouldRefreshWhenFailedLogin: true}) async {
    User user =
        User._(url, shouldRefreshWhenFailedLogin, refreshTimes, username, pass);
    if (await user.login()) {
      return user;
    } else {
      throw SkywardError("Invalid Credentials");
    }
  }
}

class User {
  /// Login session requirements retrieved
  Map<String, String> _loginCache;

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

  /// Children accounts if account is a parent. If account is not parent then [_children] and [_currentAccount] will stay null.
  bool _isParent = false;
  List<Child> _children;
  Child _currentAccount;

  /// The name of the current user.
  Future _homePage;

  User._(this._baseURL, this.shouldRefreshWhenFailedLogin, this.refreshTimes,
      this._user, this._pass) {
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

  /// Initializes messages, children accounts, and student name.
  ///
  /// The function checks for children accounts and initializes them if found. It also automatically initializes Skyward messages for you.
  void _initNewAccount({int timesRan = 0}) {
    _homePage = _useSpecifiedFunctionsToRetrieveHTML('sfhome01.w', (html) {
      Document doc = parse(html);
      String delim = "sff.sv('sessionid', '";
      int startInd = html.indexOf(delim) + delim.length;
      String scrapedSessionid =
          html.substring(startInd, html.indexOf("'", startInd));
      _loginCache['sessionid'] = scrapedSessionid;
      return [
        ParentUtils.checkForParent(doc),
        doc
            .getElementById('sf_UtilityArea')
            ?.querySelector('.sf_utilUser')
            ?.text
            ?.trim()
      ];
    }, timesRan);

    _homePage.then((val) {
      _children = val[0];
      if (_children != null) {
        _isParent = true;
        _children.removeAt(0);
        switchUserIndex(0);
      }
    });
  }

  void debugPrint() {
    print('Debug Log');
    print('Login Session Elements: $_loginCache');
    print('Base URL: $_baseURL');
    print('Credentials: \n\tUsername: $_user\n\tPassword: $_pass');
    print(
        'Settings: \n\tRefresh Times: $refreshTimes\n\tShould Refresh Login Credentials: $shouldRefreshWhenFailedLogin');
    print('Parent account? $_isParent');
  }

  bool isParent() {
    return _isParent;
  }

  Future<bool> login({int timesRan = 0}) async {
    if (timesRan > refreshTimes) throw SkywardError('Maintenence error.');
    if (_user == null || _pass == null)
      throw SkywardError("User or password has not been initialized!");
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(_user, _pass, _baseURL);
    if (loginSessionMap != null) {
      _loginCache = loginSessionMap;
      _initNewAccount();
      return true;
    } else if (shouldRefreshWhenFailedLogin) {
      return login(timesRan: timesRan + 1);
    } else
      return false;
  }

  Future<String> getName() async {
    List a = await _homePage;
    return a[1];
  }

  Future<List<Message>> getMessages({int timesRan = 0}) async {
    List<Message> messages = [];
    await _useSpecifiedFunctionsToRetrieveHTML('sfhome01.w', (html) {
      Document doc = parse(html);
      String delim = "sff.sv('sessionid', '";
      int startInd = html.indexOf(delim) + delim.length;
      String scrapedSessionid =
          html.substring(startInd, html.indexOf("'", startInd));
      _loginCache['sessionid'] = scrapedSessionid;
      var tmp = doc
          .getElementById('MessageFeed')
          ?.querySelectorAll('.feedItem.allowRemove');
      if (tmp != null && tmp.length >= 1) {
        messages.addAll(MessageParser.parseMessage(html));
        return true;
      }
      return false;
    }, timesRan);

    if (messages.length > 0) {
      int prevLen = 0;
      while (prevLen != messages.length) {
        prevLen = messages.length;
        messages.addAll(await _useSpecifiedFunctionsToRetrieveHTML(
            'sfhome01.w', MessageParser.parseMessage, timesRan,
            modifyLoginSess: (Map bodyElem) {
          bodyElem['ishttp'] = 'true';
          bodyElem['lastMessageRowId'] = messages.last.dataId;
          bodyElem['action'] = 'moreMessages';
        }));
      }
    }

    for (Message m in messages) {
      if (m.title?.attachment?.link != null) {
        m.title.attachment =
            Link(_baseURL + m.title.attachment.link, m.title.attachment.text);
      }
    }

    return messages;
  }

  /// Switches the private [_currentAccount], if the operation failed, then false would be returned, else it would be false.
  bool switchUserIndex(int newIndex) {
    if (_children == null || newIndex >= _children.length) {
      return false;
    } else {
      _currentAccount = _children[newIndex];
      return true;
    }
  }

  List<String> getChildrenNames() {
    if (isParent()) {
      List<String> list = List();
      for (Child child in _children) {
        list.add(child.name);
      }
      return list;
    } else
      return null;
  }

  int numberOfChildren() {
    if (isParent())
      return _children.length;
    else
      return -1;
  }

  Child retrieveAccountIfParent() {
    if (isParent())
      return _currentAccount;
    else
      return null;
  }

  _useSpecifiedFunctionsToRetrieveHTML(
      String page, Function parseHTML, timesRan,
      {Function(Map) modifyLoginSess, bool debug = false}) async {
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Still could not retrieve correct information from assignments');
    var html;

    if (_currentAccount?.dataID == '0')
      throw SkywardError('Cannot use index 0 of children. It is ALL STUDENTS.');
    try {
      Map postcodes = Map.from(_loginCache);
      if (_currentAccount != null)
        postcodes['studentId'] = _currentAccount.dataID;
      if (modifyLoginSess != null) {
        modifyLoginSess(postcodes);
      }
      html = await attemptPost(_baseURL + page, postcodes);

      if (parseHTML != null) {
        if (debug) print(html);
        return parseHTML(html);
      } else {
        if (html == null) throw SkywardError('HTML Still Null');
        return html;
      }
    } catch (e, s) {
      print(s.toString());
      print(e.toString());
      print(
          'This error could be caused by a parent account not finished initializing or expired session code.');
      if (shouldRefreshWhenFailedLogin) {
        await login();
        return _useSpecifiedFunctionsToRetrieveHTML(
            page, parseHTML, timesRan + 1,
            modifyLoginSess: modifyLoginSess);
      } else {
        throw SkywardError(
            'Something went wrong while trying to go to $page with ${parseHTML.toString()} which ran $timesRan times. Full trace error: ${e.toString()}');
      }
    }
  }

  List _internalGradebookStorage;
  List<Term> _terms;
  Gradebook _gradebook;

  /// Initializes and scrapes the grade book HTML
  ///
  /// [timeRan] is the number of times the function ran. To avoid infinite loops, the function will throw an error if [timeRan] reaches a value greater than 10.
  /// The function will attempt to log back in when your session expires or an errors occurs.
  /// The function initializes the grade book HTML for parsing use.
  _initGradeBook({int timeRan = 0}) async {
    if (timeRan > this.refreshTimes)
      throw SkywardError('Gradebook initializing took too long. Failing!');
    if (_children != null && _currentAccount == null)
      throw SkywardError(
          'It looks like this is a parent account. Please choose a child account before continuing!');
    try {
      if (_internalGradebookStorage == null) {
        _internalGradebookStorage = await _useSpecifiedFunctionsToRetrieveHTML(
            'sfgradebook001.w',
            GradebookAccessor.initGradebookAndGradesHTML,
            timeRan);
      }
      _terms = GradebookAccessor.getTermsFromDocCode(_internalGradebookStorage);
      _gradebook = GradebookAccessor.getGradeBoxesFromDocCode(
          _internalGradebookStorage, _terms);
    } catch (e) {
      _internalGradebookStorage = null;
      print("Couldn't get your gradebook! Trying again.");
      await _initGradeBook(timeRan: timeRan + 1);
    }
  }

  /// The terms retrieved from the grade book HTML. Returns a list of [Term].
  Future<List<Term>> getTerms({timesRan = 0}) async {
    await _initGradeBook();
    return _terms;
  }

  /// The gradebook retrieved!
  Future<Gradebook> getGradebook({timesRan = 0}) async {
    await _initGradeBook();
    return _gradebook;
  }

  /// The assignments from a specific term. Returns a list of [AssignmentNode].
  Future<List<AssignmentNode>> getAssignmentsFrom(Grade gradeBox,
      {int timesRan = 0}) async {
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

  /// The assignment info boxes from a specific assignment. Returns a list of [AssignmentProperty].
  Future<List<AssignmentProperty>> getAssignmentDetailsFrom(
      Assignment assignment,
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
  Future<List<SchoolYear>> getHistory({int timesRan = 0}) async {
    return await _useSpecifiedFunctionsToRetrieveHTML(
      'sfacademichistory001',
      HistoryAccessor.parseGradebookHTML,
      timesRan,
    );
  }

  Future<StudentInfo> getStudentProfile({int timesRan = 0}) async {
    StudentInfo info = await _useSpecifiedFunctionsToRetrieveHTML(
        'sfstudentinfo001.w', StudentInfoParser.parseStudentID, timesRan);
    if(info.studentAttributes.containsKey('Student Image Href Link')){
      info.studentAttributes['Student Image Href Link'] = _baseURL + info.studentAttributes['Student Image Href Link'];
    }
    return info;
  }
}
