import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'skywardAPITypes.dart';

class SkywardDistrictSearcher {
  static String _eventValidation;
  static String _viewState;
  static List<SkywardSearchState> states;

  static getStatesAndPostRequiredBodyElements() async {
    var getBody =
        await http.get('https://www.skyward.com/Marketing/LoginPage.aspx');
    if (getBody.statusCode == 200) {
      String getBodyHTML = getBody.body;
      var doc = parse(getBodyHTML);
      List<Element> states = doc.querySelector('#ddlStates').children;

      List<SkywardSearchState> searchStates = [];
      for (Element state in states) {
        searchStates
            .add(SkywardSearchState(state.text, state.attributes['value']));
      }
      SkywardDistrictSearcher.states = searchStates;

      _eventValidation =
          doc.getElementById('__EVENTVALIDATION').attributes['value'];
      _viewState = doc.getElementById('__VIEWSTATE').attributes['value'];
    } else {
      return 'ERROR';
    }
  }

  static searchForDistrictLinkFromState(String stateCode, String searchQuery) async {
    if (_eventValidation == null || _viewState == null) {
      await getStatesAndPostRequiredBodyElements();
      return 'Failed';
    } else {
      var postBody = await http
          .post('https://www.skyward.com/Marketing/LoginPage.aspx', body: {
        '__EVENTVALIDATION': _eventValidation,
        '__VIEWSTATE': _viewState,
        'btnSearch': 'Search',
        'ddlStates': stateCode,
        'txtSearch': searchQuery
      });
      List<SkywardDistrict> districts = [];
      Document parsed = parse(postBody.body);
      Element loginResults = parsed.querySelector('div.login-flex-container.rowCount');
      if(loginResults == null) return districts;
      List<Element> districtsElems = loginResults.querySelectorAll('.login-flex-item');


      if(districtsElems.length == 0) return districts;

      for(Element elem in districtsElems){
        districts.add(SkywardDistrict(elem.querySelector('span').text, elem.querySelector('a').attributes['href']));
      }

      return districts;
    }
  }
}
