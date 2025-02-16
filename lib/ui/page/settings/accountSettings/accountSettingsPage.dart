import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/settings/widgets/headerWidget.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsAppbar.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:provider/provider.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<AuthState>(context).userModel ?? UserModel();
    return Scaffold(
      //backgroundColor: TwitterColor.white,
      appBar: SettingsAppBar(
        title: 'Account',
        subtitle: user.userName,
      ),
      body: ListView(
        children: <Widget>[
          const HeaderWidget('Login and security'),
          SettingRowWidget(
            "Username",
            subtitle: user.userName,
            navigateTo: "ChangeUsername",
          ),
          //const Divider(),
          // SettingRowWidget(
          //   "Phone",
          //   subtitle: user.contact,
          // ),
          SettingRowWidget(
            "Email address",
            subtitle: user.email,
            navigateTo: 'VerifyEmailPage',
          ),
          const SettingRowWidget(
            "Reset Password",
            navigateTo: 'ResetPassword',
          ),
          const SettingRowWidget("Security"),
          const HeaderWidget(
            'Data and Permission',
            secondHeader: true,
          ),
          //const SettingRowWidget("Country"),
          const SettingRowWidget("Your Trusty data",
              subtitle: "Request your data using premium support.",
              navigateTo: 'HelpCenterPage'),
          //const SettingRowWidget("Apps and sessions"),
          SettingRowWidget(
            "Delete Account",
            textColor: TwitterColor.ceriseRed,
            onPressed: () {
              Utility.showDeleteAccountDialog(context);
            },
          ),
          SettingRowWidget(
            "Log out",
            textColor: TwitterColor.ceriseRed,
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
              final state = Provider.of<AuthState>(context);
              state.logoutCallback();
            },
          ),
        ],
      ),
    );
  }
}
