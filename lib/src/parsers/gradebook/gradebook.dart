import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../../core/data_types.dart';
import '../misc/skyward_utils.dart';

class GradebookAccessor {
  /*
  This decoded json string is super weird. Look at initGradebookHTML if you need to understand it.
   */
  static final _termJsonDeliminater =
      "sff.sv('sf_gridObjects',\$.extend((sff.getValue('sf_gridObjects') || {}), ";

  static getTermsFromDocCode(List infoList) {
    List<Term> terms = [];
    for (int i = 1; i < infoList[0].length; i++) {
      Map termHTMLA = infoList[0][i];
      String termHTML = termHTMLA['h'];
      termHTML =
          termHTML.replaceFirst('th', 'a').substring(0, termHTML.length - 4) +
              'a>';

      final termDoc = DocumentFragment.html(termHTML);
      final tooltip = termDoc.querySelector('a').attributes['tooltip'];

      terms.add(Term(termDoc.text, tooltip));
    }
    return terms;
  }

  static GradebookSector getGradeBoxesFromDocCode(List infoList,
      Document parsedHTML) {
    GradebookSector gradebook = new GradebookSector();
    List<Term> terms = getTermsFromDocCode(infoList);
    gradebook.terms = terms;
    Element name =
    parsedHTML.querySelector('#grid_' + infoList[2] + '_gridWrap');
    gradebook.name = name
        .querySelector('span')
        .text +
        (name
            .querySelector('div[class="sfTag"]')
            .nodes
            .firstWhere((element) => element.nodeType == Node.TEXT_NODE)
            .text);
    gradebook.name = gradebook.name.trim();
    List<Class> classes = [];
    for (var sffBrak in infoList[1]) {
      for (var i = 0; i < sffBrak['c'].length; i++) {
        var c = sffBrak['c'][i];
        var cDoc = DocumentFragment.html(c['h']);
        Element gradeElem = cDoc.getElementById('showGradeInfo');
        Element assignmentInfoElem = cDoc.getElementById('showAssignmentInfo');
        if (assignmentInfoElem != null) {
          int grade;
          for (var index = i + 1; index < sffBrak['c'].length; index++) {
            var frag = DocumentFragment.html(sffBrak['c'][index]['h']);
            int attemptedParse = int.tryParse(frag.text);
            if (attemptedParse != null) {
              grade = attemptedParse;
            }
          }
          String assignmentLabels = cDoc.querySelectorAll('span')[0].text;
          Assignment temp = Assignment(
              assignmentInfoElem.attributes['data-sid'],
              assignmentInfoElem.attributes['data-aid'],
              assignmentInfoElem.attributes['data-gid'],
              cDoc.querySelectorAll('a')[0].text,
              Map.fromIterables([
                'term',
                'grade'
              ], [
                assignmentLabels.substring(assignmentLabels.indexOf('(') + 1,
                    assignmentLabels.indexOf(')')),
                grade.toString()
              ]));

          gradebook.quickAssignments.add(temp);
          break;
        } else if (gradeElem != null) {
          Grade x = Grade(
              gradeElem.attributes['data-cni'],
              Term(gradeElem.attributes['data-lit'],
                  gradeElem.attributes['data-bkt']),
              gradeElem.text,
              gradeElem.attributes['data-sid']);
          classes.last.grades.add(x);
        } else if (c['cId'] != null) {
          var tdElement = parsedHTML.getElementById(c['cId']);
          var tdElements = (tdElement.children[0].querySelectorAll('td'));
          if (tdElements.length >= 4) {
            Element secElem = tdElements[2];
            classes.add(Class(
                tdElements[3].text,
                tdElements[1].text,
                secElem
                    .querySelector('label')
                    .text +
                    " " +
                    secElem.nodes
                        .firstWhere(
                            (element) => element.nodeType == Node.TEXT_NODE)
                        .text +
                    " " +
                    secElem
                        .querySelector('span')
                        .text));
          } else {
            classes.add(Class(tdElements[2].text, tdElements[1].text, null));
          }
        } else if (cDoc.text.trim().isNotEmpty) {
          classes.last.grades.add(FixedGrade(cDoc.text, terms[i - 1]));
        }
      }
    }

    gradebook.classes = classes;
    return gradebook;
  }

  static List initGradebookAndGradesHTML(String html) {
    Document doc = parse(html);

    if (!didSessionExpire(html)) {
      Element elem = doc.querySelector("script[data-rel='sff']");
      if (elem.text.contains(_termJsonDeliminater)) {
        var needToDecodeJson = elem.text.substring(
            elem.text.indexOf(_termJsonDeliminater) +
                _termJsonDeliminater.length -
                1,
            elem.text.length - 4);
        int ind = needToDecodeJson.indexOf('\'stuGradesGrid');
        while (ind > -1) {
          needToDecodeJson = needToDecodeJson.replaceFirst("'", ' "', ind);
          needToDecodeJson = needToDecodeJson.replaceFirst("'", '"', ind);
          ind = needToDecodeJson.indexOf('\'stuGradesGrid');
        }
        Map listOfStuGrids = jsonDecode(needToDecodeJson);

        List vals = List();
        listOfStuGrids.forEach((key, value) {
          vals.add([value['th']['r'][0]['c'], value['tb']['r'], key]);
        });
        vals.add(html);

        return vals;
      } else {
        throw SkywardError(
            'Term JSON Deliminater missing. District not supported.');
      }
    } else {
      throw SkywardError('Session Expired');
    }
  }
}
