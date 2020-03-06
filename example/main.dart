import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'dart:io';

void main() async {
  final skyward = SkywardAPICore(
      "https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w");
  var file = File('test/testCredentials.txt');
  var contents;
  var terms;
  var gradeBook;
  var assignment;

  int indexOfTestingGradeBook = 1;
  int indexOfTestingAssignment = 4;

  if (await file.exists()) {
    contents = await file.readAsString();
    List split = contents.toString().split('\n');

    if (!await skyward.getSkywardAuthenticationCodes(split[0], split[1])) {
      throw SkywardError('OH POOP WE FAIL TO LOG IN PLZ FIX BUG');
    }
  }

  try {
    terms = (await skyward.getTerms());
  } catch (e) {
    print('Should not fail: ' + e);
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    gradeBook = await skyward.getGradebook(terms);
  } catch (e) {
    print('Should not fail: ' + e.toString());
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    assignment = (await skyward.getAssignmentsFromGradeBox(gradeBook[indexOfTestingGradeBook]));
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    print(await skyward.getAssignmentInfoFromAssignment(assignment[indexOfTestingAssignment]));
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    print(await skyward.getHistory());
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }
}
