import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:skyscrapeapi/data_types.dart';

class ParentAccountUtils{
  /// Tries to get student accounts from a parent. It will return null if no students are found.
  static List<SkywardAccount> checkForParent(Document doc){
    List<Element> elems = doc.getElementById('sf_StudentList')?.querySelectorAll('a');

    if (elems == null) return null;
    List<SkywardAccount> skywardAccountList = [];
    for(Element htmlStudent in elems){
      skywardAccountList.add(SkywardAccount(htmlStudent.attributes['data-nameid'], htmlStudent.text));
    }
    return skywardAccountList;
  }
}