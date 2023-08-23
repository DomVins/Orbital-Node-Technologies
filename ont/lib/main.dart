import 'dart:async';
import 'dart:io';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color.fromARGB(255, 0, 0, 0),
    statusBarColor: Color.fromARGB(255, 0, 0, 0),
  ));
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    MaterialColor mycolor = MaterialColor(
      const Color.fromRGBO(3, 17, 141, 1).value,
      const <int, Color>{
        50: Color.fromRGBO(3, 17, 141, 0.1),
        100: Color.fromRGBO(3, 17, 141, 0.2),
        200: Color.fromRGBO(3, 17, 141, 0.3),
        300: Color.fromRGBO(3, 17, 141, 0.4),
        400: Color.fromRGBO(3, 17, 141, 0.5),
        500: Color.fromRGBO(3, 17, 141, 0.6),
        600: Color.fromRGBO(3, 17, 141, 0.7),
        700: Color.fromRGBO(3, 17, 141, 0.8),
        800: Color.fromRGBO(3, 17, 141, 0.9),
        900: Color.fromRGBO(3, 17, 141, 1),
      },
    );
    return MaterialApp(
      title: 'Orbital Node',
      theme: ThemeData(
        primarySwatch: mycolor,
      ),
      home: AnimatedSplashScreen(
        backgroundColor: Colors.white,
        splash: Image.asset("assets/logo.png"),
        nextScreen: const WebView(),
        splashIconSize: 200,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebView extends StatefulWidget {
  const WebView({Key? key}) : super(key: key);

  @override
  State<WebView> createState() => _WebViewState();
}

final ValueNotifier<int> _live = ValueNotifier<int>(0);

class _WebViewState extends State<WebView> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  var isDeviceConnected = true;

  @override
  void initState() {
    super.initState();
    checkConnection();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: ValueListenableBuilder<int>(
          valueListenable: _live,
          builder: (context, value, child) {
            return Visibility(
              visible: isDeviceConnected,
              replacement: errorPage(),
              child: Scaffold(
                  backgroundColor: const Color.fromRGBO(3, 17, 141, 1),
                  body: SafeArea(
                      child: Column(children: <Widget>[
                    Expanded(
                      child: Stack(
                        children: [
                          InAppWebView(
                            key: webViewKey,
                            initialUrlRequest: URLRequest(
                                url: Uri.parse(
                                    "https://www.orbitalnodetechnologies.com/home")),
                            onReceivedServerTrustAuthRequest:
                                (controller, challenge) async {
                              return ServerTrustAuthResponse(
                                  action:
                                      ServerTrustAuthResponseAction.PROCEED);
                            },
                            initialOptions: options,
                            pullToRefreshController: pullToRefreshController,
                            onWebViewCreated: (controller) {
                              webViewController = controller;
                            },
                            onLoadStart: (controller, url) {
                              setState(() {
                                this.url = url.toString();
                                urlController.text = this.url;
                              });
                            },
                            androidOnPermissionRequest:
                                (controller, origin, resources) async {
                              return PermissionRequestResponse(
                                  resources: resources,
                                  action:
                                      PermissionRequestResponseAction.GRANT);
                            },
                            shouldOverrideUrlLoading:
                                (controller, navigationAction) async {
                              var uri = navigationAction.request.url!;
                              if (![
                                "http",
                                "https",
                                "file",
                                "chrome",
                                "data",
                                "javascript",
                                "about"
                              ].contains(uri.scheme)) {
                                // and cancel the request
                                return NavigationActionPolicy.CANCEL;
                              }

                              return NavigationActionPolicy.ALLOW;
                            },
                            onLoadStop: (controller, url) async {
                              pullToRefreshController.endRefreshing();
                              setState(() {
                                this.url = url.toString();
                                urlController.text = this.url;
                              });
                            },
                            onLoadError:
                                (controller, url, code, message) async {
                              pullToRefreshController.endRefreshing();
                              isDeviceConnected = false;
                              _live.value += 1;
                            },
                            onProgressChanged: (controller, progress) {
                              if (progress == 100) {
                                pullToRefreshController.endRefreshing();
                              }
                              setState(() {
                                this.progress = progress / 100;
                                urlController.text = url;
                              });
                            },
                            onUpdateVisitedHistory:
                                (controller, url, androidIsReload) {
                              setState(() {
                                this.url = url.toString();
                                urlController.text = this.url;
                              });
                            },
                          ),
                          progress < 1.0
                              ? Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                    ),
                                    Expanded(
                                        child: Container(
                                      color: const Color.fromARGB(97, 0, 0, 0),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ))
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ]))),
            );
          }),
    );
  }

  checkConnection() async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (result == true) {
      isDeviceConnected = true;
      _live.value += 1;
    } else {
      isDeviceConnected = false;
      _live.value += 1;
    }
  }

  errorPage() {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Pls ensure that you have internet connection.",
              style: TextStyle(fontSize: 15),
            ),
            TextButton(
                onPressed: () {
                  checkConnection();
                },
                child: const Text(
                  "Refresh",
                  style: TextStyle(fontSize: 16),
                ))
          ],
        ),
      )),
    );
  }

  Future<bool> _onBack() async {
    bool goBack = false;
    var value = await webViewController?.canGoBack();
    if (value!) {
      webViewController?.goBack();
      return false;
    } else {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("Confirmation"),
                content: const Text("Do you want to exit the app ?"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        setState(() {
                          goBack = false;
                        });
                      },
                      child: const Text("No")),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        setState(() {
                          goBack = true;
                        });
                      },
                      child: const Text("Yes"))
                ],
              ));
      if (goBack) SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      return goBack;
    }
  }
}
