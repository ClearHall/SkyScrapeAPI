library skyscrapeapi;

import 'skywardUniversal.dart';
import 'skywardAuthenticator.dart';
import 'gradebookAccessor.dart';
import 'assignmentAccessor.dart';
import 'skywardAPITypes.dart';
import 'assignmentInfoAccessor.dart';
import 'historyAccessor.dart';

/// Skyward API Core is the heart of the API. It is essentially the only class you need to really use the API.
///
/// Skyward API Core uses your [user] and your [pass] to retrieve your [loginSessionRequiredBodyElements] from your [_baseURL] to get a login session.
/// [_baseURL] is a private value and cannot be modified after it is created.
class SkywardAPICore {
  /// Login session requirements retrieved
  Map<String, String> loginSessionRequiredBodyElements;

  /// Base URL to use for skyward page navigation
  String _baseURL;

  /// Storing username and password for refresh when session expires
  String user, pass;

  /// Constructor that instantiates [_baseURL].
  ///
  /// If [_baseURL] contains extra materials, it'll be cut down to the last "/"
  SkywardAPICore(this._baseURL) {
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
  getSkywardAuthenticationCodes(String u, String p) async {
    user = u;
    pass = p;
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(user, pass, _baseURL);
    if (loginSessionMap != null) {
      loginSessionRequiredBodyElements = loginSessionMap;
      return true;
    }
    return false;
  }

  // Temporary grade book html variable to store the grade book html for better efficiency.
  String _gradeBookHTML;

  /// Initializes and scrapes the grade book HTML
  ///
  /// [timeRan] is the number of times the function ran. To avoid infinite loops, the function will throw an error if [timeRan] reaches a value greater than 10.
  /// The function will attempt to log back in when your session expires or an errors occurs.
  /// The function initializes the grade book HTML for parsing use.
  _initGradeBook({int timeRan = 0}) async {
    if (timeRan > 10)
      throw SkywardError(
          'Could not refresh credentials at _initGradebook for user $user');
    if (_gradeBookHTML == null) {
      try {
        var result = await GradebookAccessor.getGradebookHTML(
            loginSessionRequiredBodyElements, _baseURL);
        _gradeBookHTML = result;
      } catch (e) {
        await getSkywardAuthenticationCodes(user, pass);
        await _initGradeBook(timeRan: timeRan + 1);
      }
    }
  }

  /// The terms retrieved from the grade book HTML. Returns a list of [Term].
  getGradeBookTerms() async {
    await _initGradeBook();
    return GradebookAccessor.getTermsFromDocCode();
  }

  /// The grade boxes retrieved from grade book HTML. Returns a list of [GridBox].
  getGradeBookGrades(List<Term> terms) async {
    try {
      await _initGradeBook();
      return GradebookAccessor.getGradeBoxesFromDocCode(_gradeBookHTML, terms);
    } catch (e) {
      throw SkywardError('Cannot parse gradebook grades.');
    }
  }

  /// The assignments from a specific term. Returns a list of [AssignmentsGridBox].
  getAssignmentsFromGradeBox(GradeBox gradeBox, {int timesRan = 0}) async {
    if (timesRan > 10)
      throw SkywardError(
          'Could not refresh credentials at _initGradebook for user $user}');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);

    String html;

    try {
      html = await AssignmentAccessor.getAssignmentsHTML(assignmentsPostCodes,
          _baseURL, gradeBox.courseNumber, gradeBox.term.termName);
    } catch (e) {
      await getSkywardAuthenticationCodes(user, pass);
      return getAssignmentsFromGradeBox(gradeBox, timesRan: timesRan + 1);
    }

    try {
      return AssignmentAccessor.getAssignmentsDialog(html);
    } catch (e) {
      throw SkywardError('Failed to parse assignments');
    }
  }

  /// The assignment info boxes from a specific assignment. Returns a list of [AssignmentInfoBox].
  getAssignmentInfoFromAssignment(Assignment assignment,
      {int timesRan = 0}) async {
    if (timesRan > 10)
      throw SkywardError(
          'Could not refresh credentials at _initGradebook for user $user}');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);
    var html;
    try {
      html = await AssignmentInfoAccessor.getAssignmentsDialogHTML(
          assignmentsPostCodes, _baseURL, assignment);
    } catch (e) {
      await getSkywardAuthenticationCodes(user, pass);
      getAssignmentInfoFromAssignment(assignment, timesRan: timesRan + 1);
    }
    try {
      return AssignmentInfoAccessor.getAssignmentInfoBoxesFromHTML(html);
    } catch (e) {
      throw SkywardError('Failed to parse assignment info');
    }
  }

  /// Attempts to go to sfAcademicHistory if it's available. If not, it'll throw an error or return null.
  ///
  /// Returns a list of [SchoolYear].
  getHistory({int timesRan = 0}) async {
    if (timesRan > 10)
      throw SkywardError(
          'Could not refresh credentials at _initGradebook for user $user}');
    var html;
    try {
      html = await HistoryAccessor.getGradebookHTML(
          loginSessionRequiredBodyElements, _baseURL);
    } catch (e) {
      await getSkywardAuthenticationCodes(user, pass);
      return getHistory(timesRan: timesRan + 1);
    }
    try {
      return (await HistoryAccessor.parseGradebookHTML(html));
    } catch (e) {
      throw SkywardError(
          'Could not parse history. This district most likely does not support academic history');
    }
  }
}
