import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

class SkywardAuthenticator {
  static getNewSessionCodes(String user, String pass, String baseURL) async {
    final String authenticationURL = baseURL + 'skyporthttp.w';
    var postResponse = await http.post(authenticationURL, body: {
      'codeType': 'tryLogin',
      'login': user,
      'password': pass,
      'requestAction': 'eel'
    });
    var parsedMap = parsePostResponse(postResponse.body);
    return parsedMap;
  }

  static Map<String, String> parsePostResponse(String postResponse) {
    if (postResponse.isNotEmpty) {
      String dissectedString =
          postResponse.substring(4, postResponse.length - 5);
      var toks = dissectedString.split('^');
      if (toks.length < 15) {
        DocumentFragment frag = DocumentFragment.html(postResponse);
        throw (frag.text);
      } else {
        return Map.fromIterables(['dwd', 'wfaacl', 'encses', 'User-Type', 'sessionid'],
            [toks[0], toks[3], toks[14], '1', '${toks[1]}${toks[2]}']);
      }
    } else {
      return null;
    }
  }
}
