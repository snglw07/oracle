import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'id_cloud_plugin.dart';
import 'wbcam/wb_cam_util.dart' as wbcamu;

class WbIdCloud {
  static final WbIdCloud _instance = WbIdCloud();

  static WbIdCloud instance() {
    return _instance;
  }

  void Function(Widget dlg, Map<String, dynamic>? map)? showDlg;

  WbIdCloud() {
    IdCloudPlugin.onRequestAccessToken = (String uid) {
      print('--------onRequestAccessToken--------');
      //替换为网络请求获取
      return Future<String>.value("ncyqtest");
    };

    IdCloudPlugin.init(
        netAddress: "222.178.243.202:60003", uid: "idcloudflutter");
    IdCloudPlugin.onTagDiscovered().listen((onData) {
      print('--------------nfc decode result--------------');
      print(onData.error);
      print(onData.content);
      print(onData.status);
      if (NFCStatus.error == onData.status)
        showNfcDlg(Text(onData.error ?? "" + "请重试读卡。"), null, null);
      else if (NFCStatus.reading == onData.status)
        showNfcDlg(Text('正在读取身份证，解码中'), null, null);
      else if (NFCStatus.read == onData.status) {
        Map<String, dynamic> map = {};

        onData.content?.forEach((key, value) {
          map["$key"] = value?.toString();
        });

        Widget? txt, img;

        if (map.containsKey("name")) {
          var msg =
              "姓名:${map['name']}\n性别代码:${map['sex_id']}\n性别描述:${map['sex_desc']}\n民族代码:${map['nation_id']}\n民族描述:${map['nation_desc']}";
          msg +=
              "\n出生日期:${map['birthdate']}\n地址:${map['address']}\n身份证号:${map['card_no']}";
          msg +=
              "\n有效期起始日期:${map['from_date']}\n有效期截至日期:${map['thru_date']}\n签发机关:${map['issue_dept']}";
          msg += "\n备用:${map['demo'] ?? ''}";

          txt = Text(msg);
        }

        if (map.containsKey("png"))
          img = Image.memory(map["png"]);
        else if (map.containsKey("jpg")) {
          var provider = wbcamu.toImageProvider(map["jpg"]!);
          if (provider != null) img = Image(image: provider);
        }

        showNfcDlg(txt, img, map);
      }
    });
  }

  void _buildDlg(String? title, List<Widget> children, List<Widget> buttons,
      Map<String, dynamic>? map) {
    var w = Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.black.withOpacity(0.7),
        child: Column(
          children: children,
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );

    showDlg!(w, map);
  }

  void showNfcDlg(Widget? txt, Widget? img, Map<String, dynamic>? map) {
    _buildDlg(
        '居民身份证信息云端解码',
        <Widget>[
          txt ?? Text("文本"),
          img ?? Text(""),
        ],
        <Widget>[
          TextButton(
              child: Text("关闭"),
              onPressed: () {
                //Navigator.of(context).pop();
              }),
        ],
        map);
  }
}
