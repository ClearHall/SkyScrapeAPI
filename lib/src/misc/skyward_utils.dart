library sky_universal;

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../core/data_types.dart';

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
