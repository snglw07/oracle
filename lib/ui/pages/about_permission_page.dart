import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/data/api/wbnet_api.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AboutPermissionPage extends StatelessWidget {
  const AboutPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(IntlUtil.getString(context, Ids.permissionSetting)),
          centerTitle: true,
        ),
        body: FutureBuilder(
            future: WbNetApi.fetchAppdMd(),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, dynamic>?> snapshot) {
              if (!snapshot.hasData) return const ProgressView();

              var mdstr = snapshot.data!['md'] ?? '';
              if (kDebugMode) {
                print(mdstr);
              }
              return Markdown(data: mdstr.toString());
            }));
  }
}
