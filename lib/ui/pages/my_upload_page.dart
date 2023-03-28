import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/form/index.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

class MyUploadPage extends StatefulWidget {
  const MyUploadPage({super.key});

  @override
  MyUploadPageState createState() => MyUploadPageState();
}

class MyUploadPageState extends State<MyUploadPage>
    with AutomaticKeepAliveClientMixin {
  final Map<String, String> _queryParams = {};
  List<Map<String, dynamic>> _queryResult = [];
  DateTime uploadDate = DateTime.now();
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _queryParams['uploadDate'] =
        DateUtil.formatDate(uploadDate, format: DateFormats.y_mo_d);
    startTimeOut(100);
  }

  /// 查询工作台内容
  doExecQuery() async {
    Map<String, dynamic>? res;
    try {
      Notify.loading(msg: '查询中....', context: context, radius: 50);
      res = await WbNetApi.queryMyUploadRecord(_queryParams);
      Notify.dismissAll();
    } catch (e) {}

    _queryResult = [];
    if (ObjectUtil.isEmpty(res) || !res!.containsKey("exec")) return;
    List<Map<String, dynamic>> queryList = List.from(res['exec'] as dynamic);
    if (ObjectUtil.isNotEmpty(queryList)) {
      for (int i = 0; i < queryList.length; i++) {
        Map<String, dynamic> item = queryList[i];
        item['index'] = i;
        item['isOpen'] = false;
        _queryResult.add(item);
      }
    }

    setState(() {
      _queryResult = _queryResult;
    });
  }

  /// 延迟查询工作台内容
  startTimeOut([int? milliseconds]) {
    var duration = Duration(milliseconds: milliseconds ?? 100);
    return Timer(duration, () {
      doExecQuery();
    });
  }

  /// 渲染结果单项记录
  Widget buildExpansionBody(List persons) {
    return Column(
        children: persons.map((person) {
      return ListTile(
          title: Row(children: [
        Expanded(
            child: Text(person['personName'],
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis)),
        Expanded(
            child: InkWell(
                onTap: () {
                  NavigatorUtil.launchInBrowser("tel:${person['phoneNumber']}");
                },
                child: Text(person['phoneNumber'] ?? '无',
                    style: const TextStyle(fontSize: 15, color: Colors.blue),
                    overflow: TextOverflow.ellipsis)))
      ]));
    }).toList());
  }

  /// 渲染查询结果
  Widget buildQueryResult() {
    _setCurrentIndex(int index, isExpand) {
      setState(() {
        for (var item in _queryResult) {
          if (item['index'] == index) {
            item['isOpen'] = !isExpand;
          } else {
            item['isOpen'] = false;
          }
        }
      });
    }

    return SingleChildScrollView(
        child: ObjectUtil.isEmpty(_queryResult) || _queryResult.isEmpty
            ? SizedBox(
                width: double.infinity,
                height: 300,
                child: Notify.noneWidget(msg: '未查询到相关信息'))
            : ExpansionPanelList(
                expansionCallback: (index, bol) {
                  _setCurrentIndex(index, bol);
                },
                children: _queryResult.map((item) {
                  return ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                            title: Text("${item['description']} ",
                                overflow: TextOverflow.ellipsis));
                      },
                      body: Column(children: <Widget>[
                        Container(
                            padding: const EdgeInsets.only(left: 15),
                            alignment: Alignment.centerLeft,
                            child: Text(item['description'] as String? ?? '')),
                        Container(
                            padding: const EdgeInsets.all(15),
                            alignment: Alignment.centerLeft,
                            child: Text(
                                "具体乘客名单：实载${item['checkNum']}人/核载${item['carrierNum']}人")),
                        buildExpansionBody(item['persons'] as dynamic ?? [])
                      ]),
                      isExpanded: item['isOpen'] == true);
                }).toList()));
  }

  buildQueryHeader() {
    return Container(
        padding: const EdgeInsets.only(left: 15),
        child: IFormItem.selectDate(context, "上报日期：", uploadDate,
            lastDate: DateTime.now(), cb: (DateTime res) {
          setState(() {
            uploadDate = res;
            _queryParams['uploadDate'] =
                DateUtil.formatDate(uploadDate, format: DateFormats.y_mo_d);
            doExecQuery();
          });
        }));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text("乘客上报记录"), centerTitle: true),
        body: Column(children: <Widget>[
          Container(child: buildQueryHeader()),
          Divider(height: 1.0, color: Colors.grey.withOpacity(0.2)),
          Expanded(child: buildQueryResult())
        ]));
  }
}
