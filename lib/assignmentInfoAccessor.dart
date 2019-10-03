import 'package:http/http.dart' as http;
import 'package:html/dom.dart';
import 'skywardUniversal.dart';
import 'skywardAPITypes.dart';

class AssignmentInfoAccessor{

  static getAssignmentsDialogHTML(Map<String, String> codes, String baseURL, Assignment assignment) async {
    codes['action'] = 'dialog';
    codes['ishttp'] = 'true';
    codes['assignId'] = assignment.assignmentID;
    codes['gbId'] = assignment.gbID;
    codes['type'] = 'assignment';
    codes['student'] = assignment.studentID;
    final String gradebookURL = baseURL + 'sfdialogs.w';

    var response = await http.post(gradebookURL, body: codes);

    if(didSessionExpire(response.body)) throw SkywardError('Session Expired');

    return response.body;
  }

  static getAssignmentInfoBoxesFromHTML(String html){
    String docHTML = html.split('<![CDATA[')[1].split(']]>')[0];
    var docFrag = DocumentFragment.html(docHTML);

    List<AssignmentInfoBox> assignInfoBox = [];
    List<Element> importantInfo = docFrag.querySelectorAll('td');

    for(int i = 0; i < importantInfo.length; i++){
      if(i == 0 && (importantInfo[i+1].text.contains(':'))){
          assignInfoBox.add(AssignmentInfoBox(importantInfo[i].text, null));
      }else{
        if(importantInfo[i].text.trim().isNotEmpty) {
          assignInfoBox.add(AssignmentInfoBox(
              importantInfo[i].text, importantInfo[i + 1].text));
          i = i + 1;
        }
      }
    }

    return assignInfoBox;
  }
}