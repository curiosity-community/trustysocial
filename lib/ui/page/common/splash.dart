import 'dart:convert';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/Auth/selectAuthMethod.dart';
import 'package:Trusty/ui/page/common/updateApp.dart';
import 'package:Trusty/ui/page/homePage.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      timer();
    });
    super.initState();
  }

  /// Check if current app is updated app or not
  /// If app is not updated then redirect user to update app screen
  void timer() async {
    final isAppUpdated = await _checkAppVersion();
    if (isAppUpdated) {
      cprint("App is updated");
      Future.delayed(const Duration(seconds: 1)).then((_) {
        var state = Provider.of<AuthState>(context, listen: false);
        state.getCurrentUser();
      });
    }
  }

  /// Return installed app version
  /// For testing purpose in debug mode update screen will not be open up
  /// If an old version of app is installed on user's device then
  /// User will not be able to see home screen
  /// User will redirected to update app screen.
  /// Once user update app with latest version and back to app then user automatically redirected to welcome / Home page
  Future<bool> _checkAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion = packageInfo.version;
    final buildNo = packageInfo.buildNumber;
    final config = await _getAppVersionFromFirebaseConfig();

    // OLD VERSION CHECK
    // if (config != null &&
    //     config['name'] == currentAppVersion &&
    //     config['versions'].contains(int.tryParse(buildNo))) {
    //   return true;
    // } else {
    //   if (kDebugMode) {
    //     cprint("Latest version of app is not installed on your system");
    //     cprint(
    //         "This is for testing purpose only. In debug mode update screen will not be open up");
    //     cprint(
    //         "If you are planning to publish app on store then please update app version in firebase config");
    //     return true;
    //   }
    //   Navigator.pushReplacement(context, UpdateApp.getRoute());
    //   return false;
    // }

    if (config != null) {
      final firebaseVersion = config['name'].toString();
      final currentVersionParts = currentAppVersion.split('.');
      final firebaseVersionParts = firebaseVersion.split('.');

      // Compare version numbers
      for (var i = 0; i < currentVersionParts.length; i++) {
        final current = int.parse(currentVersionParts[i]);
        final firebase = int.parse(firebaseVersionParts[i]);
        if (current > firebase) return true;
        if (current < firebase) {
          if (kDebugMode) return true;
          Navigator.pushReplacement(context, UpdateApp.getRoute());
          return false;
        }
      }

      // If versions are equal, compare build numbers
      if (currentAppVersion == firebaseVersion) {
        final currentBuildNo = int.tryParse(buildNo) ?? 0;
        final firebaseBuildNos = List<int>.from(config['versions']);
        final maxFirebaseBuild =
            firebaseBuildNos.reduce((max, no) => no > max ? no : max);
        if (currentBuildNo >= maxFirebaseBuild) return true;
      }
    }

    if (kDebugMode) {
      cprint("Latest version of app is not installed on your system");
      cprint(
          "This is for testing purpose only. In debug mode update screen will not be open up");
      cprint(
          "If you are planning to publish app on store then please update app version in firebase config");
      return true;
    }
    Navigator.pushReplacement(context, UpdateApp.getRoute());
    return false;
  }

  /// Returns app version from firebase config
  /// Fetch Latest app version from firebase Remote config
  /// To check current installed app version check [version] in pubspec.yaml
  /// you have to add latest app version in firebase remote config
  /// To fetch this key go to project setting in firebase
  /// Open `Remote Config` section in Firebase
  /// Add [supportedBuild]  as parameter key and below json in Default value
  ///  ```
  ///  {
  ///    "supportedBuild":
  ///    {
  ///       "name": "<Current Build Version>","
  ///       "versions": [ <Current Build Version> ]
  ///     }
  ///  } ```
  /// After adding app version key click on Publish Change button
  /// For package detail check:-  https://pub.dev/packages/firebase_remote_config#-readme-tab-
  Future<Map?> _getAppVersionFromFirebaseConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    // await remoteConfig.activateFetched();
    var data = remoteConfig.getString('supportedBuild');
    if (data.isNotEmpty) {
      return jsonDecode(data) as Map;
    } else {
      cprint(
          "Please add your app's current version into Remote config in firebase",
          errorIn: "_getAppVersionFromFirebaseConfig");
      return null;
    }
  }

  Widget _body() {
    var height = 150.0;
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Container(
        height: height,
        width: height,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(50),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Lottie.asset(
                'assets/animations/loading.json', // Path to your Lottie animation file
                height: 300, // Adjust height as needed
                width: 300, // Adjust width as needed
              ),
              Image.asset(
                'assets/images/trusty-icon.png',
                height: 30,
                width: 30,
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AuthState>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: state.authStatus == AuthStatus.NOT_DETERMINED
          ? _body()
          : state.authStatus == AuthStatus.NOT_LOGGED_IN
              ? const WelcomePage()
              : const HomePage(),
    );
  }
}
