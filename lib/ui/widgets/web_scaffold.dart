import 'package:flutter/material.dart';
import 'package:wbyq/common/component_index.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebScaffold extends StatefulWidget {
  const WebScaffold({
    Key? key,
    this.title,
    required this.titleId,
    this.url,
  }) : super(key: key);

  final String? title;
  final String titleId;
  final String? url;

  @override
  State<StatefulWidget> createState() {
    return WebScaffoldState();
  }
}

class WebScaffoldState extends State<WebScaffold> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url ?? ""));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? IntlUtil.getString(context, widget.titleId),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        /*   actions: <Widget>[
          LikeButton(
            width: 56.0,
            duration: Duration(milliseconds: 500),
          ),
          // IconButton(icon:  Icon(Icons.more_vert), onPressed: () {}),
           PopupMenuButton(
              padding: const EdgeInsets.all(0.0),
              onSelected: _onPopSelected,
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                     PopupMenuItem<String>(
                        value: "browser",
                        child: ListTile(
                            contentPadding: EdgeInsets.all(0.0),
                            dense: false,
                            title:  Container(
                              alignment: Alignment.center,
                              child:  Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.language,
                                    color: Colours.gray_66,
                                    size: 22.0,
                                  ),
                                  Gaps.hGap10,
                                  Text(
                                    '浏览器打开',
                                    style: TextStyles.listContent,
                                  )
                                ],
                              ),
                            ))),
                     PopupMenuItem<String>(
                        value: "share",
                        child: ListTile(
                            contentPadding: EdgeInsets.all(0.0),
                            dense: false,
                            title:  Container(
                              alignment: Alignment.center,
                              child:  Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.share,
                                    color: Colours.gray_66,
                                    size: 22.0,
                                  ),
                                  Gaps.hGap10,
                                  Text(
                                    '分享',
                                    style: TextStyles.listContent,
                                  )
                                ],
                              ),
                            ))),
                  ])
        ], */
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
//      floatingActionButton: _buildFloatingActionButton(),
    );
  }

//  Widget _buildFloatingActionButton() {
//    if (_webViewController == null || _webViewController.scrollY < 480) {
//      return null;
//    }
//    return  FloatingActionButton(
//        heroTag: widget.title ?? widget.titleId,
//        backgroundColor: Theme.of(context).primaryColor,
//        child: Icon(
//          Icons.keyboard_arrow_up,
//        ),
//        onPressed: () {
//          _webViewController.scrollTop();
//        });
//  }
}

class RpxWebScaffold extends StatefulWidget {
  RpxWebScaffold({Key? key, this.title, required this.titleId, this.url})
      : super(key: key);

  final String? title;
  final String titleId;
  final String? url;
  @override
  State<StatefulWidget> createState() => RpxWebScaffoldState();
}

class RpxWebScaffoldState extends State<RpxWebScaffold> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url ?? ""));
  }

  @override
  Widget build(BuildContext context) {
    //print('widget.url......................${widget.url}');

    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.title ?? IntlUtil.getString(context, widget.titleId),
                overflow: TextOverflow.ellipsis),
            centerTitle: true),
        body: Column(children: <Widget>[
          Expanded(
              child: WebViewWidget(
            controller: _webViewController,
          )),
          Wrap(spacing: 25, children: [
            BtnWithCircle('原图',
                size: 40,
                icon: Icon(Icons.hd),
                color: Colors.orange,
                onPressed: () =>
                    _webViewController.runJavaScript("rpxScale('FULLPAGE')")),
            BtnWithCircle('还原',
                size: 40,
                icon: Icon(Icons.replay),
                color: Colors.green,
                onPressed: () =>
                    _webViewController.runJavaScript("rpxScale('FULLSCREEN')")),
            BtnWithCircle('缩小',
                size: 40,
                icon: Icon(Icons.zoom_out, size: 30),
                color: Colors.blue,
                onPressed: () =>
                    _webViewController.runJavaScript("rpxScale('ZOOMIN')")),
            BtnWithCircle('放大',
                size: 40,
                icon: Icon(Icons.zoom_in, size: 30),
                color: Colors.red,
                onPressed: () =>
                    _webViewController.runJavaScript("rpxScale('ZOOMOUT')"))
          ])
        ])
        // floatingActionButton: _buildFloatingActionButton()
        );
  }

  // Widget _buildFloatingActionButton() {
  //   return SpeedDial(
  //       // both default to 16
  //       marginRight: 18,
  //       marginBottom: 20,
  //       animatedIcon: AnimatedIcons.add_event,
  //       animatedIconTheme: IconThemeData(size: 22.0),
  //       closeManually: false,
  //       curve: Curves.bounceIn,
  //       overlayColor: Colors.black,
  //       overlayOpacity: 0.5,
  //       tooltip: '控制选项',
  //       heroTag: 'speed-dial-hero-tag',
  //       backgroundColor: Colors.blue,
  //       foregroundColor: Colors.white,
  //       elevation: 8.0,
  //       children: [
  //         SpeedDialChild(
  //             child: Icon(Icons.zoom_in, size: 30),
  //             backgroundColor: Colors.red,
  //             label: '放大',
  //             labelStyle: TextStyle(fontSize: 16.0),
  //             onTap: () =>
  //                 _webViewController.evaluateJavascript("rpxScale('ZOOMOUT')")),
  //         SpeedDialChild(
  //             child: Icon(Icons.zoom_out, size: 30),
  //             backgroundColor: Colors.blue,
  //             label: '缩小',
  //             labelStyle: TextStyle(fontSize: 16.0),
  //             onTap: () =>
  //                 _webViewController.evaluateJavascript("rpxScale('ZOOMIN')")),
  //         SpeedDialChild(
  //             child: Icon(Icons.replay),
  //             backgroundColor: Colors.green,
  //             label: '还原',
  //             labelStyle: TextStyle(fontSize: 16.0),
  //             onTap: () => _webViewController
  //                 .evaluateJavascript("rpxScale('FULLSCREEN')")),
  //         SpeedDialChild(
  //             child: Icon(Icons.hd),
  //             backgroundColor: Colors.orange,
  //             label: '原图',
  //             labelStyle: TextStyle(fontSize: 16.0),
  //             onTap: () =>
  //                 _webViewController.evaluateJavascript("rpxScale('FULLPAGE')"))
  //       ]);
  // }
}
