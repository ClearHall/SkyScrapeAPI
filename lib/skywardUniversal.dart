library sky_universal;

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

/// Checks two items to make sure your session did not expire yet. Though, this may slow down your code, it'll help reduce error. [doc] should be valid HTML, if not, no error will be thrown.
bool didSessionExpire(String doc) {
  Document docs = parse(doc);
  List<Element> elems = docs.getElementsByClassName('sfLogout');

  if(elems.length > 0) return true;

  //Old method hardcoded
//  String literalToSearch =
//      "Your session has expired and you have been logged out.<br />You may close this window.";
//
//  for (Element elem in elems) {
//    for (Element script in elem.querySelectorAll('script')) {
//      if (script.text.contains(literalToSearch)) {
//        return true;
//      }
//    }
//  }

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
