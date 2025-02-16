import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/page/settings/widgets/headerWidget.dart';
import 'package:Trusty/ui/page/settings/widgets/settingsRowWidget.dart';
import 'package:Trusty/state/chats/chatState.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';
import 'package:Trusty/widgets/newWidget/rippleButton.dart';
import 'package:provider/provider.dart';

class ConversationInformation extends StatelessWidget {
  const ConversationInformation({Key? key}) : super(key: key);

  Widget _header(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: SizedBox(
                height: 80,
                width: 80,
                child: RippleButton(
                  onPressed: () {
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: user.userId!));
                  },
                  borderRadius: BorderRadius.circular(40),
                  child: CircularImage(path: user.profilePic, height: 80),
                )),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              UrlText(
                text: user.displayName!,
                style: TextStyles.onPrimaryTitleText.copyWith(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                width: 3,
              ),
              user.isVerified!
                  ? customIcon(
                      context,
                      icon: AppIcon.blueTick,
                      isTwitterIcon: true,
                      iconColor: AppColor.primary,
                      size: 18,
                      paddingIcon: 3,
                    )
                  : const SizedBox(width: 0),
            ],
          ),
          customText(
            user.userName,
            style: TextStyles.onPrimarySubTitleText.copyWith(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<ChatState>(context).chatUser ?? UserModel();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(
          'Conversation information',
        ),
      ),
      body: ListView(
        children: <Widget>[
          _header(context, user),
          const HeaderWidget('Notifications'),
          const SettingRowWidget(
            "Mute conversation",
            visibleSwitch: true,
          ),
          SettingRowWidget(
            "Block ${user.userName}",
            textColor: TwitterColor.dodgeBlue,
            showDivider: false,
          ),
          SettingRowWidget("Report ${user.userName}",
              textColor: TwitterColor.dodgeBlue, showDivider: false),
          SettingRowWidget(
            "Delete conversation",
            textColor: TwitterColor.ceriseRed,
            showDivider: false,
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Conversation'),
                    content: Text(
                        'Are you sure you want to delete this conversation with ${user.userName}?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                var state = Provider.of<ChatState>(context, listen: false);
                var authState = Provider.of<AuthState>(context, listen: false);
                await state.deleteConversation(authState.userId, user.userId!);

                // Navigate back to chat list page
                if (context.mounted) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  state.getUserChatList(authState.userId);
                  Navigator.of(context).pop(); // Close conversation info
                  Navigator.of(context).pop(); // Close chat screen
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
