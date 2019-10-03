import 'package:skyscrapeapi/skywardAPITypes.dart';
import 'package:test/test.dart';
import 'dart:io';

import 'package:skyscrapeapi/skywardAPICore.dart';

void main() async {
  group('Group tests', () {
    final skyward = SkywardAPICore("https://skyward-fbprod.iscorp.com/scripts/wsisa.dll/WService=wsedufortbendtx/seplog01.w");

    var file = File('test/testCredentials.txt');
    var contents;

    var terms;
    var gradebook;
    var assignment;

    bool skipLongTestTimes = true;

    test('test file input', () async{
      if (await file.exists()) {
        contents = await file.readAsString();
        List split = contents.toString().split('\n');

        await skyward.getSkywardAuthenticationCodes(split[0], split[1]);
      }
    });

    test('test login & get gradebook', () async {
      skyward.loginSessionRequiredBodyElements['dwd'] = 'ON_PURPOSE_TRY_TO_GET_ERROR';
      try {
        terms = (await skyward.getGradeBookTerms());
      }catch(e){
        print('Should not fail: ' + e);
      }

      try{
        gradebook = await skyward.getGradeBookGrades(terms);
      }catch(e){
        print('Should not fail: ' + e.toString());
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
  });

}
