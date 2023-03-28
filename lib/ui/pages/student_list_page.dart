import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:wbyq/models/student_info_model.dart';
import 'package:wbyq/ui/pages/student_normal_page.dart';
import 'package:wbyq/ui/pages/student_upload_page.dart';

import '../../a_z_list_view/az_common.dart';
import '../../a_z_list_view/az_listview.dart';

class StudentListPage extends StatefulWidget {
  final String title;
  final Map<String, String>? data;
  const StudentListPage(this.title, {super.key, this.data});

  @override
  _StudentListPage createState() => _StudentListPage(title, data: data);
}

class _StudentListPage extends State<StudentListPage> {
  final String title;
  final Map<String, String>? data;

  String _param = "";

  _StudentListPage(this.title, {this.data});

  List classList = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = SpUtil.getString(
      "_ACCESS_TOKEN",
    );
    return Scaffold(
      appBar: AppBar(title: Text(this.title), centerTitle: true, actions: [
        Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
                width: 120.0,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigoAccent,
                    ),
                    child: Text("无请假无异常", style: TextStyle(fontSize: 12.0)),
                    onPressed: ObjectUtil.isEmpty(data)
                        ? null
                        : () {
                            NavigatorUtil.pushPage(
                                context,
                                StudentNormalPage(
                                    data!['companyId'] ?? "",
                                    data!['gradeId'] ?? "",
                                    data!['classId'] ?? ""),
                                pageName: "无请假无异常");
                          })))
      ]),
      body: FutureBuilder(
          future: WbNetApi.getStudentList((data ?? <String, String>{})
              .map<String, dynamic>((key, value) =>
                  MapEntry<String, dynamic>(key.toString(), value))),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, dynamic>?> snapshot) {
            if (snapshot.data == null) return const ProgressView();

            List<dynamic> studentList = [];
            List<dynamic> list = snapshot.data!["exec"] as dynamic;
            if (ObjectUtil.isNotEmpty(list)) {
              /* return Container(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: Text('未找到学生信息，请联系管理员维护管理班级', textAlign:  TextAlign.center,),
            ); */
              for (var item in list) {
                String studentName = item["name"];
                String shortPinyin =
                    PinyinHelper.getShortPinyin(studentName).toUpperCase();
                if (ObjectUtil.isNotEmpty(_param)) {
                  if (studentName.startsWith(_param) ||
                      shortPinyin.startsWith(_param.toUpperCase())) {
                    studentList.add(item);
                  }
                } else {
                  studentList.add(item);
                }
              }
            }

            return Container(
              child: Column(
                children: <Widget>[
                  Container(
                    height: 44,
                    padding: EdgeInsets.only(left: 12, right: 12),
                    child: Text(
                      '蓝色表示在校异常，红色表示未完成今日离校追踪，绿色表示已完成今日离校追踪',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                  Container(
                    height: 80.0,
                    child: renderHeader(),
                  ),
                  Expanded(
                      child: ObjectUtil.isEmpty(list)
                          ? Center(
                              child: Text("暂无人员"),
                            )
                          : _buildAzList(studentList, accessToken ?? ""))
                ],
              ),
            );
          }),
    );
  }

  Widget renderHeader() {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                    hintText: '请输入学生姓名',
                    contentPadding: EdgeInsets.all(12.0),
                    prefixIcon: Icon(Icons.search)),
                textInputAction: TextInputAction.search,
                onChanged: (val) => _inputChange(val),
              ),
            ),
          ],
        ));
  }

  _inputChange(String val) {
    setState(() {
      _param = val;
    });
  }

  Widget _buildAzList(List<dynamic> list, String accessToken) {
    List<StudentInfoModel> data = [];
    list.forEach((var item) {
      StudentInfoModel model = StudentInfoModel.fromJson(item);
      data.add(model);
    });

    _handleList(data);

    return Container(
        child: AzListView(
      data: data,
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildListItem(data[index], accessToken);
      },
      susItemBuilder: (BuildContext context, int index) {
        String suspensionTag = data[index].getSuspensionTag();
        return _buildSusWidget(suspensionTag);
      },
      susItemHeight: 80,
    ));
  }

  void _handleList(List<StudentInfoModel> list) {
    if (list == null || list.isEmpty) return;

    for (int i = 0, length = list.length; i < length; i++) {
      String pinyin = PinyinHelper.getPinyinE(list[i].name ?? "");
      String tag = pinyin.substring(0, 1).toUpperCase();
      list[i].pinyin = pinyin;
      if (RegExp("[A-Z]").hasMatch(tag)) {
        list[i].tagIndex = tag;
      } else {
        list[i].tagIndex = "#";
      }
    }
    SuspensionUtil.sortListBySuspensionTag(list);
  }

  Widget _buildListItem(StudentInfoModel model, accessToken) {
    return Column(
      children: <Widget>[
        Offstage(
          offstage: !(model.isShowSuspension == true),
          child: _buildSusWidget(model.getSuspensionTag()),
        ),
        Container(
            padding: EdgeInsets.only(left: 8.0),
            height: 70.0,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ListTile(
                    title: Text(
                      model.name ?? "未知",
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      model.statusName ?? "",
                      style: TextStyle(
                          color: textColor(model.detailId ?? "",
                              model.statusCode ?? "", model.hasSymptom ?? "")),
                    ),
                    onTap: () {
                      NavigatorUtil.pushPage(context,
                          StudentUploadPage(model.studentId ?? "", model),
                          pageName: "晨午检登记");
                    },
                  ),
                )
              ],
            ))
      ],
    );
  }

  Color textColor(String detailId, String statusCode, String hasSymptom) {
    Color color = Colors.grey;
    if (statusCode != 'ZX' && detailId != null && detailId != '')
      color = Colors.green;
    else if (statusCode != 'ZX')
      color = Colors.red;
    else if (hasSymptom == 'Y') color = Colors.blue;

    return color;
  }

  ///构建悬停Widget.
  Widget _buildSusWidget(String susTag) {
    return ObjectUtil.isEmpty(susTag)
        ? Container()
        : Container(
            height: 40.0,
            padding: const EdgeInsets.only(left: 15.0),
            color: Color(0xfff3f4f5),
            alignment: Alignment.centerLeft,
            child: Text(
              '$susTag',
              softWrap: false,
              style: TextStyle(
                fontSize: 14.0,
                color: Color(0xff999999),
              ),
            ),
          );
  }
}
