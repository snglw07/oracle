import 'package:flutter/widgets.dart';

import '../../flutter_form_builder/form_builder.dart';
import '../index.dart';

abstract class WbItemBuilder {
  /// itemCfg 表单配置项
  /// fbKey 分页表单key
  /// updateFunc 表单更新方法（回调表单页面）
  Widget? build(BuildContext context, WbFormCfg formCfg, WbItemCfg itemCfg,
      {GlobalKey<FormBuilderState>? fbKey,
      Object? fbValue,
      Function(String key, Object? value)? updateFunc});
}
