import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';

class SchedulePage extends StatefulWidget {
  final String? scheduleId;
  final ValueChanged<Map>? onSave;

  const SchedulePage({super.key, this.scheduleId, this.onSave});

  @override
  _SchedulePage createState() =>
      _SchedulePage(scheduleId: scheduleId, onSave: onSave);
}

class _SchedulePage extends State<SchedulePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final String? scheduleId;
  final ValueChanged<Map>? onSave;
  String? token;
  _SchedulePage({this.scheduleId, this.onSave}) {
    token = this.scheduleId;
  }

  Map<String, dynamic> doc = {};
  @override
  void initState() {
    super.initState();
    WbNetApi.getMyLoginInfo().then((map) {
      setState(() {
        doc['driverName'] = map['lastName'] ?? '';
        doc['driverIdcardNum'] = map['idcardNumber'] ?? '';
        doc['driverPhone'] = map['phoneNumber'] ?? '';
      });
    });
    doc['departDate'] = DateTime.now();
    doc['departTime'] = TimeOfDay.now();
    doc['fromStation'] = '';
    doc['toStation'] = '';
    doc['cc'] = '';
    doc['toNc'] = '';
    doc['licensePlate'] = '渝';
    doc['refer'] = "APP";
  }

  void _onSubmit(BuildContext context) async {
    if (ObjectUtil.isEmpty(scheduleId) && ObjectUtil.isEmpty(token))
      token = await WbNetApi.token();

    Map<String, Object?> map = Map.from(doc);
    map['token'] = token;
    if (ObjectUtil.isEmpty(map['scheduleId']))
      map['scheduleId'] = this.scheduleId ?? "";

    DateTime departDate = doc['departDate'] as dynamic;
    map['departDate'] =
        intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(departDate);

    print(map);
    var errTag = "";
    if (!WbUtils.isChinaPhoneLegal(doc['driverPhone'] ?? "" as dynamic))
      errTag = "请输入正确的联系电话";
    if (!RegexUtil.isIDCard18(doc['driverIdcardNum'] ?? "" as dynamic))
      errTag = "请输入正确的身份证号";
    if (!RegexUtil.matches("[1-9]\d*", map['carrierNum'] ?? "" as dynamic))
      errTag = "请输入正确的核载人数";
    if (ObjectUtil.isEmpty(map['cc'])) errTag = "请输入车次";
    if (!WbUtils.isPlateNoLegal(map['licensePlate'] ?? '' as dynamic))
      errTag = "请输入正确的车牌号";

    if (ObjectUtil.isEmpty(map['toNc'])) errTag = "请选择目的地是否南川";
    if (ObjectUtil.isEmpty(map['toStation'])) errTag = "请输入终点站";
    if (ObjectUtil.isEmpty(map['fromStation'])) errTag = "请输入起点站";

    if (ObjectUtil.isEmpty(map['departDate']) ||
        ObjectUtil.isEmpty(map['driverName'])) errTag = "请检查必录项是否已经正确录入";

    if ("" != errTag) {
      Notify.error(errTag, context: context, duration: Duration(seconds: 3));
      return;
    }

    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: '正在保存...');
        });

    WbNetApi.storeSchedule(map).then((Map<String, dynamic>? result) {
      Navigator.pop(context);

      result ??= <String, dynamic>{};
      if (result.containsKey('error')) {
        Notify.error(result["error"] ?? "保存失败" as dynamic, context: context);
      } else {
        Notify.success("保存成功", context: context);
        doc['scheduleId'] = result['scheduleId'] ?? doc['token'] as dynamic;
        if (ObjectUtil.isNotEmpty(onSave)) {
          onSave!(result);
        }
      }
    });
  }

  Widget _buildPage(BuildContext context) {
    return ListView(children: <Widget>[
      IFormItem.selectDate(context, "发车日期：", doc['departDate'] as dynamic,
          requiredValue: true, cb: (DateTime res) {
        setState(() {
          doc['departDate'] = res;
        });
      }),
      IFormItem.selectTime(context, "发车时间：", doc['departTime'] as dynamic,
          requiredValue: true, cb: (TimeOfDay res) {
        setState(() {
          if (ObjectUtil.isNotEmpty(res))
            doc['departTime'] = res;
          else
            res = doc['departTime'] as dynamic;

          DateTime departDate = doc['departDate'] as dynamic;
          doc['departDate'] = DateTime(departDate.year, departDate.month,
              departDate.day, res.hour, res.minute);
        });
      }),
/*       IFormItem.selectEnumType(
          context, '起  点  站:', fromStationLabel, "DUALRE_APPT_TYPE",
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['fromStation'] = res['value'];
          fromStationLabel = res['description'];
        });
      }), */
      ITextFieldItem(
          requiredValue: true,
          labelText: '起  点  站:',
          inputText: doc['fromStation'] ?? "" as dynamic,
          onChange: (value) {
            doc['fromStation'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '终  点  站:',
          inputText: doc['toStation'] ?? "" as dynamic,
          onChange: (value) {
            doc['toStation'] = value;
          }),
      IFormItem.selectType(
          context,
          '目的地是否南川:',
          doc['toNc'] ?? "" as dynamic,
          [
            {'value': 'Y', 'description': '是'},
            {'value': 'N', 'description': '否'}
          ],
          flex1: 1,
          flex2: 1,
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['toNc'] = '';
          if (ObjectUtil.isNotEmpty(res)) doc['toNc'] = res['value'];
        });
      }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '车  牌  号:',
          inputText: doc['licensePlate'] ?? "" as dynamic,
          onChange: (value) {
            doc['licensePlate'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '车        次:',
          inputText: doc['cc'] ?? "" as dynamic,
          onChange: (value) {
            doc['cc'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '核载人数:',
          keyboardType: TextInputType.number,
          inputText: doc['carrierNum'] ?? "" as dynamic,
          onChange: (value) {
            doc['carrierNum'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '驾驶员姓名：',
          inputText: doc['driverName'] ?? "" as dynamic,
          onChange: (value) {
            doc['driverName'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '身份证号:',
          inputText: doc['driverIdcardNum'] ?? "" as dynamic,
          onChange: (value) {
            doc['driverIdcardNum'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '联系电话：',
          keyboardType: TextInputType.phone,
          inputText: doc['driverPhone'] ?? "" as dynamic,
          onChange: (value) {
            doc['driverPhone'] = value;
          })
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: Text("车次排班"), centerTitle: true, actions: [
          Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 64.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigoAccent,
                      ),
                      child: Text("保存", style: TextStyle(fontSize: 12.0)),
                      onPressed: () {
                        _onSubmit(context);
                      })))
        ]),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: _buildPage(context)))
        ])));
  }
}
