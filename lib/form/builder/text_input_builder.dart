import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flutter_form_builder/fields/form_builder_text_field.dart';
import '../../flutter_form_builder/form_builder.dart';
import '../../form_builder_validators/form_builder_validators.dart';
import '../index.dart';

class WbTextInputBuilder implements WbItemBuilder {
  TextEditingController? textEditingController;
  bool autoValidate = false;
  @override
  Widget build(BuildContext context, WbFormCfg formCfg, WbItemCfg itemCfg,
      {GlobalKey<FormBuilderState>? fbKey,
      Object? fbValue,
      Function(String key, Object? value)? updateFunc}) {
    // 获取当前输入框的值
    var value = fbValue ?? itemCfg.defaultValue;
    if (ObjectUtil.isNotEmpty(fbKey?.currentState?.fields[itemCfg.id])) {
      value = fbKey?.currentState?.fields[itemCfg.id]?.value;
    }
    textEditingController = TextEditingController(text: value?.toString());

    // 在值发生变化的时候的处理逻辑
    void inputValueChange(value) {
      // 身份证类型 存在映射关系字段 输入正确的身份证
      if (WbItemVType.sfz == itemCfg.vtype &&
          FormUtils.canUpdateMultipleTextRef(itemCfg, fbKey) &&
          RegexUtil.isIDCard18Exact(value)) {
        CoolKeyboard.hideKeyboard();

        Map<String, String> sfz = FormUtils.iDCard18Parse(value);

        List<String> refs = itemCfg.textRef?.split("|") ?? [];
        if (refs.contains("birthdate")) {
          GlobalKey<FormFieldState> refItem = fbKey
              ?.currentState?.fields['birthdate'] as GlobalKey<FormFieldState>;
          refItem.currentState?.didChange(
              DateTime.tryParse(sfz['birthdate']?.toString() ?? ""));
        }
        if (refs.contains("sexId")) {
          GlobalKey<FormFieldState> refItem =
              fbKey?.currentState?.fields['sexId'] as GlobalKey<FormFieldState>;
          refItem.currentState?.didChange(sfz['sex']);
        }
      }
      updateFunc!(itemCfg.id, value);
    }

    List<TextInputFormatter> inputFormatters = [];
    List<FormFieldValidator<String>> validators = [];
    // 根据配置文件匹配对应的自定义输入
    TextInputType switchKeyboardType() {
      TextInputType keyboardType;
      switch (itemCfg.vtype) {
        case WbItemVType.postal:
          {
            keyboardType = NumKeyboard.inputType;
            inputFormatters
                .add(FilteringTextInputFormatter.digitsOnly); ////只允许输入数字
            validators.add((value) {
              if (value?.length != 0 &&
                  (value?.length != 6 || int.tryParse(value![0]) == 0)) {
                return "非法的邮编";
              }
              return null;
            });
          }
          break;
        case WbItemVType.digits:
          {
            keyboardType = NumKeyboard.inputType;
            inputFormatters
                .add(FilteringTextInputFormatter.digitsOnly); ////只允许输入数字
            validators.add((value) {
              if (value?.length != 0 && int.tryParse(value ?? "") == null) {
                return "非法的数字";
              }
              return null;
            });
          }
          break;
        case WbItemVType.mphone:
          {
            keyboardType = NumKeyboard.inputType;
            validators.add((value) {
              if (value?.length != 0 && !RegexUtil.isMobileExact(value ?? "")) {
                return "非法的手机号码";
              }
              return null;
            });
          }
          break;
        case WbItemVType.email:
          {
            keyboardType = TextInputType.emailAddress;
            validators
                .add(FormBuilderValidators.email(errorText: "非法的email地址"));
          }
          break;
        case WbItemVType.number:
          {
            if ((itemCfg.decimalPrecision ?? 0) > 0)
              keyboardType = TextInputType.numberWithOptions(decimal: true);
            else
              keyboardType = TextInputType.numberWithOptions(decimal: false);
            String pointer = ".";
            inputFormatters.add(FilteringTextInputFormatter(
              RegExp("[0-9.]"),
              allow: true,
            )); ////只允许输入小数
            validators.add((value) {
              if (value == null || value.length == 0) return null;
              if (value.length != 0 && double.tryParse(value) == null) {
                return "非法的数字值";
              }

              num val = num.tryParse(value) ?? 0;
              if (val > (itemCfg.maxValue ?? 0)) {
                return "值不能大于" + itemCfg.maxValue.toString();
              } else if (val < (itemCfg.minValue ?? 0)) {
                return "值不能小于" + itemCfg.minValue.toString();
              } else if (value.contains(pointer)) {
                if (itemCfg.decimalPrecision == 0) {
                  return "请输入整数";
                } else {
                  int index = value.indexOf(pointer);
                  int lengthAfterPointer =
                      value.substring(index, value.length).length - 1;

                  if (lengthAfterPointer > (itemCfg.decimalPrecision ?? 0)) {
                    return "小数位大于精度";
                  }
                }
              }

              return null;
            });
          }
          break;
        case WbItemVType.date:
          {
            keyboardType = TextInputType.datetime;
            validators.add((value) {
              if (value?.length != 0 && !RegexUtil.isDate(value!)) {
                return "非法的日期";
              }
              return null;
            });
          }
          break;
        case WbItemVType.sfz:
          {
            keyboardType = SfzKeyboard.inputType;
            validators.add((value) {
              if (value?.length != 0 && !RegexUtil.isIDCard18(value!)) {
                return "非法身份证号";
              }
              return null;
            });
            break;
          }
        default:
          keyboardType = TextInputType.text;
          break;
      }
      return keyboardType;
    }

    if (!itemCfg.allowBlank) {
      var errorText = "${itemCfg.title}不能为空";
      validators.add(FormBuilderValidators.required(errorText: errorText));
    }

    if (itemCfg.dataMinLength > 0) {
      var minLengthHint = "至少需要输入${itemCfg.dataMinLength}个字符";

      validators.add(FormBuilderValidators.minLength(itemCfg.dataMinLength,
          errorText: minLengthHint));
    }

    if (itemCfg.dataMaxLength > 0) {
      var maxLengthHint = "至多能输入${itemCfg.dataMaxLength}个字符";

      validators.add(FormBuilderValidators.maxLength(itemCfg.dataMaxLength,
          errorText: maxLengthHint));
    }

    TextInputType keyboardType = switchKeyboardType();

    ///!! 修改FormBuilderTextField  里面的build  方法里面添加一行  _effectiveController = widget.controller;
    FormBuilderTextField formField = FormBuilderTextField(
      //attribute: itemCfg.id,
      //validators: validators,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      controller: textEditingController,
      readOnly: itemCfg.disabled,
      decoration: InputDecoration(
          labelText: '${itemCfg.title}${itemCfg.labelRequired}',
          hintText: itemCfg.hintText,
          contentPadding: EdgeInsets.only(top: 10, bottom: 10),
          hintStyle: TextStyle(
              fontSize: itemCfg.disabled ? 8 : 14, color: Colors.grey)),
      //autovalidate: false,
      autofocus: false,
      onChanged: inputValueChange, name: itemCfg.id,
    );

    if (keyboardType == SfzKeyboard.inputType ||
        keyboardType == NumKeyboard.inputType) {
      return KeyboardMediaQuery(//用于键盘弹出的时候页面可以滚动到输入框的位置
          child: Builder(builder: (ctx) {
        CoolKeyboard.init(KeyboardRootState(), ctx); //初始化键盘监听并且传递当前页面的context

        return formField;
      }));
    }
    return formField;
  }
}
