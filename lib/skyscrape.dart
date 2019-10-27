library sky_core;

import 'src/skywardUniversal.dart';
import 'src/skywardAuthenticator.dart';
import 'src/gradebookAccessor.dart';
import 'src/assignmentAccessor.dart';
import 'data_types.dart';
import 'src/assignmentInfoAccessor.dart';
import 'src/historyAccessor.dart';

/// Skyward API Core is the heart of the API. It is essentially the only class you need to really use the API.
///
/// Skyward API Core uses your [user] and your [pass] to retrieve your [loginSessionRequiredBodyElements] from your [_baseURL] to get a login session.
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
  String user, pass;

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
  getSkywardAuthenticationCodes(String u, String p, {int timesRan = 0}) async {
    if (timesRan > refreshTimes) throw SkywardError('Maintenence error.');
    user = u;
    pass = p;
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(user, pass, _baseURL);
    if (loginSessionMap != null) {
      loginSessionRequiredBodyElements = loginSessionMap;
      return true;
    } else if (shouldRefreshWhenFailedLogin) {
      return getSkywardAuthenticationCodes(u, p, timesRan: timesRan + 1);
    } else
      return false;
  }

  _useSpecifiedFunctionsToRetrieveHTML(
      String page, Function parseHTML, timesRan,
      {Function(Map) modifyLoginSess}) async {
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Still could not retrieve correct information from assignments');
    var html;

    try {
      Map postcodes = Map.from(loginSessionRequiredBodyElements);
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
    } catch (e) {
      if (shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
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
