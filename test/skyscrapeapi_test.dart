import 'dart:io';

import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'package:test/test.dart';

void main() async {
  String url =
      'https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w';

//  List<Term> terms;
  List<Gradebook> gradebook;

  group('Group tests on network WITH enabled refresh', () {
    test('test regular usage', () async {
      Map<String, String> env = Platform.environment;
      User person = await SkyCore.login(
          env['USERNAME'], env['PASSWORD'], url, ignoreExceptions: false);
//
//      print(await person.getName());
      try {
        gradebook = await person.getGradebook();
//        var assignment = gradebook.quickAssignments.lastWhere((element) => element.name == 'Fall Concert Performance');
//        print("${assignment.name} (${assignment.getIntGrade() ?? "Empty"})");
//        print(await person.getAssignmentDetailsFrom(assignment));
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }
//
//      //print(person.numberOfChildren());
//
//      try {
      //print(await person.getAssignmentDetailsFrom(Assignment('67916', '13030650', '12751622', 'Fall Concert Performance', {'term': 'T!', 'grade': '100'})));
//      } catch (e) {
//        throw SkywardError('SHOULD SUCCEED');
//      }
//
////      try {
////        print(await skyward.getAssignmentInfoFromAssignment(assignment[indexOfTestingAssignment]));
////      } catch (e) {
////        print('Should succeed: ${e.toString()}');
////        throw SkywardError('SHOULD SUCCEED');
////      }
//
//      try {
//        List<AssignmentProperty> props = (await person
//            .getAssignmentDetailsFrom(gradebook.quickAssignments[0]));
//        print(props);
//      } catch (e) {
//        print('Should succeed: ${e.toString()}');
//        throw SkywardError('SHOULD SUCCEED');
//      }
//
//      try {
//        print(await person.getStudentProfile());
//      } catch (e) {
//        print('Should succeed: ${e.toString()}');
//        throw SkywardError('SHOULD SUCCEED');
//      }
//
//      print(terms);
      print(gradebook);
//      print(await person.getHistory());
    });
  });
}
