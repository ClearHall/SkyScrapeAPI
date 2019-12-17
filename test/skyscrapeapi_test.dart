import 'package:skyscrapeapi/data_types.dart';
import 'package:skyscrapeapi/sky_core.dart';
import 'package:skyscrapeapi/district_searcher.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  //String url = 'https://skyward-alvinprod.iscorp.com/scripts/wsisa.dll/WService=wsedualvinisdtx/seplog01.w';
  String url = 'https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w';
  var skyward = SkywardAPICore(
      url);

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

        if (!await skyward.getSkywardAuthenticationCodes(user, pass)) {
          throw SkywardError('OH POOP WE FAIL TO LOG IN PLZ FIX BUG');
        }
      }
    });

    test('test speed', () async{
      await skyward.initNewAccount();
      skyward.switchUserIndex(1);
      print(await skyward.getGradeBookGrades(await skyward.getGradeBookTerms()));
      print(await skyward.getGradeBookGrades(await skyward.getGradeBookTerms()));
      await skyward.initNewAccount();
      skyward.switchUserIndex(1);
      print(await skyward.getGradeBookGrades(await skyward.getGradeBookTerms()));
    });
  });

  group('Group tests on network WITH enabled refresh', () {
    test('test multiple logins quickly', () async {
      if (!skipLongTestTimes) {
        for (int i = 0; i < loginAttemptsTest; i++)
          assert(await skyward.getSkywardAuthenticationCodes(user, pass));
      }
    });

    test('test parent account switching', () async {
      await skyward.initNewAccount();
      skyward.switchUserIndex(1);

      print(await skyward.getMessages());
    });

    test('test login & get gradebook', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';

      await skyward.initNewAccount();
      skyward.switchUserIndex(2);

      try {
        terms = (await skyward.getGradeBookTerms());
      } catch (e, s) {
        print('Should not fail: ' + s.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(terms);
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(null);
      } catch (e) {
        print('On purpose failed: ' + e.toString());
      }
      print(gradebook);
    });

    test('test login & get gradebook second', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';
      skyward = SkywardAPICore(
          url);
      skyward.getSkywardAuthenticationCodes(user, pass);
      await skyward.initNewAccount();
      skyward.switchUserIndex(1);

      try {
        terms = (await skyward.getGradeBookTerms());
      } catch (e, s) {
        print('Should not fail: ' + s.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(terms);
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      print(gradebook);
      skyward.switchUserIndex(2);

      try {
        terms = (await skyward.getGradeBookTerms());
      } catch (e, s) {
        print('Should not fail: ' + s.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(terms);
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      print(gradebook);
    });

    test('test assignment getting', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        print(await skyward
            .getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      } catch (e) {
        print('Should fail with type error: ${e.toString()}');
      }

      if (!skipLongTestTimes)
        try {
          GradeBox gradeBox =
              GradeBox('92234', Term(null, null), 'WOOOO', '600000');
          print(await skyward.getAssignmentsFromGradeBox(gradeBox));
        } catch (e) {
          print('Should fail: ${e.toString()}');
        }

      try {
        assignment = (await skyward.getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test assignment info getting', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        await skyward.getAssignmentInfoFromAssignment(new Assignment("23", "SJDKFJS", "WOAIMAMA", "大便", null));
      } catch (e) {
        print('Should fail: ${e.toString()}');
      }

      try {
        print(await skyward.getAssignmentInfoFromAssignment(
            assignment[assignmentTestInfoIndex]));
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test history getting', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        var _ = (await skyward.getHistory());
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test district searcher', () async {
      await SkywardDistrictSearcher.getStatesAndPostRequiredBodyElements();

      try {
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState(
            SkywardDistrictSearcher.states[1].stateID, 'Search');
      } catch (e) {
        throw SkywardError('Should not fail');
      }

      try {
        if ((await SkywardDistrictSearcher.searchForDistrictLinkFromState(
                    '9999', 'Search'))
                .length !=
            0) throw SkywardError('POOPOO');
      } catch (e) {
        throw SkywardError('Should not fail');
      }

      try {
        // 180 is Texas at the time of writing
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState(
            '180', 'OH');
      } catch (e) {
        print('Should fail with: ${e.toString()}');
      }
    });
  });

  group('Group tests on network WITH DISABLED refresh', () {
    test('test multiple logins quickly', () async {
      skyward.shouldRefreshWhenFailedLogin = false;
      for (int i = 0; i < loginAttemptsTest; i++)
        print(await skyward.getSkywardAuthenticationCodes(user, pass));
    });

    test('test login & get gradebook', () async {
      try {
        terms = (await skyward.getGradeBookTerms());
      } catch (e) {
        print('Should not fail: ' + e);
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(terms);
      } catch (e) {
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }

      try {
        gradebook = await skyward.getGradeBookGrades(null);
      } catch (e) {
        print('On purpose failed: ' + e.toString());
      }
    });

    test('test assignment getting', () async {
      try {
        print(await skyward
            .getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      } catch (e) {
        print('Should fail with type error: ${e.toString()}');
      }

      if (!skipLongTestTimes)
        try {
          GradeBox gradeBox =
              GradeBox('92234', Term(null, null), 'WOOOO', '600000');
          print(await skyward.getAssignmentsFromGradeBox(gradeBox));
        } catch (e) {
          print('Should fail: ${e.toString()}');
        }

      try {
        assignment = (await skyward.getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test assignment info getting', () async {
      try {
        Assignment assoonmentttt = assignment[assignmentTestInfoIndex];
        assoonmentttt.assignmentID = '123';
        print(await skyward.getAssignmentInfoFromAssignment(assoonmentttt));
      } catch (e) {
        print('Should fail: ${e.toString()}');
      }

      try {
        var _ = (await skyward.getAssignmentInfoFromAssignment(
            assignment[assignmentTestInfoIndex]));
      } catch (e) {
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test history getting', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] =
          'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        var _ = (await skyward.getHistory());
      } catch (e) {
        print('Should succeed: ${e.toString()}');
      }
    });

    test('test district searcher', () async {
      await SkywardDistrictSearcher.getStatesAndPostRequiredBodyElements();

      try {
        print(await SkywardDistrictSearcher.searchForDistrictLinkFromState(
            '180', 'Alv'));
      } catch (e) {
        throw SkywardError('Should not fail');
      }

      try {
        if ((await SkywardDistrictSearcher.searchForDistrictLinkFromState(
                    '9999', 'Search'))
                .length !=
            0) throw SkywardError('POOPOO');
      } catch (e) {
        throw SkywardError('Should not fail');
      }

      try {
        // 180 is Texas at the time of writing
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState(
            '180', 'OH');
      } catch (e) {
        print('Should fail with: ${e.toString()}');
      }
    });
  });
}
