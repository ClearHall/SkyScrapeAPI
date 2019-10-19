import 'package:http/http.dart' as http;
import 'package:skyscrapeapi/skywardUniversal.dart';

class SkywardAuthenticator {
  static getNewSessionCodes(String user, String pass, String baseURL) async {
    final String authenticationURL = baseURL + 'skyporthttp.w';
    print(authenticationURL);
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
    String dissectedString = postResponse.substring(4, postResponse.length - 5);
    var toks = dissectedString.split('^');
    if (toks.length < 15) {
      throw SkywardError('Your Skyward Service is under maintenence or a critical error has occured.');
    } else {
      return Map.fromIterables(
          ['dwd', 'wfaacl', 'encses'], [toks[0], toks[3], toks[14]]);
    }
  }
}
