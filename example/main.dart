import 'dart:io';

import 'file:///C:/Users/Hunter%20Han/StudioProjects/SkyScrapeAPI/lib/src/core/data_types.dart';
import 'file:///C:/Users/Hunter%20Han/StudioProjects/SkyScrapeAPI/lib/src/core/login.dart';

void main() async {
  print('start');
  final skyward =
      "https://cors-anywhere.herokuapp.com/https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w";
  var file = File('test/testCredentials.txt');
  var contents;
  var terms;
  var gradebook;
  User person;

  if (await file.exists()) {
    contents = await file.readAsString();
    List split = contents.toString().split('\n');

    person = await SkyCore.login(split[0], split[1], skyward);
  }

  try {
    gradebook = await person.getGradebook();
  } catch (e) {
    print('Should not fail: ' + e.toString());
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    List<AssignmentProperty> props =
    (await person.getAssignmentDetailsFrom(gradebook[0].quickAssignments[0]));
    print(props);
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }

  try {
    print(await person.getStudentProfile());
  } catch (e) {
    print('Should succeed: ${e.toString()}');
    throw SkywardError('SHOULD SUCCEED');
  }

  print(terms);
  print(gradebook);
  print(await person.getHistory());
}
