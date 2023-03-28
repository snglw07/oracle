import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MsgComModel {
  String? title;
  String? content;
  String? extra;
  Icon? icon;
  Color? color;
  String? imgUrl;
  String? url;
  String? msgNum;
  String? updatedAt;
  Widget? page;

  MsgComModel(
      {this.title,
      this.content,
      this.extra,
      this.icon,
      this.url,
      this.imgUrl,
      this.msgNum,
      this.updatedAt,
      this.page});

  MsgComModel.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        content = json['content'],
        extra = json['extra'],
        icon = json['icon'],
        color = json['color'],
        imgUrl = json['imgUrl'],
        url = json['url'],
        msgNum = json['msgNum'],
        updatedAt = json['updatedAt'];
}
