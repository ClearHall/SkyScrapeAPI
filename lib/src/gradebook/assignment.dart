import 'package:html/dom.dart';
import '../../data_types.dart';

class AssignmentAccessor {
  static DetailedGradingPeriod getAssignmentsDialog(String assignmentPageHTML) {
    var doc = DocumentFragment.html(assignmentPageHTML);
    Map<List<CategoryHeader>, List<Assignment>> gridBoxes = Map();
    Element table =
        doc.querySelector('table[id*=grid_stuAssignmentSummaryGrid]');
    List<String> headers = [];
    List<Element> elementsInsideTable =
        table.querySelector('tbody').querySelectorAll('tr');
    Map<String, String> extrAttr = Map();

    List<Element> elems = table.querySelector('thead').querySelectorAll('th');
    for (Element header in elems) {
      headers.add(header.text);
    }

    try {
      Element th = doc.querySelector('th');
      extrAttr['term'] = th.nodes[0].text.split(' ')[0];
      extrAttr['date'] = th.querySelector('span').text;
    } catch (e) {}
    try {
      // When you have to fix the html cause the parser is stupid
      List<Element> setElems = Element.html(doc
              .querySelector('script[language="JavaScript"]')
              .text
              .split('"')[3]
              .replaceFirst('/>', '></style>')
              .replaceFirst('/>', '></style>'))
          .querySelectorAll('set');
      for (Element a in setElems) {
        extrAttr['${a.attributes['label']} Weight'] = a.attributes['value'];
      }
    } catch (e, s) {}
    List<CategoryHeader> tmp;
    List<Assignment> assignList;
    bool wasLastCat = false;
    for (Element row in elementsInsideTable) {
      List<Element> tdVals = row.querySelectorAll('td');
      List<String> attributes = [];

      if (row.classes.contains('sf_Section') && row.classes.contains('cat')) {
        if (!wasLastCat) if (tmp != null) gridBoxes[tmp] = assignList;
        CategoryHeader catHeader = CategoryHeader(null, null, null);
        for (Element td in tdVals) {
          if (td.classes.contains('nWp') && td.classes.contains('noLBdr')) {
            List<Element> weighted = td.querySelectorAll('span');
            String weightedText;
            if (weighted.length > 0) {
              weightedText = weighted != null ? weighted.last.text : null;
              catHeader.weight = weightedText;
            }
            attributes.add(td.text.substring(
                0,
                weightedText != null
                    ? td.text.indexOf(weightedText)
                    : td.text.length));
          } else {
            attributes.add(td.text);
          }
        }
        for (int i = attributes.length; i < headers.length; i++) {
          attributes.add("");
        }
        catHeader.name = attributes[1];
        catHeader.attributes = Map.fromIterables(headers, attributes);
        if (!wasLastCat) tmp = List();
        tmp.add(catHeader);
        assignList = List();
        wasLastCat = true;
      } else {
        wasLastCat = false;
        Element assignment = row.querySelector('#showAssignmentInfo');
        List<String> tmpMoreAttr = List();
        for (Element td in tdVals) {
          if (td.children.length == 2 &&
              td.children[1].attributes.containsKey('data-info')) {
            tmpMoreAttr.add(td.children[1].attributes['data-info']);
          }
          if (td.attributes['type'] == '<img>') attributes.add('yes');
          attributes.add(td.text);
        }
        if (assignment != null)
          assignList.add(Assignment(
              assignment.attributes['data-sid'],
              assignment.attributes['data-aid'],
              assignment.attributes['data-gid'],
              attributes[1],
              Map.fromIterables(headers, attributes)));
        else {
          for (int i = attributes.length; i < headers.length; i++) {
            attributes.add("");
          }
          assignList.add(Assignment(null, null, null, attributes.first,
              Map.fromIterables(headers, attributes)));
        }
      }
    }
    gridBoxes[tmp] = assignList;
    return DetailedGradingPeriod.define(gridBoxes, extrAttr);
  }
}
