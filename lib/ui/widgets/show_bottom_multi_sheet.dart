import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/res/styles.dart';

class ShowBottomMultiSheet extends StatefulWidget {
  //final Widget hintText;
  final List dataList; //填充数据
  final String title;
  final List<String> selected;
  ShowBottomMultiSheet(this.title,
      {Key? key,
      required this.dataList,
      //required this.hintText,
      required this.selected});

  @override
  _ShowBottomMultiSheet createState() => _ShowBottomMultiSheet(title,
      dataList: dataList, // hintText: hintText,
      selected: selected);
}

class _ShowBottomMultiSheet extends State<ShowBottomMultiSheet> {
  // final Widget hintText;
  final List dataList; //填充数据
  final String title;
  List<String> selected;
  bool checkedMutex = false;

  _ShowBottomMultiSheet(this.title,
      {required this.dataList,
      //required this.hintText,
      required this.selected});

  @override
  void initState() {
    super.initState();

    this.dataList.forEach((var data) {
      if (selected.indexOf(data['value']) > -1) {
        data['checked'] = true;
        if (ObjectUtil.isNotEmpty(data['isMutex']) && data['isMutex'])
          checkedMutex = true;
      } else
        data['checked'] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("请选择"), centerTitle: true, actions: [
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
                        if (this.selected.length == 0) {
                          Notify.error("请选择", context: context);
                        } else
                          Navigator.of(context).pop({
                            'value': this.selected,
                            'jsonStr': json.encode(this.selected),
                            'strValue': this.selected.join(',')
                          });
                      })))
        ]),
        body: Container(
            child: ListView(
                children: dataList.map((var data) {
          data["checked"] = data["checked"] ?? false;
          return Container(
              decoration: Decorations.bottom2,
              padding: EdgeInsets.only(left: 24, right: 24),
              child: CheckboxListTile(
                onChanged: (bool? value) {
                  if (ObjectUtil.isNotEmpty(data['isMutex']) &&
                      data['isMutex'] &&
                      value == true) {
                    //选择了互斥项
                    selected = [data['description']];
                    checkedMutex = true;
                    for (var i = 0; i < dataList.length; i++) {
                      if (ObjectUtil.isEmpty(dataList[i]['isMutex']) ||
                          !dataList[i]['isMutex'])
                        dataList[i]['checked'] = false;
                    }
                  } else {
                    if (checkedMutex == true) {
                      selected = [data['description']];
                      for (var i = 0; i < dataList.length; i++) {
                        if (ObjectUtil.isNotEmpty(dataList[i]['isMutex']) &&
                            dataList[i]['isMutex'])
                          dataList[i]['checked'] = false;
                      }
                      checkedMutex = false;
                    }
                  }
                  setState(() {
                    data["checked"] = !data["checked"];

                    if (data["checked"] &&
                        !selected.contains(data["description"])) {
                      selected.add(data["description"]);
                    } else if (!data["checked"] &&
                        selected.contains(data["description"])) {
                      selected.remove(data["description"]);
                    }
                    print(selected);
                  });
                },
                title: Text(
                    (data["description"] ?? data["text"]) ?? data["label"]),
                value: data["checked"],
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.blue,
              ));
        }).toList())));
  }
}
