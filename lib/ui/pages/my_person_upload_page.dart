import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

class MyRyUploadPage extends StatefulWidget {
  const MyRyUploadPage({super.key});

  @override
  MyRyUploadPageState createState() => MyRyUploadPageState();
}

class MyRyUploadPageState extends State<MyRyUploadPage>
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
      res =
          await WbNetApi.exec('wbyq.yqfk.ryupload.query', params: _queryParams);
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
      return Container();
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
                            title: Text(
                                "${item['upTime']}   ${item['personName']}   ${item['riskLevelDesc']} ",
                                overflow: TextOverflow.ellipsis));
                      },
                      body: Column(children: <Widget>[
                        Container(
                            padding: const EdgeInsets.only(left: 15),
                            alignment: Alignment.centerLeft,
                            child: ListTile(
                                title: Row(children: [
                              const Expanded(
                                  flex: 1,
                                  child: Text('上报时间:',
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis)),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                      item['recordDate'] ?? '' as dynamic,
                                      style: const TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis))
                            ]))),
                        Container(
                            padding: const EdgeInsets.only(left: 15),
                            alignment: Alignment.centerLeft,
                            child: ListTile(
                                title: Row(children: [
                              const Expanded(
                                  flex: 1,
                                  child: Text('健康状态:',
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis)),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                      "${item['healthStateDesc']} ${item['healthRemark'] ?? ''}",
                                      style: const TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis))
                            ]))),
                        Container(
                            padding: const EdgeInsets.only(left: 15),
                            alignment: Alignment.centerLeft,
                            child: ListTile(
                                title: Row(children: [
                              const Expanded(
                                  flex: 1,
                                  child: Text('来  源  地:',
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis)),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                      item['fcitySelected'] ?? "未定位" as dynamic,
                                      style: const TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis))
                            ]))),
                        Container(
                            padding: const EdgeInsets.only(left: 15),
                            alignment: Alignment.centerLeft,
                            child: ListTile(
                                title: Row(children: [
                              const Expanded(
                                  flex: 1,
                                  child: Text('联系电话:',
                                      style: TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis)),
                              Expanded(
                                  flex: 3,
                                  child: InkWell(
                                      onTap: () {
                                        NavigatorUtil.launchInBrowser(
                                            "tel:${item['phoneNumber']}");
                                      },
                                      child: Text(
                                          item['phoneNumber'] ?? '无' as dynamic,
                                          style: const TextStyle(
                                              fontSize: 15, color: Colors.blue),
                                          overflow: TextOverflow.ellipsis)))
                            ]))),
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
        appBar: AppBar(
          title: const Text("返南人员上报记录"),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.help),
              onPressed: () {
                WbUtils.confirm(
                  context,
                  content: "根据记录创建日期和记录最后修改日期查询上报记录",
                  showCancel: false,
                );
              },
            )
          ],
        ),
        body: Column(children: <Widget>[
          Container(child: buildQueryHeader()),
          Divider(height: 1.0, color: Colors.grey.withOpacity(0.2)),
          Expanded(child: buildQueryResult())
        ]));
  }
}
