import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/ui/page/common/splash.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';

class UpdateApp extends StatefulWidget {
  const UpdateApp({Key? key}) : super(key: key);

  static Route<T> getRoute<T>() {
    return MaterialPageRoute(
      builder: (_) => UpdateApp(),
    );
  }

  @override
  _UpdateAppState createState() => _UpdateAppState();
}

class _UpdateAppState extends State<UpdateApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SplashPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwitterColor.mystic,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/images/icon-480.png"),
            const TitleText(
              "New Update is available",
              fontSize: 25,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const TitleText(
              "The current version of app is no longer supported. We apologized for any inconvenience we may have caused you",
              fontSize: 14,
              color: AppColor.darkGrey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 35),
              child: CustomFlatButton(
                label: "Update now",
                onPressed: () => Utility.launchURL(Platform.isIOS
                    ? "https://apps.apple.com/app/id6737801994"
                    : "https://play.google.com/store/apps/details?id=tech.curiosity.trusty"),
                borderRadius: 30,
              ),
            )
          ],
        ),
      ),
    );
  }
}
