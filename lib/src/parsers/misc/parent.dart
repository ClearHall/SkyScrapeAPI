import 'package:html/dom.dart';

import '../../core/data_types.dart';

class ParentUtils {
  /// Tries to get student accounts from a parent. It will return null if no students are found.
  static List<Child> checkForParent(Document doc) {
    List<Element> elems =
        doc.getElementById('sf_StudentList')?.querySelectorAll('a');

    if (elems == null) return null;
    List<Child> skywardAccountList = [];
    for (Element htmlStudent in elems) {
      skywardAccountList
          .add(Child(htmlStudent.attributes['data-nameid'], htmlStudent.text));
    }
    return skywardAccountList;
  }
}
