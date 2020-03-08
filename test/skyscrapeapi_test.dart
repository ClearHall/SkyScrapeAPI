import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'package:skyscrapeapi/district_searcher.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  //String url = 'https://skyward-alvinprod.iscorp.com/scripts/wsisa.dll/WService=wsedualvinisdtx/seplog01.w';
  String url = 'https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w';
  SkyCore skyward;

  var credentialFile = File('test/testCredentials.txt');
  var settingsFile = File('test/testSettings.skyTest');
  var contents;

  int assignmentTestIndex = 3;
  int assignmentTestInfoIndex = 5;
  int loginAttemptsTest = 10;
  bool skipLongTestTimes = true;

  var terms;
  var gradebook;
  var assignment;

  var user;
  var pass;

  group("test time of login", () {
    test('test file input', () async {
      if (await credentialFile.exists()) {
        contents = await credentialFile.readAsString();
        List split = contents.toString().split('\n');

        user = split[0];
        pass = split[1];

        contents = await settingsFile.readAsString();
        split = contents.toString().split('\n');

        for (String s in split) {
          if (s.startsWith('# ') || s.isEmpty) continue;
          List ssplit = [];
          ssplit = s.split(':');

          switch (ssplit[0]) {
            case 'assignmentTestIndex':
              assignmentTestIndex = int.parse(ssplit[1]);
              break;
            case 'assignmentTestInfoIndex':
              assignmentTestInfoIndex = int.parse(ssplit[1]);
              break;
            case 'loginAttemptsTest':
              loginAttemptsTest = int.parse(ssplit[1]);
              break;
            case 'skipLongTestTimes':
              skipLongTestTimes = ssplit[1].toString().toLowerCase() == 'true';
              break;
            default:
              break;
          }
        }
      }
    });

//    test('test speed', () async{
//      await skyward.initNewAccount();
//      skyward.switchUserIndex(1);
//      print(await skyward.getGradebook(await skyward.getTerms()));
//      print(await skyward.getGradebook(await skyward.getTerms()));
//      await skyward.initNewAccount();
//      skyward.switchUserIndex(1);
//      print(await skyward.getGradebook(await skyward.getTerms()));
//    });
  });

  group('Group tests on network WITH enabled refresh', ()
  {
    test('test regular usage', () async {
      skyward = SkyCore(url);
      User person = await skyward.loginWith(user, pass);
      //person.switchUserIndex(1);

      try {
        terms = await person.getTerms();
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await person.getGradebook();
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      //print(person.numberOfChildren());

//      try {
//        assignment = (await skyward.getAssignmentsFromGradeBox(gradeBook[indexOfTestingGradeBook]));
//      } catch (e) {
//        print('Should succeed: ${e}');
//        throw SkywardError('SHOULD SUCCEED');
//      }
//
//      try {
//        print(await skyward.getAssignmentInfoFromAssignment(assignment[indexOfTestingAssignment]));
//      } catch (e) {
//        print('Should succeed: ${e.toString()}');
//        throw SkywardError('SHOULD SUCCEED');
//      }

      try {
        print(await person.getHistory());
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }

      print(terms);
      print(gradebook);
    });
  });
}
