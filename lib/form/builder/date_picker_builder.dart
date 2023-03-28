import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../flutter_form_builder/fields/form_builder_date_time_picker.dart';
import '../../flutter_form_builder/form_builder.dart';
import '../../form_builder_validators/form_builder_validators.dart';
import '../index.dart';

class WbDatePickerBuilder implements WbItemBuilder {
  @override
  Widget build(BuildContext context, WbFormCfg formCfg, WbItemCfg itemCfg,
      {GlobalKey<FormBuilderState>? fbKey,
      Object? fbValue,
      void Function(String key, Object? value)? updateFunc}) {
    TextEditingController textEditingController;
    List<FormFieldValidator> validators = [];

    if (!itemCfg.allowBlank) {
      var errorText = "${itemCfg.title}不能为空";
      validators.add(FormBuilderValidators.required(errorText: errorText));
    }
    var currentValue = fbValue;
    if (ObjectUtil.isNotEmpty(fbKey?.currentState?.fields[itemCfg.id])) {
      currentValue = fbKey?.currentState?.fields[itemCfg.id]?.value;
    }
    if (ObjectUtil.isNotEmpty(currentValue) && !(currentValue is DateTime))
      currentValue = DateTime.tryParse(currentValue?.toString() ?? "");

    if (ObjectUtil.isEmpty(currentValue) &&
        ObjectUtil.isNotEmpty(itemCfg.defaultValue))
      currentValue = itemCfg.defaultValue is String
          ? DateTime.tryParse(itemCfg.defaultValue.toString() ?? "")
          : itemCfg.defaultValue is DateTime
              ? itemCfg.defaultValue
              : DateTime.now();

    String textValue = DateUtil.formatDate(currentValue as DateTime,
        format: itemCfg.vtype == WbItemVType.date
            ? "yyyy-MM-dd"
            : "yyyy-MM-dd HH:mm:ss");
    textEditingController = TextEditingController(text: textValue);

    var formField = FormBuilderDateTimePicker(
      controller: textEditingController,
      //attribute: itemCfg.id,
      //validators: validators,
      //readOnly: true,
      initialDate:
          ObjectUtil.isNotEmpty(currentValue) ? currentValue : DateTime.now(),
      firstDate: DateTime(1910, 1),
      lastDate: DateTime(2050, 12),
      initialDatePickerMode: DatePickerMode.day,
      textCapitalization: TextCapitalization.none,
      inputType:
          (itemCfg.vtype == WbItemVType.date ? InputType.date : InputType.both),
      format: intl.DateFormat(itemCfg.vtype == WbItemVType.date
          ? "yyyy-MM-dd"
          : "yyyy-MM-dd HH:mm:ss"),
      decoration: InputDecoration(
          labelText: '${itemCfg.title}${itemCfg.labelRequired}',
          hintText: itemCfg.hintText,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey)),
      onChanged: (DateTime? value) {
        updateFunc!(itemCfg.id, value);
      },
      name: '',
    );
    return formField;
  }
}
