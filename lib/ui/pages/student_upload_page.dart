import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/models/student_info_model.dart';
import 'package:wbyq/ui/widgets/Iform_item.dart';
import 'package:intl/intl.dart' as intl;

class StudentUploadPage extends StatefulWidget {
  final String? studentId;
  final StudentInfoModel studentInfo;

  const StudentUploadPage(this.studentId, this.studentInfo, {super.key});

  @override
  State createState() => StudentUploadPageState();
}

class StudentUploadPageState extends State<StudentUploadPage> {
  Map<String, dynamic> doc = {};

  bool loading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    doc = {
      'recordId': '',
      'studentId': widget.studentId ?? '',
      'name': '',
      'idcardNumber': '',
      'schoolSelected': '',
      'classSelected': '',
      'exType': '',
      'leave': 'ZX',
      'otherLeave': '',
      'inHospital': '',
      'temperature': '',
      'symptom': '',
      'symptomStr': '',
      'otherSymptom': '',
      'screeningResult': '',
      'contagion': '',
      'contagionStr': '',
      'classify': '',
      'otherResult': '',
      'otherContagion': '',
      'lxDate': DateTime.now(),
      'isBack': 'N',
      'backDate': DateTime.now(),
      'exRecordId': '',
      'diagnoseCompany': '',
      'diagnose': ''
    };

