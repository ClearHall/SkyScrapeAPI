library sky_core;

import 'package:html/dom.dart';
import 'package:html/parser.dart';

import '../gradebook/assignment.dart';
import '../gradebook/assignment_info.dart';
import '../gradebook/gradebook.dart';
import '../misc/parent.dart';
import '../misc/skyward_utils.dart';
import '../student_related/history.dart';
import '../student_related/message.dart';
import '../student_related/student_info.dart';
import 'authenticator.dart';
import 'data_types.dart';

/// Root class that controls the creation of new [User] accounts.
class SkyCore {
  static Future<User> login(String username, String pass, String url,
      {refreshTimes: 10,
      shouldRefreshWhenFailedLogin: true,
      ignoreExceptions: true}) async {
    User user = User._(url, shouldRefreshWhenFailedLogin, refreshTimes,
        username, pass, !ignoreExceptions);
    if (await user.login()) {
      return user;
    } else {
      throw SkywardError("Invalid Credentials");
    }
  }
}

/// A logged in user that allows for all skyward actions to be executed.
class User {
  /// Login session requirements retrieved
  Map<String, String> _loginCache;

  /// Whether or not debug messages will be shown.
  bool _debugMessagesEnabled;

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
  ///
  /// **KEY: THIS IS NOT A LIMIT TO HOW MANY TIMES THE OBJECT CAN REFRESH, [User] CAN REFRESH INFINITElY**
  /// ## Benefits of this
  /// - Prevents infinite loops
  /// - Provides detailed error information to the console when an error occurs.
  int refreshTimes;

  /// Storing username and password for refresh when session expires
  ///
  /// These values are private for a reason.
  String _user, _pass;

  /// Children accounts if account is a parent. If account is not parent then [_children] and [_currentAccount] will stay null.
  bool _isParent = false;
  List<Child> _children;
  Child _currentAccount;

  /// A temporary future of the values retrieved from [_initNewAccount()] This an internal method and variable and does not need to be understood.
  List _homePage;

