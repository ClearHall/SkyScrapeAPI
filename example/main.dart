import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'dart:io';

void main() async {
  final skyward = "https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w";
  var file = File('test/testCredentials.txt');
  User user;
  var contents;
  var terms;
  var gradeBook;
  var assignment;

  int indexOfTestingGradeBook = 1;
  int indexOfTestingAssignment = 4;

  if (await file.exists()) {
    contents = await file.readAsString();
    List split = contents.toString().split('\n');

    user = await SkyCore.login(split[0], split[1], skyward);
  }

  User a = User._();
  try {
    terms = await user.getTerms();
  } catch (e) {
    print('Should not fail: ' + e.toString());
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    gradeBook = await user.getGradebook();
  } catch (e) {
    print('Should not fail: ' + e);
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    assignment = (await user.getAssignmentsFrom(gradeBook[indexOfTestingGradeBook]));
  } catch (e) {
    print('Should succeed: ${e}');
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    print(await user.getAssignmentDetailsFrom(assignment[indexOfTestingAssignment]));
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    print(await user.getHistory());
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }
}
