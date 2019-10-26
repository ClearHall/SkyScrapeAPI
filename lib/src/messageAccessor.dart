import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../data_types.dart';

class MessageAccessor {

  static getMessages(String messagePageHTML) {
    var parsed = parse(messagePageHTML);
    List<Element> rawMessage = parsed.querySelectorAll(".home_MessageFeed > li");
    List<Message> processedMessages = [];
    for (Element i in rawMessage) {
      processedMessages.add(Message.fromJson({
        "name" : i.querySelector("[data-type = \"teacher\"]").text,
        "date" : i.querySelector(".date").text,
        "body" : i.querySelector(".msgDetail").text
      }));
    }
    return processedMessages;
  }
}