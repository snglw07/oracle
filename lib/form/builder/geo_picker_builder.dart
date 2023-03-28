import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wbyq/ui/widgets/widgets.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../../form_builder_validators/form_builder_validators.dart';
import '../index.dart';

class WbGeoPickerBuilder implements WbItemBuilder {
  @override
  Widget build(BuildContext context, WbFormCfg formCfg, WbItemCfg itemCfg,
      {GlobalKey<FormBuilderState>? fbKey,
      Object? fbValue,
      Function(String key, Object? value)? updateFunc}) {
    List<FormFieldValidator> validators = [];
    if (!itemCfg.allowBlank) {
      var errorText = "${itemCfg.title}不能为空";
      validators.add(FormBuilderValidators.required(errorText: errorText));
    }

    return FutureBuilder(
      future: WbFormApi.geoGeoMain(),
      builder:
          (BuildContext ctx, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        print(snapshot.data);
        if (!snapshot.hasData) return const ProgressView();

        List<Map> geoData = List<Map>.from(snapshot.data!['data'] as dynamic);
        var geoMain = [];
        for (Map map in geoData) {
          geoMain.add({'id': map['geoId'], 'lable': map['geoName']});
        }

        return Container();
        /*return FormBuilderCustomField(
            attribute: itemCfg.id,
            validators: validators,
            formField: FormField(
                // key: _fieldKey,
                enabled: true,
                builder: (FormFieldState<dynamic> field) {
                  String value = getLoactionCode(field.value);
                  if (value.startsWith(FormConstant.mainGeoId)) {
                    hintText = FormConstant.mainGeoName;
                  } else
                    hintText = FormConstant.otherGeoName;

                  return InputDecorator(
                      decoration: InputDecoration(
                          labelText: '${itemCfg.title}${itemCfg.labelRequired}',
                          hintText: itemCfg.hintText,
                          hintStyle:
                              TextStyle(fontSize: 14, color: Colors.grey),
                          contentPadding:
                              EdgeInsets.only(top: 10.0, bottom: 0.0),
                          //border: InputBorder.none,
                          errorText: field.errorText),
                      child: DropdownButton(
                          isExpanded: true,
                          items: geoMain.map((option) {
                            return DropdownMenuItem(
                                child: Text("${option['lable']}"),
                                value: option['id']);
                          }).toList(),
                          hint: Text(hintText ?? ''),
                          onChanged: (value) async {
                            if (value == FormConstant.mainGeoId) {
                              // 缓存读取
                              Map<String, dynamic> map =
                                  await WbFormApi.geoEnum(isForce: false);

                              Map<String, Objdynamicect> citiesData =
                                  Map<String, dynamic>.from(map['valiages']);
                              Map<String, String> provincesData =
                                  Map<String, String>.from(map['towns']);
                              String locationCode =
                                  getLoactionCode(field.value);
                              CityPickers.showCityPicker(
                                      context: field.context,
                                      citiesData: citiesData,
                                      provincesData: provincesData,
                                      locationCode: locationCode,
                                      height: 400)
                                  .then((result) {
                                // 本来有值但是取消点击关闭 不能设置为空 只能保持之前的选择
                                if (ObjectUtil.isNotEmpty(field.value) &&
                                    ObjectUtil.isEmpty(result)) return;
                                // 获取地址名称拼装 idList
                                String address = addressBuild(result);
                                List<String> addressIds =
                                    addressIdBuild(result);
                                addressIds.insert(0, FormConstant.mainGeoId);
                                //是否存在关联input 输入框 存在则更新 关联项目内容
                                if (FormUtils.canUpdateTextRef(
                                    itemCfg, fbKey)) {
                                  GlobalKey<FormFieldState> refItem = fbKey
                                      .currentState.fields[itemCfg.textRef] as GlobalKey<FormFieldState>;
                                  refItem.currentState.didChange(address);
                                  updateFunc(itemCfg.id, addressIds);
                                }
                                field.didChange(addressIds);
                              });
                            } else {
                              List<String> addressIds = List();
                              for (int i = 1; i <= 4; i++) {
                                addressIds.add(value);
                              }
                              field.didChange(addressIds);
                              GlobalKey<FormFieldState> refItem =
                                  fbKey.currentState.fields[itemCfg.textRef] as GlobalKey<FormFieldState>;
                              refItem.currentState
                                  .didChange(FormConstant.otherGeoName);
                              updateFunc(itemCfg.id, addressIds);
                            }
                          }));
                }));*/
      },
    );
  }
}

// String addressBuild(Result result) {
//   String address = "";
//   if (ObjectUtil.isEmpty(result)) return address;
//   if (ObjectUtil.isNotEmpty(result.provinceName))
//     address += result.provinceName;
//   if (ObjectUtil.isNotEmpty(result.cityName)) address += result.cityName;
//   if (ObjectUtil.isNotEmpty(result.areaName)) address += result.areaName;
//   return address;
// }

// List<String> addressIdBuild(Result result) {
//   List<String> addressIds = <String>[];
//   if (ObjectUtil.isEmpty(result)) return addressIds;
//   if (ObjectUtil.isNotEmpty(result.provinceName))
//     addressIds.add(result.provinceId);
//   if (ObjectUtil.isNotEmpty(result.cityId)) addressIds.add(result.cityId);
//   if (ObjectUtil.isNotEmpty(result.areaId)) addressIds.add(result.areaId);
//   return addressIds;
// }

String getLoactionCode(dynamic value) {
  String loactionCode = FormConstant.defaultGeoId;
  if (ObjectUtil.isEmpty(value)) return loactionCode;
  if (value is String) loactionCode = value;
  if (value is List) loactionCode = value.last;
  return loactionCode;
}
