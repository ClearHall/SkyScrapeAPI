import 'package:html/dom.dart';
import 'package:html/parser.dart';

import '../core/data_types.dart';

class MessageParser {
  static List<Message> parseMessage(String html) {
    Document document = parse(html);
    List<Element> messageElems = [];

    if (document.getElementById('MessageFeed') != null) {
      for (Element x in document
          .getElementById('MessageFeed')
          .querySelectorAll('.feedItem.allowRemove')) {
        messageElems.add(x);
      }
    } else {
      String docFragText = document.querySelector('output').innerHtml;
      DocumentFragment docfrag = DocumentFragment.html(docFragText.substring(
          "<!--[CDATA[".length, docFragText.lastIndexOf(']')));
      for (Element x in docfrag.querySelectorAll('.feedItem.allowRemove')) {
        messageElems.add(x);
      }
    }

    List<Message> messages = [];
    for (Element e in messageElems) {
      Element rootDiv = e.querySelector('div');
      String messageTextID =
          rootDiv.querySelector('div.messageBody > .text > span').id;
      int endInd = html.indexOf("').appendTo('#" + messageTextID + "');");
      int firstInd = html.substring(0, endInd).lastIndexOf("\$('") + 3;
      DocumentFragment documentFragment =
          DocumentFragment.html(html.substring(firstInd, endInd));

      MessageBody messageBody = MessageBody();
      List<Element> aList = documentFragment.querySelectorAll('div');

      while (aList.length > 0) {
        List tmp = aList.first.querySelectorAll('div');
        if (tmp.isEmpty) {
          break;
        } else {
          aList = tmp;
        }
      }

      List bList = [];
      for (Element aL in aList) {
        String aLHTML = aL.innerHtml;
        if (aL.children.length >= 1) {
          for (int i = 0; i < aL.children.length; i++) {
            if (aL.children[i].outerHtml.startsWith('<a')) {
              List split = aLHTML.split(aL.children[i].outerHtml);
              bList.add(Element.html('<div>' + split[0] + '</div>'));
              bList.add(Element.html(aL.children[i].outerHtml));
              if (split.length > 1)
                aLHTML = split[1];
              else
                aLHTML = '';
            }
          }
          bList.add(Element.html('<div>' + aLHTML + '</div>'));
        } else {
          bList.add(aL);
        }
      }
      for (Element element in bList) {
        if (element.attributes.containsKey('href')) {
          messageBody.addLinkSection(element.attributes['href'], element.text);
        } else if (element.text.isNotEmpty) {
          messageBody.addTextSection(element.text);
        } else {
          messageBody.addTextSection('\n');
        }
      }

      Element title = rootDiv.querySelector('.messageBody > .text');
      List<Element> subjects = title.getElementsByClassName('Subject');
      List<Element> attachments = title.getElementsByClassName('Attachments');
      messages.add(Message(
          rootDiv.attributes['data-wall-id'],
          rootDiv.querySelector('.messageBody > .date').text.trim(),
          rootDiv.querySelector('.messageHead').text.trim(),
          subjects.length == 0 && attachments.length == 0
              ? null
              : MessageTitle(
                  subjects.isNotEmpty ? subjects.first.text.trim() : null,
                  attachments.isNotEmpty
                      ? Link(
                          attachments.first.children.first.attributes['href'],
                          attachments.first.children.first.text)
                      : null),
          messageBody));
    }

    return messages;
  }
}
