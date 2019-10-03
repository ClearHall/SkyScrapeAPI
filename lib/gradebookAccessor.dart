import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'skywardAPITypes.dart';
import 'skywardUniversal.dart';

class GradebookAccessor {
  List<String> sffData = [];
  /*
  This decoded json string is super weird. Look at initGradebookHTML if you need to understand it.
   */
  List termElements = [];
  List gradesElements = [];
  static final _termJsonDeliminater =
      "sff.sv('sf_gridObjects',\$.extend((sff.getValue('sf_gridObjects') ";

  getGradebookHTML(Map<String, String> codes, String baseURL) async {
    final String gradebookURL = baseURL + 'sfgradebook001.w';
    final postReq = await http.post(gradebookURL, body: codes);

    if (didSessionExpire(postReq.body)) {
      throw SkywardError('Session Expired');
    }else
      initGradebookAndGradesHTML(postReq.body);
    return postReq.body;
  }

  getTermsFromDocCode() {
    var terms = [];
    terms = _detectTermsFromScriptByParsing();
    return terms;
  }

  //TODO: Implement server quick scrape assignments algorithm from sff.sv() script code.

  getGradeBoxesFromDocCode(String docHtml, List<Term> terms) {
    var gradeBoxes = [];
    gradeBoxes = _scrapeGradeBoxesFromSff(docHtml, terms);
    return gradeBoxes;
  }

  List<GridBox> _scrapeGradeBoxesFromSff(String docHtml, List<Term> terms) {
    List<GridBox> gradeBoxes = [];
    var parsedHTML = parse(docHtml);
    for (var sffBrak in gradesElements) {
      for (var i = 0; i < sffBrak['c'].length; i++) {
        var c = sffBrak['c'][i];
        var cDoc = DocumentFragment.html(c['h']);
        Element gradeElem = cDoc.getElementById('showGradeInfo');
        if (gradeElem != null) {
          GradeBox x = GradeBox(
              gradeElem.attributes['data-cni'],
              Term(gradeElem.attributes['data-lit'],
                  gradeElem.attributes['data-bkt']),
              gradeElem.text,
              gradeElem.attributes['data-sid']);
          x.clickable = true;
          gradeBoxes.add(x);
        } else if (c['cId'] != null) {
          var tdElement = parsedHTML.getElementById(c['cId']);
          var tdElements = (tdElement.children[0].querySelectorAll('td'));
          gradeBoxes.add(TeacherIDBox(
              tdElements[3].text, tdElements[1].text, tdElements[2].text));
        } else if (cDoc.text.trim().isNotEmpty &&
            cDoc.getElementById('showAssignmentInfo') == null) {
          gradeBoxes.add(LessInfoBox(cDoc.text, terms[i - 1]));
        }
      }
    }
    return gradeBoxes;
  }

  initGradebookAndGradesHTML(String html) {
    Document doc = parse(html);

    if (!didSessionExpire(html)) {
      Element elem = doc.querySelector("script[data-rel='sff']");
      if (elem.text.contains(_termJsonDeliminater)) {
        var needToDecodeJson = elem.text.substring(
            elem.text.indexOf(_termJsonDeliminater) +
                _termJsonDeliminater.length,
            elem.text.length - 5);
        needToDecodeJson =
            needToDecodeJson.substring(needToDecodeJson.indexOf(':') + 1);
        var mapOfFutureParsedHTML = jsonDecode(needToDecodeJson);

        if (termElements.isEmpty) {
          termElements = mapOfFutureParsedHTML['th']['r'][0]['c'];
        }
        if (gradesElements.isEmpty) {
          gradesElements = mapOfFutureParsedHTML['tb']['r'];
        }
      }
    } else {
      throw SkywardError('Session Expired');
    }
  }

  List<Term> _detectTermsFromScriptByParsing() {
    List<Term> terms = [];
    for (var termHTMLA in termElements) {
      String termHTML = termHTMLA['h'];
      termHTML =
          termHTML.replaceFirst('th', 'a').substring(0, termHTML.length - 4) +
              'a>';

      final termDoc = DocumentFragment.html(termHTML);
      final tooltip = termDoc.querySelector('a').attributes['tooltip'];

      if (tooltip != null) terms.add(Term(termDoc.text, tooltip));
    }
    return terms;
  }
}
