library sky_universal;

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

attemptPost(String url, Map postCodes) async {
  final postReq = await http.post(url, body: postCodes);

  if (didSessionExpire(postReq.body))
    throw SkywardError('Session Expired');
  else
    return postReq.body;
}

/// Checks two items to make sure your session did not expire yet. Though, this may slow down your code, it'll help reduce error. [doc] should be valid HTML, if not, no error will be thrown.
bool didSessionExpire(String doc) {
  Document docs = parse(doc);
  List<Element> elems = docs.getElementsByClassName('sfLogout');

  if (elems.length > 0) return true;

  if (doc.contains("sff.httpCalls[''] = {") &&
      doc.contains(
          "'messages':[{show:true ,type:'dialog',target:'',message:'',code:''}],") &&
      doc.contains("'options':{status:\"logout\"}")) return true;

  return false;
}

/// SkyScrapeAPI Custom errors to locate errors and give proper causes.
///
/// **NOTE: THE WHOLE API WILL USE THIS EXCEPTION**
class SkywardError implements Exception {
  String cause;
  SkywardError(this.cause);

  @override
  String toString() {
    return cause;
  }
}
