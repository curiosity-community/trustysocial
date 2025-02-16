import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/settings/widgets/headerWidget.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsAppbar.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:provider/provider.dart';

class ContentPrefrencePage extends StatelessWidget {
  const ContentPrefrencePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<AuthState>(context).userModel ?? UserModel();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsAppBar(
        title: 'Content preferences',
        subtitle: user.userName,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: const <Widget>[
          HeaderWidget('Explore'),
          SettingRowWidget(
            "Trends",
            navigateTo: 'TrendsPage',
          ),
          //Divider(),
          SettingRowWidget(
            "Search settings",
            navigateTo: null,
          ),
          HeaderWidget(
            'Languages',
            secondHeader: true,
          ),
          SettingRowWidget(
            "Recommendations",
            vPadding: 15,
            subtitle:
                "Select which language you want recommended Tweets, people, and trends to include",
          ),
          HeaderWidget(
            'Safety',
            secondHeader: true,
          ),
          SettingRowWidget(
            "Blocked accounts",
            navigateTo: "BlockedUsersPage",
          ),
          //SettingRowWidget("Muted accounts"),
        ],
      ),
    );
  }
}
