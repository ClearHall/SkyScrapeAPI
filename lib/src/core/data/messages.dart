part of '../data_types.dart';

class Message {
  String date, header, dataId;
  MessageBody body;
  MessageTitle title;

  Message(this.dataId, this.date, this.header, this.title, this.body);

  @override
  bool operator ==(other) {
    return other is Message && other.title == this.title;
  }

  @override
  String toString() {
    return 'Message{date: $date, title: $title, header: $header, dataId: $dataId, body: $body}';
  }

  @override
  int get hashCode => title.hashCode;
}

class MessageTitle {
  String title;
  Link attachment;

  MessageTitle(this.title, this.attachment);

  @override
  String toString() {
    return 'MessageTitle{title: $title, attachment: $attachment}';
  }
}

class MessageBody {
  List _arr = [];

  void addTextSection(String txt) {
    _arr.add(txt);
  }

  void addLinkSection(String link, String txt) {
    if (_arr.last == link) _arr.removeLast();
    _arr.add(Link(link, txt));
  }

  List getArr() => _arr;

  @override
  String toString() {
    return 'MessageBody{_arr: $_arr}';
  }
}

class Link {
  final String link, text;

  Link(this.link, this.text);

  @override
  String toString() {
    return 'Link{link: $link, text: $text}';
  }
}
