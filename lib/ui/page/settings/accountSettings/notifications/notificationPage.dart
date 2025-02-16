import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/settings/widgets/headerWidget.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsAppbar.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<AuthState>(context).userModel ?? UserModel();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SettingsAppBar(
        title: 'Notifications',
        subtitle: user.userName,
      ),
      body: ListView(
        children: const <Widget>[
          HeaderWidget('Filters'),
          SettingRowWidget(
            "Quality filter",
            showCheckBox: true,
            subtitle:
                'Filter lower-quality from your notifications. This won\'t filter out notifications from people you follow or account you\'ve inteacted with recently.',
          ),
          //Divider(height: 0),
          SettingRowWidget("Advanced filter"),
          SettingRowWidget("Muted word"),
          HeaderWidget(
            'Preferences',
            secondHeader: true,
          ),
          SettingRowWidget(
            "Unread notification count badge",
            showCheckBox: false,
            subtitle:
                'Display a badge with the number of notifications waiting for you inside the Trusty app.',
          ),
          SettingRowWidget("Push notifications"),
          SettingRowWidget("SMS notifications"),
          SettingRowWidget(
            "Email notifications",
            subtitle: 'Control when how often Trusty sends emails to you.',
          ),
        ],
      ),
    );
  }
}
