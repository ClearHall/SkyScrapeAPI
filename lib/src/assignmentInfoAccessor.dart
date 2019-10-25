import 'package:html/dom.dart';
import '../data_types.dart';

class AssignmentInfoAccessor {
  static getAssignmentInfoBoxesFromHTML(String html) {
    String docHTML = html.split('<![CDATA[')[1].split(']]>')[0];
    var docFrag = DocumentFragment.html(docHTML);

    List<AssignmentInfoBox> assignInfoBox = [];
    List<Element> importantInfo = docFrag.querySelectorAll('td');

    for (int i = 0; i < importantInfo.length; i++) {
      if (i == 0 && (importantInfo[i + 1].text.contains(':'))) {
        assignInfoBox.add(AssignmentInfoBox(importantInfo[i].text, null));
      } else {
        if (importantInfo[i].text.trim().isNotEmpty) {
          assignInfoBox.add(AssignmentInfoBox(
              importantInfo[i].text, importantInfo[i + 1].text));
          i = i + 1;
        }
      }
    }

    return assignInfoBox;
  }
}