    if (widget.studentInfo.statusCode == 'ZX') {
      setState(() {
        doc['name'] = widget.studentInfo.name ?? "";
        doc['schoolSelected'] = widget.studentInfo.schoolName ?? "";
        String gradeName = ObjectUtil.isEmpty(widget.studentInfo.gradeName)
            ? ''
            : widget.studentInfo.gradeName!;
        String className = ObjectUtil.isEmpty(widget.studentInfo.className)
            ? ''
            : widget.studentInfo.className!;
        doc['classSelected'] = gradeName + className;
        doc['leave'] = 'ZX';
      });
    } else {
      WbNetApi.queryStudentInfo(widget.studentId ?? "").then((map) {
        Map<String, dynamic>? res = map?['exec'] as dynamic;
        res ??= <String, dynamic>{};
        if (ObjectUtil.isNotEmpty(res['temperature'])) {
          res['temperature'] = res['temperature'].toString();
        }

        if (ObjectUtil.isNotEmpty(res['lxDate'])) {
          res['lxDate'] = DateTime.parse(res['lxDate'].toString());
        }

        res['symptom'] = res['symptomStr'] ?? "";
        if (ObjectUtil.isNotEmpty(res['symptomStr'])) {
          List symptomList = json.decode(res['symptomStr'] as dynamic) as List;
          res['symptomStr'] = symptomList.join(',');
        }

        res['contagion'] = res['contagionStr'] ?? "";
        if (ObjectUtil.isNotEmpty(res['contagionStr'])) {
          List contagionList =
              json.decode(res['contagionStr'] as dynamic) as List;
          res['contagionStr'] = contagionList.join(',');
        }

        setState(() {
          doc.addAll(res ?? <String, Object>{});
        });
      });
    }
  }

  void _onSubmit(BuildContext context) async {
    // 获取token
    if (loading) {
      Notify.error("处理中，请勿重复点击。", context: context);
      return;
    }
    loading = true;

    Map<String, dynamic> map = Map.from(doc);

    // 提交内容校验
    if (ObjectUtil.isEmpty(map['leave'])) {
      Notify.error("请检查必录项是否已经正确录入",
          context: context, duration: const Duration(seconds: 3));
      loading = false;
      return;
    }

    if (widget.studentInfo.statusCode == 'ZX' &&
        ObjectUtil.isEmpty(map['exType'])) {
      Notify.error("请检查必录项是否已经正确录入",
          context: context, duration: const Duration(seconds: 3));
      loading = false;
      return;
    }

    if (map['leave'] != 'ZX' && ObjectUtil.isEmpty(map['lxDate'])) {
      Notify.error("请选择离校时间",
          context: context, duration: const Duration(seconds: 3));
      loading = false;
      return;
    }

    if (map['leave'] == 'ZX' || map['leave'] == 'BJ') {
      if (ObjectUtil.isEmpty(map['temperature']) ||
          ObjectUtil.isEmpty(map['symptom']) ||
          ObjectUtil.isEmpty(map['screeningResult']) ||
          ObjectUtil.isEmpty(map['contagion']) ||
          (ObjectUtil.isEmpty(map['diagnoseCompany']) &&
              map['leave'] == 'BJ') ||
          (ObjectUtil.isEmpty(map['diagnose']) && map['leave'] == 'BJ') ||
          ObjectUtil.isEmpty(map['inHospital'])) {
        Notify.error("请检查必录项是否已经正确录入",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (double.parse(map['temperature']) > 37.2 &&
          !map['symptom'].toString().contains('发热')) {
        Notify.error("体温大于37.2时，症状需选择'发热'",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (double.parse(map['temperature']) <= 37.2 &&
          map['symptom'].toString().contains('发热')) {
        Notify.error("症状选择'发热'时，体温需大于37.2",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (map['leave'] == 'QT' && ObjectUtil.isEmpty(map['otherLeave'])) {
        Notify.error("请输入其他缺课原因",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (map['symptom'].toString().contains('其他') &&
          ObjectUtil.isEmpty(map['otherSymptom'])) {
        Notify.error("请输入其他症状",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (map['screeningResult'] == 'QT' &&
          ObjectUtil.isEmpty(map['otherResult'])) {
        Notify.error("请输入其他筛查结果",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (map['contagion'].toString().contains('其他') &&
          ObjectUtil.isEmpty(map['otherContagion'])) {
        Notify.error("请输入其他传染病",
            context: context, duration: const Duration(seconds: 3));
        loading = false;
        return;
      }

      if (double.parse(map['temperature']) < 37.3 &&
          !map['symptom'].toString().contains('无')) {
        map['classify'] = '第一类';
      } else if (double.parse(map['temperature']) >= 37.3 &&
          (map['symptom'].toString().contains('无') || map['symptom'] == '发热')) {
        map['classify'] = '第二类';
      } else if (double.parse(map['temperature']) >= 37.3 &&
          !map['symptom'].toString().contains('无')) {
        map['classify'] = '第三类';
      }
    }

    if (map['leave'] == 'ZX') map['lxDate'] = '';

    if (map['isBack'] != 'Y') map['backDate'] = '';

    if (ObjectUtil.isNotEmpty(map['lxDate'])) {
      map['lxDate'] =
          intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(map['lxDate']);
    }
    if (ObjectUtil.isNotEmpty(map['backDate'])) {
      map['backDate'] =
          intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(map['backDate']);
    }
    map['fromTag'] = 'app';
    _doSubmit(map);
  }

  void _doSubmit(map) {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(text: '正在保存...');
        });

    String url = '';
    if (widget.studentInfo.statusCode == 'ZX' || map['leave'] == 'ZX') {
      url = 'xx.student.ex.store';
      if (ObjectUtil.isNotEmpty(map['exRecordId'])) {
        map['recordId'] = map['exRecordId'];
      }
    } else {
      url = 'xx.student.leave.detail.store';
    }

    WbNetApi.storeStudentEx(map, url).then((Map<String, dynamic>? result) {
      Navigator.pop(context);
      if (result?.containsKey('error') == true) {
        Notify.error(result!["error"] ?? "保存失败",
            context: context, duration: const Duration(seconds: 4));
      } else {
        Notify.success("保存成功",
            context: context, duration: const Duration(seconds: 4));
        doc['recordId'] = result?['recordId'] ?? "";
        Navigator.pop(context);
      }
      loading = false;
    });
  }

  Widget _buildPage(BuildContext context) {
    List<Map<String, dynamic>> symptoms = [
      //{'description': "无", 'value': "无", "isMutex": true},
      {'description': "发热", 'value': "发热"},
      {'description': "寒战", 'value': "寒战"},
      {'description': "干咳", 'value': "干咳"},
      {'description': "咳痰", 'value': "咳痰"},
      {'description': "鼻塞", 'value': "鼻塞"},
      {'description': "流涕", 'value': "流涕"},
      {'description': "咽痛", 'value': "咽痛"},
      {'description': "头痛", 'value': "头痛"},
      {'description': "乏力", 'value': "乏力"},
      {'description': "肌肉酸痛", 'value': "肌肉酸痛"},
      {'description': "关节酸痛", 'value': "关节酸痛"},
      {'description': "气促", 'value': "气促"},
      {'description': "呼吸困难", 'value': "呼吸困难"},
      {'description': "胸闷", 'value': "胸闷"},
      {'description': "胸痛", 'value': "胸痛"},
      {'description': "结膜充血", 'value': "结膜充血"},
      {'description': "恶心", 'value': "恶心"},
      {'description': "呕吐", 'value': "呕吐"},
      {'description': "腹泻", 'value': "腹泻"},
      {'description': "腹痛", 'value': "腹痛"},
      {'description': "其他", 'value': "其他"},
    ];

    /* List<Map<String, dynamic>> symptomList = List();
    symptoms.forEach((var symptom){
      if(doc['symptom'].toString().indexOf(symptom['value']) > -1)
        symptom['checked'] = true;
      else
        symptom['checked'] = false;

      symptomList.add(symptom);
    }); */

    List<Map<String, dynamic>> contagions = [
      {'description': "无", 'value': "无", "isMutex": true},
      {'description': "水痘", 'value': "水痘"},
      {'description': "手足口病", 'value': "手足口病"},
      {'description': "流行性腮腺炎", 'value': "流行性腮腺炎"},
      {'description': "感染性腹泻", 'value': "感染性腹泻"},
      {'description': "急性出血性结膜炎", 'value': "急性出血性结膜炎"},
      {'description': "风疹", 'value': "风疹"},
      {'description': "麻疹", 'value': "麻疹"},
      {'description': "诺如病毒急性胃肠炎", 'value': "诺如病毒急性胃肠炎"},
      {'description': "肺结核", 'value': "肺结核"},
      {'description': "细菌性痢疾", 'value': "细菌性痢疾"},
      {'description': "流行性感冒”", 'value': "流行性感冒”"},
      {'description': "新型冠状病毒感染", 'value': "新型冠状病毒感染"},
      {'description': "其他", 'value': "其他"},
    ];

    /* List<Map<String, dynamic>> contagionList = List();
    contagions.forEach((var contagion){
      if(doc['contagion'].toString().indexOf(contagion['value']) > -1)
        contagion['checked'] = true;
      else
        contagion['checked'] = false;

      contagionList.add(contagion);
    }); */

    return ListView(children: <Widget>[
      ITextFieldItem(
          requiredValue: true,
          labelText: '姓名:',
          inputText: doc['name'] ?? "" as dynamic,
          enabled: false,
          onChange: (value) async {
            doc['name'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '学校：',
          inputText: doc['schoolSelected'] ?? "" as dynamic,
          enabled: false,
          onChange: (value) {
            doc['schoolSelected'] = value;
          }),
      ITextFieldItem(
          requiredValue: true,
          labelText: '班级：',
          keyboardType: TextInputType.phone,
          inputText: doc['classSelected'] ?? "" as dynamic,
          enabled: false,
          onChange: (value) {
            doc['classSelected'] = value;
          }),
      IFormItem.selectType(
          context,
          '缺勤登记:',
          doc['leave'] ?? "" as dynamic,
          [
            {'description': "在校异常", 'value': "ZX"},
            {'description': "病假", 'value': "BJ"},
            {'description': "事假", 'value': "SJ"},
            {'description': "其他", 'value': "QT"}
          ],
          enabled:
              !(ObjectUtil.isNotEmpty(doc['recordId']) && doc['leave'] != 'ZX'),
          requiredValue: true, cb: (Map res) {
        setState(() {
          doc['leave'] =
              ObjectUtil.isNotEmpty(res) ? res['value'] : doc['leave'];
          if (doc['leave'] != 'QT') {
            doc['otherLeave'] = '';
          }
          if (doc['leave'] == 'SJ' || doc['leave'] == 'QT') {
            doc['inHospital'] = '';
            doc['temperature'] = '';
            doc['symptom'] = '';
            doc['otherSymptom'] = '';
            doc['screeningResult'] = '';
            doc['contagion'] = '';
            doc['classify'] = '';
            doc['otherResult'] = '';
            doc['otherContagion'] = '';
          }
        });
      }),
      Visibility(
        visible: doc['leave'] == 'QT',
        child: ITextFieldItem(
            requiredValue: doc['leave'] == 'QT',
            labelText: '其他缺课原因：',
            inputText: doc['otherLeave'] ?? "" as dynamic,
            onChange: (value) {
              doc['otherLeave'] = value;
            }),
      ),
      Visibility(
        visible: ObjectUtil.isEmpty(doc['recordId']) || doc['leave'] == 'ZX',
        child: IFormItem.selectType(
            context,
            '检查类型:',
            doc['exType'] ?? "" as dynamic,
            [
              {'description': "晨检", 'value': "M"},
              {'description': "午检", 'value': "A"},
              {'description': "晚检", 'value': "N"}
            ],
            requiredValue: true, cb: (Map res) {
          String exType =
              ObjectUtil.isNotEmpty(res) ? res['value'] : doc['exType'];
          WbNetApi.studentExRecordQuery(widget.studentId ?? "", exType)
              .then((data) {
            data ??= <String, dynamic>{};

            setState(() {
              doc['exType'] =
                  ObjectUtil.isNotEmpty(res) ? res['value'] : doc['exType'];
              if (data!.containsKey("exec") &&
                  ObjectUtil.isNotEmpty(data['exec'])) {
                var res = data['exec'] as Map;
                doc['temperature'] = res['temperature'].toString();
                doc['symptom'] = res['symptom'];
                List symptomList = json.decode(res['symptom']) as List;
                doc['symptomStr'] = symptomList.join(',');
                doc['otherSymptom'] = res["otherSymptom"];
                doc['screeningResult'] = res["screeningResult"];
                doc['otherResult'] = res["otherResult"];
                doc['inHospital'] = res["inHospital"];
                doc['contagion'] = res["contagion"];
                List contagionList = json.decode(res['contagion']) as List;
                doc['contagionStr'] = contagionList.join(',');
                doc['otherContagion'] = res["otherContagion"];
                doc['exRecordId'] = res['recordId'];
              } else {
                doc['recordId'] = '';
              }
            });
          });
        }),
      ),
      Visibility(
        visible: doc['leave'] == 'ZX' || doc['leave'] == 'BJ',
        child: ITextFieldItem(
            requiredValue: true,
            labelText: '体温：',
            keyboardType: TextInputType.number,
            inputText: doc['temperature'] ?? "" as dynamic,
            appendWidget: const Text("℃"),
            onChange: (value) {
              doc['temperature'] = value;
            }),
      ),
      Visibility(
        visible: doc['leave'] == 'ZX' || doc['leave'] == 'BJ',
        child: IFormItem.selectCheckBox(
            context, '症状:', doc['symptomStr'] ?? "" as dynamic, symptoms,
            requiredValue: true, cb: (Map res) {
          setState(() {
            doc['symptomStr'] = ObjectUtil.isNotEmpty(res)
                ? res['strValue']
                : doc['symptomStr'];
            doc['symptom'] =
                ObjectUtil.isNotEmpty(res) ? res['jsonStr'] : doc['symptom'];
            if (ObjectUtil.isNotEmpty(doc['symptom']) &&
                doc['symptom'].toString().contains('其他')) {
              doc['otherResult'] = '';
            }
          });
        }),
      ),
      Visibility(
        visible: (doc['leave'] == 'ZX' || doc['leave'] == 'BJ') &&
            ObjectUtil.isNotEmpty(doc['symptom']) &&
            doc['symptom'].toString().contains('其他'),
        child: ITextFieldItem(
            requiredValue: ObjectUtil.isNotEmpty(doc['symptom']) &&
                doc['symptom'].toString().contains('其他'),
            labelText: '其他症状：',
            inputText: doc['otherSymptom'] ?? "" as dynamic,
            onChange: (value) {
              doc['otherSymptom'] = value;
            }),
      ),
      // Visibility(
      //   visible: doc['leave'] == 'ZX' || doc['leave'] == 'BJ',
      //   child: IFormItem.selectType(
      //       context,
      //       '筛查结果:',
      //       doc['screeningResult'] ?? "" as dynamic,
      //       [
      //         {'description': "上感", 'value': "上感"},
      //         {'description': "流感", 'value': "流感"},
      //         {'description': "不能排除新冠", 'value': "不能排除新冠"},
      //         {'description': "其他", 'value': "其他"}
      //       ],
      //       requiredValue: true, cb: (Map res) {
      //     setState(() {
      //       doc['screeningResult'] = ObjectUtil.isNotEmpty(res)
      //           ? res['value']
      //           : doc['screeningResult'];
      //       if (doc['screeningResult'] != '其他') doc['otherResult'] = '';
      //     });
      //   }),
      // ),
      Visibility(
        visible: (doc['leave'] == 'ZX' || doc['leave'] == 'BJ') &&
            doc['screeningResult'] == '其他',
        child: ITextFieldItem(
            requiredValue: doc['screeningResult'] == '其他',
            labelText: '其他筛查结果：',
            inputText: doc['otherResult'] ?? "" as dynamic,
            onChange: (value) {
              doc['otherResult'] = value;
            }),
      ),
      Visibility(
        visible: doc['leave'] == 'ZX' || doc['leave'] == 'BJ',
        child: IFormItem.selectCheckBox(
            context, '常见传染病:', doc['contagionStr'] ?? "" as dynamic, contagions,
            requiredValue: true, cb: (Map res) {
          setState(() {
            doc['contagionStr'] = ObjectUtil.isNotEmpty(res)
                ? res['strValue']
                : doc['contagionStr'];
            doc['contagion'] =
                ObjectUtil.isNotEmpty(res) ? res['jsonStr'] : doc['contagion'];
            if (ObjectUtil.isNotEmpty(doc['contagion']) &&
                doc['contagion'].toString().contains('其他')) {
              doc['otherContagion'] = '';
            }
          });
        }),
      ),
      Visibility(
        visible: (doc['leave'] == 'ZX' || doc['leave'] == 'BJ') &&
            ObjectUtil.isNotEmpty(doc['contagion']) &&
            doc['contagion'].toString().contains('其他'),
        child: ITextFieldItem(
            requiredValue: ObjectUtil.isNotEmpty(doc['contagion']) &&
                doc['contagion'].toString().contains('其他'),
            labelText: '其他传染病：',
            inputText: doc['otherContagion'] ?? "" as dynamic,
            enabled: ObjectUtil.isNotEmpty(doc['contagion']) &&
                doc['contagion'].toString().contains('其他'),
            onChange: (value) {
              doc['otherContagion'] = value;
            }),
      ),
      Visibility(
        visible: doc['leave'] == 'ZX' || doc['leave'] == 'BJ',
        child: IFormItem.selectType(
            context,
            '是否在院治疗:',
            doc['inHospital'] ?? "" as dynamic,
            [
              {'description': "是", 'value': "Y"},
              {'description': "否", 'value': "N"}
            ],
            requiredValue: true, cb: (Map res) {
          setState(() {
            doc['inHospital'] =
                ObjectUtil.isNotEmpty(res) ? res['value'] : doc['inHospital'];
          });
        }),
      ),
      Visibility(
        visible: doc['leave'] == 'BJ',
        child: ITextFieldItem(
            requiredValue: doc['leave'] == 'BJ',
            labelText: '疾病诊断：',
            inputText: doc['diagnose'] ?? "" as dynamic,
            onChange: (value) {
              doc['diagnose'] = value;
            }),
      ),
      Visibility(
        visible: doc['leave'] == 'BJ',
        child: IFormItem.selectExecType(
            context,
            '诊断机构:',
            doc['diagnoseCompany'] ?? "" as dynamic,
            'xx.app.diagnose.company.query',
            requiredValue: doc['leave'] == 'BJ', cb: (Map res) {
          setState(() {
            doc['diagnoseCompany'] = ObjectUtil.isNotEmpty(res)
                ? res['value']
                : doc['diagnoseCompany'];
          });
        }),
      ),
      Visibility(
          visible: doc['leave'] != 'ZX',
          child: IFormItem.selectDate(
              context, "离校日期：", doc['lxDate'] ?? "" as dynamic,
              requiredValue: doc['leave'] != 'ZX',
              lastDate: DateTime.now(), cb: (DateTime res) {
            setState(() {
              doc['lxDate'] = res;
            });
          })),
      Visibility(
        visible: doc['leave'] != 'ZX' && ObjectUtil.isNotEmpty(doc['recordId']),
        child: IFormItem.selectType(
            context,
            '是否返校:',
            doc['isBack'] ?? "" as dynamic,
            [
              {'description': "是", 'value': "Y"},
              {'description': "否", 'value': "N"}
            ],
            requiredValue: true, cb: (Map res) {
          setState(() {
            doc['isBack'] =
                ObjectUtil.isNotEmpty(res) ? res['value'] : doc['isBack'];
          });
        }),
      ),
      Visibility(
          visible: doc['leave'] != 'ZX' &&
              ObjectUtil.isNotEmpty(doc['recordId']) &&
              doc['isBack'] == 'Y',
          child: IFormItem.selectDate(
              context, "返校校日期：", doc['backDate'] ?? "" as dynamic,
              requiredValue: doc['leave'] != 'ZX' &&
                  ObjectUtil.isNotEmpty(doc['recordId']),
              lastDate: DateTime.now(), cb: (DateTime res) {
            setState(() {
              doc['backDate'] = res;
            });
          }))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: const Text("晨午检及缺勤登记"), centerTitle: true, actions: [
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 64.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigoAccent,
                      ),
                      child: const Text("保存", style: TextStyle(fontSize: 12.0)),
                      onPressed: () {
                        _onSubmit(context);
                      })))
        ]),
        body: Column(children: <Widget>[
          Expanded(
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildPage(context)))
        ]));
  }
}
