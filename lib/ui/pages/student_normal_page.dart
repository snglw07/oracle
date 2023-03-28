import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';

class StudentNormalPage extends StatefulWidget {
  final String? schoolId;
  final String? gradeId;
  final String? classId;
  StudentNormalPage(this.schoolId, this.gradeId, this.classId);

  _StudentNormalPage createState() =>
      _StudentNormalPage(schoolId, gradeId, classId);
}

class _StudentNormalPage extends State<StudentNormalPage> {
  final String? schoolId;
  final String? gradeId;
  final String? classId;
  _StudentNormalPage(this.schoolId, this.gradeId, this.classId);

  String? exType;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("无异常无请假"),
        centerTitle: true,
        actions: [
          Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 64.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigoAccent,
                      ),
                      child: Text("确定", style: TextStyle(fontSize: 12.0)),
                      onPressed: () {
                        _onSubmit();
                      })))
        ],
      ),
      body: ListView(
        children: <Widget>[
          RadioListTile(
              title: Text('晨检'),
              value: 'M',
              groupValue: exType,
              onChanged: (value) {
                setState(() {
                  exType = value ?? "" as dynamic;
                });
              }),
          RadioListTile(
              title: Text('午检'),
              value: 'A',
              groupValue: exType,
              onChanged: (value) {
                setState(() {
                  exType = value ?? "" as dynamic;
                });
              }),
          RadioListTile(
              title: Text('晚检'),
              value: 'N',
              groupValue: exType,
              onChanged: (value) {
                setState(() {
                  exType = value ?? "" as dynamic;
                });
              })
        ],
      ),
    );
  }

  _onSubmit() {
    if (ObjectUtil.isEmpty(exType)) {
      Notify.error("请选择检查类型", context: context, duration: Duration(seconds: 3));
      return;
    }

    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: '正在保存...');
        });

    Map<String, dynamic> data = {
      'schoolId': this.schoolId ?? "",
      'gradeId': this.gradeId ?? "",
      'classId': this.classId ?? "",
      'personType': ObjectUtil.isNotEmpty(this.classId) ? '1' : '2',
      'exType': exType ?? ""
    };

    WbNetApi.studentNormalStore(data).then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true)
        Notify.error(result!["error"] ?? "提交失败",
            context: context, duration: Duration(seconds: 4));
      else {
        Notify.success("提交成功",
            context: context, duration: Duration(seconds: 4));
        Navigator.pop(context);
      }
    });
  }
}