  /// A private constructor only accessible to the [SkyCore] class.
  User._(this._baseURL, this.shouldRefreshWhenFailedLogin, this.refreshTimes,
      this._user, this._pass, this._debugMessagesEnabled) {
    if (this.shouldRefreshWhenFailedLogin && this.refreshTimes < 1)
      throw SkywardError.usingErrorCode(ErrorCode.RefreshTimeLessThanOne);
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
  /// The function checks for children accounts and initializes them if found.
  void _initNewAccount({int timesRan = 0, forceRefresh = false}) async {
    if (_homePage == null || forceRefresh) {
      _homePage = await _useSpecifiedFunctionsToRetrieveHTML(
          'sfhome01.w', _attemptInitHtml, timesRan);
      if (_isParent) {
        _children = _homePage[0];
        if (_children != null) {
          _children.removeAt(0);
          switchUserIndex(0);
        }
      }
    }
  }

  List<Object> _attemptInitHtml(html) {
    try {
      Document doc = parse(html);
      return [ParentUtils.checkForParent(doc), _findUserInfo(doc: doc)];
    } catch (e) {
      _internalPrint(e.toString() +
          '\nAn error occured and we could not initialize your account!');
      return null;
    }
  }

  String _findUserInfo({String html, Document doc}) {
    try {
      if (html != null) {
        String look =
            '<li class="sf_utilUser notranslate" valign="middle" align="center">';
        int start = html.indexOf(look) + look.length;
        return html.substring(start, html.indexOf('</li>', start)).trim();
      } else if (doc != null) {
        return doc
            .getElementById('sf_UtilityArea')
            ?.querySelector('.sf_utilUser')
            ?.text
            ?.trim();
      }
    } catch (e) {
      _internalPrint(e.toString() +
          '\nAn error occured and we could not initialize your account!');
      return null;
    }
    return null;
  }

  /// Prints detailed information about the object for debugging purposes.
  void debugPrint() {
    print('Debug Log');
    print('Login Session Elements: $_loginCache');
    print('Base URL: $_baseURL');
    print(
        'Settings: \n\tRefresh Times: $refreshTimes\n\tShould Refresh Login Credentials: $shouldRefreshWhenFailedLogin');
    print('Parent account? $_isParent');
  }

  /// Just to see if the user is a parent or not.
  bool isParent() {
    return _isParent;
  }

  /// Logs into the specified skyward links.
  ///
  /// If the user is a parent then the function will take a little longer to run because it will attempt to initialize the account automatically.
  Future<bool> login({int timesRan = 0}) async {
    if (timesRan > refreshTimes)
      throw SkywardError.usingErrorCode(ErrorCode.UnderMaintenance);
    if (_user == null || _pass == null)
      throw SkywardError("User or password has not been initialized!");
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(_user, _pass, _baseURL);
    if (loginSessionMap != null) {
      _loginCache = loginSessionMap;
      _isParent = (loginSessionMap['User-Type'] == '1');
      if (isParent()) await _initNewAccount();
      return true;
    } else if (shouldRefreshWhenFailedLogin) {
      return login(timesRan: timesRan + 1);
    } else
      return false;
  }

  /// Initializes and retrieves the user's name.
  Future<String> getName() async {
    await _initNewAccount();
    return _homePage == null ? null : _homePage[1];
  }

  /// Scrapes the skyward account homepage messages. This takes a long time to run because it scrapes everything from top to bottom by date.
  /// I recommend you run this function asynchronously on a separate thread to maximize efficiency.
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

  /// Returns a list of the parent's children names. If the account is not a parent, then [null] will be returned.
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

  /// Retrieves the number of children that the parent contains. If the user is not a parent, then the function will return -1
  int numberOfChildren() {
    if (isParent())
      return _children.length;
    else
      return -1;
  }

  /// Returns the current child's information.
  Child retrieveAccountIfParent() {
    if (isParent())
      return _currentAccount;
    else
      return null;
  }

  void _internalPrint(String m) {
    if (_debugMessagesEnabled) print(m);
  }

  //TODO: Create a base accessor class and pass that instead of parseHTML function!
  /// Internal support function!
  _useSpecifiedFunctionsToRetrieveHTML(
      String page, Function parseHTML, timesRan,
      {Function(Map) modifyLoginSess}) async {
    if (timesRan > refreshTimes)
      throw SkywardError.usingErrorCode(ErrorCode.ExceededRefreshTimeLimit);
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

      if (_homePage == null) _homePage = [null, _findUserInfo(html: html)];
      if (parseHTML != null) {
        var a = parseHTML(html);
        if (a == null)
          throw SkywardError('Object returned is null!');
        else
          return a;
      } else {
        if (html == null) throw SkywardError('HTML Still Null');
        return html;
      }
    } catch (e, s) {
      _internalPrint(s.toString());
      _internalPrint(e.toString());
      _internalPrint(
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

  /// Internal variables for caching grade book.
  List _internalGradebookStorage;
  List<GradebookSector> _gradebooks;

  /// Initializes and scrapes the grade book HTML. Internal method.
  _initGradeBook({int timeRan = 0}) async {
    if (timeRan > this.refreshTimes)
      throw SkywardError.usingErrorCode(ErrorCode.ExceededRefreshTimeLimit);
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
      _gradebooks = [];
      Document parsed = parse(_internalGradebookStorage.last ?? "");
      for (int i = 0; i < _internalGradebookStorage.length - 1; i++) {
        _gradebooks.add(GradebookAccessor.getGradeBoxesFromDocCode(
            _internalGradebookStorage[i], parsed));
      }
    } catch (e, s) {
      _internalGradebookStorage = null;
      _internalPrint(e.toString() +
          "\n" +
          s.toString() +
          "\nCouldn't get your gradebook! Trying again.");
      await _initGradeBook(timeRan: timeRan + 1);
    }
  }

  /// The gradebook retrieved!
  Future<Gradebook> getGradebook({timesRan = 0, forceRefresh = false}) async {
    if (forceRefresh) _internalGradebookStorage = null;
    await _initGradeBook();
    return Gradebook(_gradebooks);
  }

  /// The assignments from a specific term. Returns a list of [AssignmentNode].
  Future<DetailedGradingPeriod> getAssignmentsFrom(Grade gradeBox,
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
      codes['gbId'] = assignment.courseID;
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
    if (info.studentAttributes.containsKey('Student Image Href Link')) {
      info.studentAttributes['Student Image Href Link'] =
          _baseURL + info.studentAttributes['Student Image Href Link'];
    }
    return info;
  }
}
