library skyscrapeapi;
/*
  SKYSCRAPEAPI
  In-Code documentation will be written for those who would like to modify the API for their own purposes.
 */

import 'package:skyscrapeapi/skywardUniversal.dart';

import 'skywardAuthenticator.dart';
import 'gradebookAccessor.dart';
import 'assignmentAccessor.dart';
import 'skywardAPITypes.dart';
import 'assignmentInfoAccessor.dart';
import 'historyAccessor.dart';

class SkywardAPICore {
  Map<String, String> loginSessionRequiredBodyElements;
  String _baseURL;
  String _gradebookHTML;
  GradebookAccessor gradebookAccessor = GradebookAccessor();
  String user, pass;

  SkywardAPICore(this._baseURL) {
    if (_verifyBaseURL(this._baseURL)) {
      this._baseURL =
          this._baseURL.substring(0, this._baseURL.lastIndexOf('/') + 1);
    }
    if (_baseURL.contains("wsEAplus"))
      _baseURL = _baseURL.substring(
              0, _baseURL.indexOf('wsEAplus') + 'wsEAplus'.length) +
          "/";
  }

  bool _verifyBaseURL(String url) {
    return !url.endsWith('/');
  }

  //Returns true for success and false for failed.
  getSkywardAuthenticationCodes(String u, String p) async {
    user = u;
    pass = p;
    var loginSessionMap =
        await SkywardAuthenticator.getNewSessionCodes(user, pass, _baseURL);
    if (loginSessionMap != null) {
      loginSessionRequiredBodyElements = loginSessionMap;
    }
  }

  _initGradebook({int timeRan = 0}) async {
    if (timeRan > 10) throw SkywardError('Could not refresh credentials at _initGradebook for user $user');
    if (_gradebookHTML == null) {
      try{
        var result = await gradebookAccessor.getGradebookHTML(
            loginSessionRequiredBodyElements, _baseURL);
         _gradebookHTML = result;
      }catch(e){
          await getSkywardAuthenticationCodes(user, pass);
          await _initGradebook(timeRan: timeRan + 1);
      }
    }
  }

  getGradeBookTerms() async {
    await _initGradebook();
    return gradebookAccessor.getTermsFromDocCode();
  }

  getGradeBookGrades(List<Term> terms) async {
    try {
      await _initGradebook();
      return gradebookAccessor.getGradeBoxesFromDocCode(_gradebookHTML, terms);
    } catch (e) {
      throw SkywardError('Cannot parse gradebook grades.');
    }
  }

  getAssignmentsFromGradeBox(GradeBox gradeBox, {int timesRan = 0}) async {
    if (timesRan > 10) throw SkywardError('Could not refresh credentials at _initGradebook for user $user}');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);

    String html;

    try {
      html = await AssignmentAccessor.getAssignmentsHTML(
          assignmentsPostCodes,
          _baseURL, gradeBox.courseNumber, gradeBox.term.termName);
    }catch(e){
      await getSkywardAuthenticationCodes(user, pass);
      return getAssignmentsFromGradeBox(gradeBox, timesRan: timesRan + 1);
    }

      try {
        return AssignmentAccessor.getAssignmentsDialog(html);
      } catch (e) {
        throw SkywardError('Failed to parse assignments');
      }
  }

  getAssignmentInfoFromAssignment(Assignment assignment,
      {int timesRan = 0}) async {
    if (timesRan > 10) throw SkywardError('Could not refresh credentials at _initGradebook for user $user}');
    Map<String, String> assignmentsPostCodes =
        Map.from(loginSessionRequiredBodyElements);
    var html;
    try {
      html = await AssignmentInfoAccessor.getAssignmentsDialogHTML(
          assignmentsPostCodes, _baseURL, assignment);
    }catch(e) {
      await getSkywardAuthenticationCodes(user, pass);
      getAssignmentInfoFromAssignment(assignment,
          timesRan: timesRan + 1);
    }
    try {
      return AssignmentInfoAccessor.getAssignmentInfoBoxesFromHTML(html);
    } catch (e) {
      throw SkywardError('Failed to parse assignment info');
    }
  }

  getHistory({int timesRan = 0}) async {
    if (timesRan > 10) throw SkywardError('Could not refresh credentials at _initGradebook for user $user}');
    var html;
    try{
      html = await HistoryAccessor.getGradebookHTML(
          loginSessionRequiredBodyElements, _baseURL);
    } catch(e) {
      await getSkywardAuthenticationCodes(user, pass);
      return getHistory(timesRan: timesRan + 1);
    }
    try {
      return (await HistoryAccessor.parseGradebookHTML(html));
    } catch (e) {
      throw SkywardError('Could not parse history. This district most likely does not support academic history');
    }
  }
}