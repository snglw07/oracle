import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/ui/pages/student_list_page.dart';

class StudentClassPage extends StatefulWidget {
  final List classList;

  StudentClassPage(this.classList);
  @override
  _StudentClassPage createState() => _StudentClassPage(classList);
}

class _StudentClassPage extends State<StudentClassPage> {
  final List? classList;
  String? checkClass;

  _StudentClassPage(this.classList);
  @override
  Widget build(BuildContext context) {
    var classList1 = classList ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("选择班级"),
        centerTitle: true,
      ),
      body: ListView(
          children: classList1.map((item) {
        return InkWell(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: Decorations.bottom2,
              child: Text(
                item['description'],
                style: TextStyle(fontSize: 18),
              ),
            ),
            onTap: () {
              String companyId = ObjectUtil.isEmpty(item['companyId'])
                  ? ''
                  : item['companyId'];
              String gradeId =
                  ObjectUtil.isEmpty(item['gradeId']) ? '' : item['gradeId'];
              String classId =
                  ObjectUtil.isEmpty(item['classId']) ? '' : item['classId'];
              Map<String, String> map = {
                'companyId': companyId,
                'gradeId': gradeId,
                'classId': classId
              };
              NavigatorUtil.pushPage(
                  context, StudentListPage("学生列表", data: map),
                  pageName: "学生列表");
            });
      }).toList()),
    );
  }
}
