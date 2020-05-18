import 'dart:convert';
import 'dart:io';

import 'package:skyscrapeapi/sky_core.dart';
import 'package:test/test.dart';

void main() async {
  String url =
      'https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w';
  Map<String, String> env = Platform.environment;
  User person = await SkyCore.login(env['USERNAME'], env['PASSWORD'], url,
      ignoreExceptions: false);
//  List<Term> terms;
  Gradebook gradebook;

  group('Group tests on network WITH enabled refresh', () {
    test('test regular usage', () async {
      try {
        gradebook = await person.getGradebook();
        print(gradebook.getAllAssignments()[0].getClass(gradebook));
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
//      print(gradebook.toCompressedJson());
      print(gradebook.toString() + "\n\n\n\n\n\n\n\n");
      var dec = jsonDecode(jsonEncode(gradebook.toCompressedJson()));
      print(dec.toString() + "\n\n\n\n\n\n\n\n");
      print(Gradebook.fromJson(dec));
      //for(dynamic f in dec) print(Grade.fromJson(f));
//      print(Gradebook.fromJson(
//          jsonDecode(jsonEncode(gradebook.toCompressedJson()))));
//      print(gradebook);
//      print(await person.getHistory());
    });
  });
}
