import 'package:flutter/material.dart';
//import 'package:wbyq/application.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:wbyq/ui/pages/language_page.dart';
import 'package:wbyq/ui/pages/page_index.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LogUtil.e("SettingPage build......");
    final ApplicationBloc? bloc = BlocProvider.of<ApplicationBloc>(context);
    //final MainBloc exBloc = BlocProvider.of<MainBloc>(context);
    //exBloc.queryUserLoginExInfo(isForce: true, updateExMap: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          IntlUtil.getString(context, Ids.titleSetting),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          ExpansionTile(
            title: Row(
              children: <Widget>[
                Icon(
                  Icons.color_lens,
                  color: Colours.gray_66,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Text(
                    IntlUtil.getString(context, Ids.titleTheme),
                  ),
                )
              ],
            ),
            children: <Widget>[
              Wrap(
                children: themeColorMap.keys.map((String key) {
                  Color value = themeColorMap[key]!;
                  return InkWell(
                    onTap: () {
                      SpUtil.putString(Constant.KEY_THEME_COLOR, key);
                      bloc?.sendAppEvent(Constant.TYPE_SYS_UPDATE);
                    },
                    child: Container(
                      margin: EdgeInsets.all(5.0),
                      width: 36.0,
                      height: 36.0,
                      color: value,
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          ListTile(
            title: Row(
              children: <Widget>[
                Icon(
                  Icons.language,
                  color: Colours.gray_66,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Text(
                    IntlUtil.getString(context, Ids.titleLanguage),
                  ),
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                    SpHelper.getLanguageModel() == null
                        ? IntlUtil.getString(context, Ids.languageAuto)
                        : IntlUtil.getString(
                            context, SpHelper.getLanguageModel()!.titleId,
                            languageCode: 'zh', countryCode: 'CH'),
                    style: TextStyles.listContenntHui),
                Icon(Icons.keyboard_arrow_right)
              ],
            ),
            onTap: () {
              NavigatorUtil.pushPage(context, LanguagePage(),
                  pageName: Ids.titleLanguage);
            },
          ),
        ],
      ),
    );
  }
}
