import 'package:html/dom.dart';
import 'package:skyscrapeapi/data_types.dart';

class StudentInfoParser{
  static StudentInfo parseStudentID(String html){
    Document doc = Document.html(html);
    StudentInfo info = StudentInfo();

    Element family = doc.getElementById('sf_ContentBody').children[2];
    info.family = (parseFamily(family));
    Element sfTag = doc.querySelectorAll('.sfTag')[2];
    info.name = sfTag.text;

    info.studentAttributes = parseStudentAttr(sfTag.parent.querySelector('td'));
    info.currentSchool = parseSchoolInfo(sfTag.parent.querySelectorAll('table')[4]);

    return info;
  }

  static Map<String, String> parseStudentAttr(Element stuAttrElem){
    Map<String, String> attr = Map();

    List<Element> trElems = stuAttrElem.querySelectorAll('tbody > tr');
    for(Element tr in trElems){
      if(tr.children.length > 1){
        if(tr.children[0].querySelector('img') != null){
          attr['Student Image Href Link'] = tr.children[0].querySelector('img').attributes['src'];
        }else{
          getAttributesFrom(tr, attr);
        }
      }
    }

    return attr;
  }

  static SchoolInfo parseSchoolInfo(Element schoolAttrElem){
    SchoolInfo schoolInfo = SchoolInfo();
    List<Element> trs = schoolAttrElem.querySelectorAll('tr');

    for(Element tr in trs){
      if(tr.classes.contains('odd')){
        Element th = tr.querySelector('th');
        if(th != null){
          String strNode;
          for(Node node in th.nodes) if(node.nodeType == Node.TEXT_NODE) strNode = node.text;
          schoolInfo.schoolName = strNode;

          th.children.removeAt(0);
          getAttributesFrom(th, schoolInfo.attributes);
        }
      }else{
        getAttributesFrom(tr, schoolInfo.attributes);
      }
    }
    return schoolInfo;
  }

  static void getAttributesFrom(Element tr, Map<String, String> attr) {
    for(int i = 0; i < tr.children.length; i+=2){
      String infoName = tr.children[i].text.trim();
      String info = tr.children[i+1].text.trim();
      if(infoName.isNotEmpty && info.isNotEmpty)
        attr[infoName] = info;
    }
  }

  static List<Family> parseFamily(Element familyElem){
    List<Family> finalList = List();
    for(Element guardianElem in familyElem.children){
      Family family = Family();
      Element body = guardianElem.querySelector('tbody');

      List<Element> headers = body.children[0].children;
      int addressNum = headers.length;
      for(int i = 0; i < addressNum; i++){
        String address = body.children[1].children[i].text;
        family.extraInfo[headers[i].text] = address;
      }

      List<Element> tableList = body.querySelectorAll('table');
      for(Element table in tableList){
        if(table.querySelector('thead') != null){
          List<String> guardianAttr = List();

          List<Element> theadThs = table.querySelector('thead').querySelectorAll('th');
          for(Element th in theadThs) { guardianAttr.add(th.text); }
          guardianAttr.removeAt(0);

          List<Element> tbodyTrs = table.querySelector('tbody').querySelectorAll('tr');
          for(Element tr in tbodyTrs){
            Guardian guardian = Guardian();
            for(int i = 0; i < tr.children.length; i++){
              Element td = tr.children[i];
              if(i == 0){
                guardian.guardianName = td.text;
              }else{
                guardian.extraInfo[guardianAttr[i - 1]] = td.text;
              }
            }
            family.guardians.add(guardian);
          }
        }else{
          List<Element> trs = table.querySelectorAll('tr');
          for(Element tr in trs){
            if(tr.children.length >= 2)
              family.extraInfo[tr.children[0].text] = tr.children[1].text;
            else if(tr.children.length == 1) {
              Element td = tr.children[0];
              if(td.children.length == 1 && td.children[0].children.length == 1){
                Element input = td.children[0].children[0];
                bool disabled = true;
                if(input.attributes['disabled'] != 'disabled') disabled = false;

                family.extraInfo[tr.children[0].text] = disabled.toString();
              }
            }
          }
        }
      }

      finalList.add(family);
    }
    return finalList;
  }
}