import 'package:flutter/material.dart';
import 'package:wbyq/ui/widgets/widget_index.dart';

import '../index.dart';
/* 
class FormTestPageLocal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future:
                rootBundle.loadString('assets/data/ehrform.json').then((json) {
              Map<String, dynamic> map = jsonDecode(json);
              return WbFormCfg(map);
            }).catchError((e) {
              return WbFormCfg({"children": []});
            }),
            builder: (BuildContext context, AsyncSnapshot<WbFormCfg> snapshot) {
              if (!snapshot.hasData) return Text("无数据");
              return WbFormWidget(snapshot.data);
            }));
  }
} */

class FormTestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: WbFormApi.formCfg("/公共卫生/个人基本信息表appd", isForce: true)
            .then((Map<String, dynamic> result) {
          return WbFormPageCfg(result, title: '个人基本信息表');
        }).catchError((e) {
          print(e);
          Notify.error('加载模板文件出错。', context: context);
        }),
        builder: (BuildContext context, AsyncSnapshot<WbFormPageCfg> snapshot) {
          if (!snapshot.hasData) return ProgressView();
          return WbPageWidget(snapshot.data!, {});
        });
  }
}
