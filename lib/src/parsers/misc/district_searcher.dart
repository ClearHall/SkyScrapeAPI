library skyward_district_searcher;

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../../core/data_types.dart';

/// [SkywardDistrictSearcher] is a completely static class that'll search for districts.
///
/// **NOTE: You must initialize [_eventValidation] and [_viewState] with [getStatesAndPostRequiredBodyElements()] BEFORE you use [searchForDistrictLinkFromState()]**
/// If the above note is not followed, then [getStatesAndPostRequiredBodyElements()] will return 'Failed' and attempt to initialize the values for you so you can call [searchForDistrictLinkFromState()] again.
class SkywardDistrictSearcher {
  static String _eventValidation;
  static String _viewState;
  static List<SkywardSearchState> states;

  /// Gets [_eventValidation] and [_viewState] and [states] so you can search for district links.
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

  /// Use [stateCode] which is the state ID. For example, Texas has a [stateCode] of 180. The [stateCode] is easily retrievable after the first successful call of [getStatesAndPostRequiredBodyElements()].
  /// To retrieve [stateCode] from [states], you search for a specific state and use:
  /// ```dart
  /// String stateNumber = SkywardDistrictSearcher.states[<index>].stateID;
  /// ```
  static searchForDistrictLinkFromState(
      String stateCode, String searchQuery) async {
    if (searchQuery.length < 3)
      throw SkywardError(
          'Parameter searchQuery should be at least 3 characters long.');
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

      try {
        Document parsed = parse(postBody.body);
        Element loginResults =
            parsed.querySelector('div.login-flex-container.rowCount');
        if (loginResults == null) return districts;
        List<Element> districtsElems =
            loginResults.querySelectorAll('.login-flex-item');

        if (districtsElems.length == 0) return districts;

        for (Element elem in districtsElems) {
          List split = elem.querySelector('a').attributes['href'].split("'");
          for (String s in split) {
            if (Uri.parse(s).host.isNotEmpty) {
              districts
                  .add(SkywardDistrict(elem.querySelector('span').text, s));
              break;
            }
          }
        }
      } catch (e) {
        throw SkywardError(
            'Invalid state ID or search query\nThings to note: Check your state ID and make sure it corresponds to a state ID retrieved.\nMake sure you also check your search query and make sure it\'s valid');
      }
      return districts;
    }
  }
}
