import 'package:flutter/cupertino.dart';

abstract class FormState<T extends StatefulWidget> extends State
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? doc;
  loadstate();
}
