import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  String url =
      'https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w';

  List<Term> terms;
  Gradebook gradebook;

  group('Group tests on network WITH enabled refresh', () {
    test('test regular usage', () async {
      Map<String, String> env = Platform.environment;
      User person = await SkyCore.login(env['USERNAME'], env['PASSWORD'], url);

      print(await person.getName());
      try {
        gradebook = await person.getGradebook();
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      //print(person.numberOfChildren());

      try {
        print((await person.getAssignmentsFrom(gradebook.classes[0].grades[0])));
      } catch (e) {
        throw SkywardError('SHOULD SUCCEED');
      }

//      try {
//        print(await skyward.getAssignmentInfoFromAssignment(assignment[indexOfTestingAssignment]));
//      } catch (e) {
//        print('Should succeed: ${e.toString()}');
//        throw SkywardError('SHOULD SUCCEED');
//      }

      try {
        List<AssignmentProperty> props = (await person
            .getAssignmentDetailsFrom(gradebook.quickAssignments[0]));
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
    });
  });
}
