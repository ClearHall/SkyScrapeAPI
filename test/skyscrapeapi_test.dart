import 'package:skyscrapeapi/skywardAPITypes.dart';
import 'package:skyscrapeapi/skywardAPICore.dart';
import 'package:skyscrapeapi/skywardUniversal.dart';
import 'package:skyscrapeapi/skywardDistrictSearcher.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  var skyward = SkywardAPICore("https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedualvinisdtx/seplog01.w");

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

  test('test file input', () async{
    if (await credentialFile.exists()) {
      contents = await credentialFile.readAsString();
      List split = contents.toString().split('\n');

      user = split[0];
      pass = split[1];

      contents = await settingsFile.readAsString();
      split = contents.toString().split('\n');

      for(String s in split){
        if(s.startsWith('# ') || s.isEmpty) continue;
        List ssplit = [];
        ssplit = s.split(':');

        switch(ssplit[0]){
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

      if (!await skyward.getSkywardAuthenticationCodes(user, pass)){
        throw SkywardError('OH POOP WE FAIL TO LOG IN PLZ FIX BUG');
      }
    }
  });

  group('Group tests on network WITH enabled refresh', () {
    test('test multiple logins quickly', () async{
      for(int i = 0; i < loginAttemptsTest; i++)
        print(await skyward.getSkywardAuthenticationCodes(user, pass));
    });

    test('test login & get gradebook', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';
      try {
        terms = (await skyward.getGradeBookTerms());
      }catch(e){
        print('Should not fail: ' + e);
        throw SkywardError('SHOULD SUCCEED');
      }

      try{
        gradebook = await skyward.getGradeBookGrades(terms);
      }catch(e){
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }


      try{
        gradebook = await skyward.getGradeBookGrades(null);
      }catch(e){
        print('On purpose failed: ' + e.toString());
      }
    });

    test('test login & get gradebook second', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';
      skyward = SkywardAPICore("https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w");
      skyward.getSkywardAuthenticationCodes(user, pass);
      try {
        terms = (await skyward.getGradeBookTerms());
      }catch(e){
        print('Should not fail: ' + e);
        throw SkywardError('SHOULD SUCCEED');
      }

      try{
        gradebook = await skyward.getGradeBookGrades(terms);
      }catch(e){
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }


      try{
        gradebook = await skyward.getGradeBookGrades(null);
      }catch(e){
        print('On purpose failed: ' + e.toString());
      }
    });

    test('test assignment getting', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        print(await skyward.getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      }catch(e){
        print('Should fail with type error: ${e.toString()}');
      }

      if(!skipLongTestTimes)
        try {
          GradeBox gradeBox = GradeBox('92234', Term(null, null), 'WOOOO', '600000');
          print(await skyward.getAssignmentsFromGradeBox(gradeBox));
        }catch(e){
          print('Should fail: ${e.toString()}');
        }

      try {
        assignment = (await skyward.getAssignmentsFromGradeBox(gradebook[1]));
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test assignment getting second', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';
      SkywardAPICore testCore = SkywardAPICore("https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w");

      testCore.getSkywardAuthenticationCodes(user, pass);
      await testCore.getGradeBookGrades(await testCore.getGradeBookTerms());

      try {
        print(await skyward.getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      }catch(e){
        print('Should fail with type error: ${e.toString()}');
      }

      if(!skipLongTestTimes)
        try {
          GradeBox gradeBox = GradeBox('92234', Term(null, null), 'WOOOO', '600000');
          print(await skyward.getAssignmentsFromGradeBox(gradeBox));
        }catch(e){
          print('Should fail: ${e.toString()}');
        }

      try {
        assignment = (await skyward.getAssignmentsFromGradeBox(gradebook[1]));
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test assignment info getting', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        Assignment assoonmentttt = assignment[assignmentTestInfoIndex];
        assoonmentttt.assignmentID = '123';
        print(await skyward.getAssignmentInfoFromAssignment(assoonmentttt));
      }catch(e){
        print('Should fail: ${e.toString()}');
      }

      try {
        var _ = (await skyward.getAssignmentInfoFromAssignment(assignment[assignmentTestInfoIndex]));
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test history getting', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        var _ = (await skyward.getHistory());
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test district searcher', () async{
      await SkywardDistrictSearcher.getStatesAndPostRequiredBodyElements();

      try{
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState(SkywardDistrictSearcher.states[1].stateID, 'Search');
      }catch (e){
        throw SkywardError('Should not fail');
      }

      try{
        if ((await SkywardDistrictSearcher.searchForDistrictLinkFromState('9999', 'Search')).length != 0)
          throw SkywardError('POOPOO');
      }catch(e){
        throw SkywardError('Should not fail');
      }

      try{
        // 180 is Texas at the time of writing
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState('180', 'OH');
      }catch(e){
        print('Should fail with: ${e.toString()}');
      }
    });
  });

  group('Group tests on network WITH DISABLED refresh', () {
    test('test multiple logins quickly', () async{
      skyward.shouldRefreshWhenFailedLogin = false;
      for(int i = 0; i < loginAttemptsTest; i++)
        print(await skyward.getSkywardAuthenticationCodes(user, pass));
    });

    test('test login & get gradebook', () async {
      try {
        terms = (await skyward.getGradeBookTerms());
      }catch(e){
        print('Should not fail: ' + e);
        throw SkywardError('SHOULD SUCCEED');
      }

      try{
        gradebook = await skyward.getGradeBookGrades(terms);
      }catch(e){
        print('Should not fail: ' + e.toString());
        throw SkywardError('SHOULD SUCCEED');
      }


      try{
        gradebook = await skyward.getGradeBookGrades(null);
      }catch(e){
        print('On purpose failed: ' + e.toString());
      }
    });

    test('test assignment getting', () async{
      try {
        print(await skyward.getAssignmentsFromGradeBox(gradebook[assignmentTestIndex]));
      }catch(e){
        print('Should fail with type error: ${e.toString()}');
      }

      if(!skipLongTestTimes)
        try {
          GradeBox gradeBox = GradeBox('92234', Term(null, null), 'WOOOO', '600000');
          print(await skyward.getAssignmentsFromGradeBox(gradeBox));
        }catch(e){
          print('Should fail: ${e.toString()}');
        }

      try {
        assignment = (await skyward.getAssignmentsFromGradeBox(gradebook[1]));
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test assignment info getting', () async{
      try {
        Assignment assoonmentttt = assignment[assignmentTestInfoIndex];
        assoonmentttt.assignmentID = '123';
        print(await skyward.getAssignmentInfoFromAssignment(assoonmentttt));
      }catch(e){
        print('Should fail: ${e.toString()}');
      }

      try {
        var _ = (await skyward.getAssignmentInfoFromAssignment(assignment[assignmentTestInfoIndex]));
      }catch(e){
        print('Should succeed: ${e.toString()}');
        throw SkywardError('SHOULD SUCCEED');
      }
    });

    test('test history getting', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        var _ = (await skyward.getHistory());
      }catch(e){
        print('Should succeed: ${e.toString()}');
      }
    });

    test('test district searcher', () async{
      await SkywardDistrictSearcher.getStatesAndPostRequiredBodyElements();

      try{
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState(SkywardDistrictSearcher.states[1].stateID, 'Search');
      }catch (e){
        throw SkywardError('Should not fail');
      }

      try{
        if ((await SkywardDistrictSearcher.searchForDistrictLinkFromState('9999', 'Search')).length != 0)
          throw SkywardError('POOPOO');
      }catch(e){
        throw SkywardError('Should not fail');
      }

      try{
        // 180 is Texas at the time of writing
        var _ = await SkywardDistrictSearcher.searchForDistrictLinkFromState('180', 'OH');
      }catch(e){
        print('Should fail with: ${e.toString()}');
      }
    });
  });
}
