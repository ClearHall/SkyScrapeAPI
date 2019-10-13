library sky_core;

import 'skywardUniversal.dart';
import 'src/skywardAuthenticator.dart';
import 'src/gradebookAccessor.dart';
import 'src/assignmentAccessor.dart';
import 'skywardAPITypes.dart';
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
  SkywardAPICore(this._baseURL, {this.shouldRefreshWhenFailedLogin = true , this.refreshTimes = 10}) {
    if(this.shouldRefreshWhenFailedLogin && this.refreshTimes < 1) throw SkywardError('Refresh times cannot be set to a value less than 1');
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
    if(timesRan > refreshTimes) return false;
    user = u;
    pass = p;
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(user, pass, _baseURL);
    if (loginSessionMap != null) {
      loginSessionRequiredBodyElements = loginSessionMap;
      return true;
    }else if(shouldRefreshWhenFailedLogin){
      return getSkywardAuthenticationCodes(u, p, timesRan: timesRan + 1);
    }else
      return false;
  }

  // Temporary grade book html variable to store the grade book html for better efficiency.
  List _gradeBookList;

  /// Initializes and scrapes the grade book HTML
  ///
  /// [timeRan] is the number of times the function ran. To avoid infinite loops, the function will throw an error if [timeRan] reaches a value greater than 10.
  /// The function will attempt to log back in when your session expires or an errors occurs.
  /// The function initializes the grade book HTML for parsing use.
  _initGradeBook({int timeRan = 0}) async {
    if (timeRan > refreshTimes)
      throw SkywardError(
          'Unexpected error, _gradeBookHTML is still null');
    if (_gradeBookList == null) {
      try {
        var result = await GradebookAccessor.getGradebookHTML(
            loginSessionRequiredBodyElements, _baseURL);
        _gradeBookList = result;
      } catch (e) {
        if(shouldRefreshWhenFailedLogin) {
          await getSkywardAuthenticationCodes(user, pass);
          await _initGradeBook(timeRan: timeRan + 1);
        }else throw SkywardError('Session could have expired, failed to get gradebook');
      }
    }
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
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Still could not retrieve correct information from assignments');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);

    String html;

    try {
      html = await AssignmentAccessor.getAssignmentsHTML(assignmentsPostCodes,
          _baseURL, gradeBox.courseNumber, gradeBox.term.termName);
    } catch (e) {
        if(shouldRefreshWhenFailedLogin) {
          await getSkywardAuthenticationCodes(user, pass);
          return getAssignmentsFromGradeBox(gradeBox, timesRan: timesRan + 1);
        }else throw SkywardError('Session could have expired, failed to get assignment');
    }

    if(html == null) throw SkywardError('Somehow, Assignment HTML is still null and got passed first error check');

    try {
      return AssignmentAccessor.getAssignmentsDialog(html);
    } catch (e) {
      if(shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
        return getAssignmentsFromGradeBox(gradeBox, timesRan: timesRan + 1);
      }else throw SkywardError('Session could have expired, failed to parse assignment');
    }
  }

  /// The assignment info boxes from a specific assignment. Returns a list of [AssignmentInfoBox].
  getAssignmentInfoFromAssignment(Assignment assignment,
      {int timesRan = 0}) async {
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Could not get assignment info');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);
    var html;
    try {
      html = await AssignmentInfoAccessor.getAssignmentsDialogHTML(
          assignmentsPostCodes, _baseURL, assignment);
    } catch (e) {
      if(shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
        return getAssignmentInfoFromAssignment(assignment, timesRan: timesRan + 1);
      }else throw SkywardError('Session could have expired, failed to get assignment info');
    }
    try {
      return AssignmentInfoAccessor.getAssignmentInfoBoxesFromHTML(html);
    } catch (e) {
      if(shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
        return getAssignmentInfoFromAssignment(assignment, timesRan: timesRan + 1);
      }else throw SkywardError('Session could have expired, failed to parse assignment info');
    }
  }

  /// Attempts to go to sfAcademicHistory if it's available. If not, it'll throw an error or return null.
  ///
  /// Returns a list of [SchoolYear].
  getHistory({int timesRan = 0}) async {
    if (timesRan > refreshTimes)
      throw SkywardError(
          'Failed to get history');
    var html;
    try {
      html = await HistoryAccessor.getGradebookHTML(
          loginSessionRequiredBodyElements, _baseURL);
    } catch (e) {
      if(shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
        return getHistory(timesRan: timesRan + 1);
      }else throw SkywardError('Session could have expired, failed to get history');
    }
    try {
      return (await HistoryAccessor.parseGradebookHTML(html));
    } catch (e) {
      if(shouldRefreshWhenFailedLogin) {
        await getSkywardAuthenticationCodes(user, pass);
        return getHistory(timesRan: timesRan + 1);
      }else throw SkywardError('Session could have expired, failed to get history or history not supported');
    }
  }
}
