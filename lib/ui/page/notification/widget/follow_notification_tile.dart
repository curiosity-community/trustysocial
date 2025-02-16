import 'package:flutter/material.dart';
import 'package:Trusty/model/notificationModel.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';

class FollowNotificationTile extends StatelessWidget {
  final NotificationModel model;
  const FollowNotificationTile({Key? key, required this.model})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
          child: Column(
            children: [
              Row(
                children: [
                  customIcon(context,
                      icon: AppIcon.profile, isEnable: true, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    model.user.displayName!,
                    style: TextStyles.titleStyle.copyWith(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    " Followed you",
                    style: TextStyles.subtitleStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              _UserCard(user: model.user)
            ],
          ),
        ),
        const Divider(height: 0, thickness: .6)
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({Key? key, required this.user}) : super(key: key);
  String getBio(String bio) {
    if (bio == "Edit profile to update bio") {
      return "No bio available";
    } else {
      return bio.takeOnly(100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 30, top: 10, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.extraLightGrey, width: .5),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularImage(path: user.profilePic, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: UrlText(
                            text: user.displayName!,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        user.isVerified!
                            ? customIcon(context,
                                icon: AppIcon.blueTick,
                                isTwitterIcon: true,
                                iconColor: AppColor.primary,
                                size: 13,
                                paddingIcon: 3)
                            : const SizedBox(width: 0),
                      ],
                    ),
                    const SizedBox(height: 4),
                    customText(
                      '${user.userName}',
                      style: TextStyles.subtitleStyle.copyWith(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (getBio(user.bio!).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      customText(
                        getBio(user.bio!),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ).ripple(() {
          Navigator.push(
              context, ProfilePage.getRoute(profileId: user.userId!));
        }, borderRadius: BorderRadius.circular(15)));
  }
}
