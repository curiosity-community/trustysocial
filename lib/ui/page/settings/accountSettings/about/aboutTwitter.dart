import 'package:flutter/material.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/ui/page/settings/widgets/headerWidget.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/ui/page/helpcenter/helpCenterPage.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(
          'About Trusty',
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const HeaderWidget(
            'Help',
            secondHeader: true,
          ),
          SettingRowWidget(
            "Help Center",
            vPadding: 0,
            showDivider: false,
            navigateTo: 'HelpCenterPage',
          ),
          const HeaderWidget('Legal'),
          const SettingRowWidget(
            "Terms of Service",
            showDivider: true,
          ),
          const SettingRowWidget(
            "Privacy policy",
            showDivider: true,
          ),
          const SettingRowWidget(
            "Cookie use",
            showDivider: true,
          ),
          SettingRowWidget(
            "Legal notices",
            showDivider: true,
            onPressed: () async {
              showLicensePage(
                context: context,
                applicationName: 'Trusty',
                applicationVersion: '1.1.0',
                useRootNavigator: true,
              );
            },
          ),
          const HeaderWidget('Curiosity Technology'),
          SettingRowWidget("ZekAI", showDivider: true, onPressed: () {
            Utility.launchURL(
                "https://apps.apple.com/tr/app/zekai/id6449234898");
          }),
          SettingRowWidget("SezAI", showDivider: true, onPressed: () {
            Utility.launchURL("https://sezai.co");
          }),
          SettingRowWidget("Gloria", showDivider: true, onPressed: () {
            Utility.launchURL(
                "https://apps.apple.com/us/app/gloria-skincare-expert/id6477208926");
          }),
          SettingRowWidget("Curiosity", showDivider: true, onPressed: () {
            Utility.launchURL("https://curiosity.tech");
          }),
        ],
      ),
    );
  }
}
