import 'package:html/dom.dart';
import '../data_types.dart';

class AssignmentInfoAccessor {
  static getAssignmentInfoBoxesFromHTML(String html) {
    String docHTML = html.split('<![CDATA[')[1].split(']]>')[0];
    var docFrag = DocumentFragment.html(docHTML);

    List<AssignmentProperty> assignInfoBox = [];
    List<Element> importantInfo = docFrag.querySelectorAll('td');

    for (int i = 0; i < importantInfo.length; i++) {
      if (i == 0 && (importantInfo[i + 1].querySelector('label') != null)) {
        assignInfoBox.add(AssignmentProperty(importantInfo[i].text, null));
      } else {
        if (importantInfo[i].text.trim().isNotEmpty) {
          assignInfoBox.add(AssignmentProperty(
              importantInfo[i].text, importantInfo[i + 1].text));

          Element aElem = importantInfo[i + 1].querySelector('a');
          if (aElem != null) {
            String onClick = aElem.attributes['onclick'];
            List<String> diagAttr = onClick.split("\"");
            AssignmentProperty assignmentInfoBox = AssignmentProperty(null, null);
            for (int j = 0; j < diagAttr.length; j++) {
              if (diagAttr[j] == 'title') {
                assignmentInfoBox.infoName = diagAttr[j + 2];
                j += 2;
              } else if (diagAttr[j] == 'html') {
                assignmentInfoBox.info = diagAttr[j + 2];
                j += 2;
              }
            }
            assignInfoBox.add(assignmentInfoBox);
          }

          i = i + 1;
        }
      }
    }

    return assignInfoBox;
  }
}
