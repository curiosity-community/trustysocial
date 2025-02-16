import 'package:flutter/material.dart';
import 'package:Trusty/helper/constant.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/bookmark/bookmarkPage.dart';
import 'package:Trusty/ui/page/profile/follow/followerListPage.dart';
import 'package:Trusty/ui/page/profile/follow/followingListPage.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/ui/page/profile/qrCode/scanner.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/ui/page/feed/suggestedUsers.dart';
import 'package:Trusty/state/appState.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:flutter/services.dart';
import 'package:Trusty/ui/page/common/referral_codes_dialog.dart';
import 'package:Trusty/ui/page/professional/professionalPage.dart';

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _SidebarMenuState createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  Widget _menuHeader() {
    final state = context.watch<AuthState>();
    if (state.userModel == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, minHeight: 100),
        child: Center(
          child: Text(
            'Login to continue',
            style: TextStyles.onPrimaryTitleText,
          ),
        ),
      ).ripple(() {
        _logOut();
      });
    } else {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              margin: const EdgeInsets.only(left: 17, top: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: customAdvanceNetworkImage(
                    state.userModel!.profilePic ?? Constants.dummyProfilePic,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(context,
                    ProfilePage.getRoute(profileId: state.userModel!.userId!));
              },
              title: Row(
                children: <Widget>[
                  UrlText(
                    text: state.userModel!.displayName ?? "",
                    style: TextStyles.onPrimaryTitleText.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 20),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  state.userModel!.isVerified ?? false
                      ? customIcon(context,
                          icon: AppIcon.blueTick,
                          isTwitterIcon: true,
                          iconColor: AppColor.primary,
                          size: 18,
                          paddingIcon: 3)
                      : const SizedBox(
                          width: 0,
                        ),
                  state.userModel!.isOrganizer ?? false
                      ? customIcon(context,
                          icon: AppIcon.organizer,
                          isTwitterIcon: true,
                          iconColor: AppColor.primary,
                          size: 18,
                          paddingIcon: 3)
                      : const SizedBox(
                          width: 0,
                        ),
                  state.userModel!.isProfessional ?? false
                      ? customIcon(context,
                          icon: AppIcon.world,
                          isTwitterIcon: true,
                          iconColor: AppColor.primary,
                          size: 18,
                          paddingIcon: 3)
                      : const SizedBox(
                          width: 0,
                        ),
                ],
              ),
              subtitle: customText(
                state.userModel!.userName,
                style: TextStyles.onPrimarySubTitleText.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    fontSize: 15),
              ),
              trailing: customIcon(context,
                  icon: AppIcon.profile,
                  iconColor: AppColor.primary,
                  paddingIcon: 20),
            ),
            Container(
              alignment: Alignment.center,
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 17,
                  ),
                  _textButton(context, state.userModel!.getFollower,
                      ' Followers', 'FollowerListPage'),
                  const SizedBox(width: 10),
                  _textButton(context, state.userModel!.getFollowing,
                      ' Following', 'FollowingListPage'),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _textButton(
      BuildContext context, String count, String text, String navigateTo) {
    return InkWell(
      onTap: () {
        var authState = context.read<AuthState>();
        late List<String> usersList;
        authState.getProfileUser();
        Navigator.pop(context);
        switch (navigateTo) {
          case "FollowerListPage":
            usersList = authState.userModel!.followersList!;
            Navigator.push(
              context,
              FollowerListPage.getRoute(
                profile: authState.userModel!,
                userList: usersList,
              ),
            );
            break;
          case "FollowingListPage":
            if (authState.userModel!.followingList == null ||
                authState.userModel!.followingList!.isEmpty) {
              // Navigate to the suggestion page if the following list is empty
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SuggestedUsers()),
              );
            } else {
              usersList = authState.userModel!.followingList!;
              Navigator.push(
                context,
                FollowingListPage.getRoute(
                  profile: authState.userModel!,
                  userList: usersList,
                ),
              );
            }
            break;
        }
      },
      child: Row(
        children: <Widget>[
          customText(
            '$count ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          customText(
            text,
            style: const TextStyle(color: AppColor.darkGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  ListTile _menuListRowButton(String title,
      {Function? onPressed, IconData? icon, bool isEnable = false}) {
    return ListTile(
      onTap: () {
        if (onPressed != null) {
          onPressed();
        }
      },
      leading: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 5),
              child: customIcon(
                context,
                icon: icon,
                size: 25,
                iconColor: isEnable
                    ? Theme.of(context).textTheme.bodyMedium!.color
                    : AppColor.darkGrey,
              ),
            ),
      title: customText(
        title,
        style: TextStyle(
          fontSize: 20,
          color: isEnable
              ? Theme.of(context).textTheme.bodyMedium!.color
              : AppColor.darkGrey,
        ),
      ),
    );
  }

  Positioned _footer() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Consumer<AuthState>(
        builder: (context, authState, child) => Column(
          children: <Widget>[
            const Divider(),
            Row(
              children: <Widget>[
                const SizedBox(width: 15, height: 45),
                customIcon(
                  context,
                  icon: context.watch<AppState>().isDark
                      ? AppIcon.bulbOff
                      : AppIcon.bulbOn,
                  isTwitterIcon: true,
                  size: 25,
                  iconColor: TwitterColor.dodgeBlue,
                ).ripple(() {
                  context.read<AppState>().toggleTheme();
                }),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _onReferralCodesPressed(context);
                  },
                  child: Text(
                    '${authState.referralCodes.length} invitation',
                    style: TextStyle(
                      fontSize: 14,
                      color: TwitterColor.dodgeBlue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      ScanScreen.getRoute(
                          context.read<AuthState>().profileUserModel!),
                    );
                  },
                  child: Image.asset(
                    "assets/images/qr.png",
                    height: 25,
                  ),
                ),
                const SizedBox(width: 0, height: 45),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _logOut() {
    final state = Provider.of<AuthState>(context, listen: false);
    Navigator.pop(context);
    state.logoutCallback();
  }

  void _navigateTo(String path) {
    Navigator.pop(context);
    Navigator.of(context).pushNamed('/$path');
  }

  void _onReferralCodesPressed(BuildContext context) {
    showReferralCodesDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  Container(
                    child: _menuHeader(),
                  ),
                  const Divider(),
                  _menuListRowButton('Profile',
                      icon: AppIcon.profile, isEnable: true, onPressed: () {
                    var state = context.read<AuthState>();
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: state.userId));
                  }),
                  _menuListRowButton(
                    'Bookmarks',
                    icon: AppIcon.bookmark,
                    isEnable: true,
                    onPressed: () {
                      Navigator.push(context, BookmarkPage.getRoute());
                    },
                  ),
                  _menuListRowButton('Events',
                      icon: AppIcon.calender, isEnable: true, onPressed: () {
                    _navigateTo('EventsPage');
                  }),
                  _menuListRowButton('Professionals',
                      icon: AppIcon.professional,
                      isEnable: true, onPressed: () {
                    _navigateTo('ProfessionalPage');
                  }),
                  _menuListRowButton('Checklists',
                      icon: Icons.add_home_work_outlined),
                  //_menuListRowButton('Lists', icon: AppIcon.lists),
                  //_menuListRowButton('Moments', icon: AppIcon.moments),
                  //_menuListRowButton('Invitation', icon: AppIcon.locationPin),
                  const Divider(),
                  _menuListRowButton('Settings and privacy', isEnable: true,
                      onPressed: () {
                    _navigateTo('SettingsAndPrivacyPage');
                  }),
                  _menuListRowButton('Premium Support', isEnable: true,
                      onPressed: () {
                    _navigateTo('HelpCenterPage');
                  }),
                  const Divider(),
                  _menuListRowButton('Logout',
                      icon: null, onPressed: _logOut, isEnable: true),
                ],
              ),
            ),
            _footer()
          ],
        ),
      ),
    );
  }
}
