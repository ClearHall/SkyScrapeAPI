import 'package:skyscrapeapi/skywardAPITypes.dart';
import 'package:skyscrapeapi/skywardAPICore.dart';
import 'package:skyscrapeapi/skywardUniversal.dart';
import 'package:skyscrapeapi/skywardDistrictSearcher.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() async {
  final skyward = SkywardAPICore("https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w");

  var file = File('test/testCredentials.txt');
  var contents;

  var terms;
  var gradebook;
  var assignment;

  group('Group tests on network', () {
    bool skipLongTestTimes = true;

    test('test file input', () async{
      if (await file.exists()) {
        contents = await file.readAsString();
        List split = contents.toString().split('\n');

        if (!await skyward.getSkywardAuthenticationCodes(split[0], split[1])){
          throw SkywardError('OH POOP WE FAIL TO LOG IN PLZ FIX BUG');
        }
      }
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

    test('test assignment getting', () async{
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';

      try {
        print(await skyward.getAssignmentsFromGradeBox(gradebook[0]));
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
        Assignment assoonmentttt = assignment[3];
        assoonmentttt.assignmentID = '123';
        print(await skyward.getAssignmentInfoFromAssignment(assoonmentttt));
      }catch(e){
        print('Should fail: ${e.toString()}');
      }

      try {
        var _ = (await skyward.getAssignmentInfoFromAssignment(assignment[6]));
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

}
