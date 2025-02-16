import 'package:Trusty/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/common/usersListPage.dart';
import 'package:Trusty/ui/page/profile/follow/followListState.dart';
import 'package:Trusty/widgets/newWidget/customLoader.dart';
import 'package:provider/provider.dart';

class FollowerListPage extends StatelessWidget {
  const FollowerListPage({Key? key, this.userList, this.profile})
      : super(key: key);
  final List<String>? userList;
  final UserModel? profile;

  static MaterialPageRoute getRoute(
      {required List<String> userList, required UserModel profile}) {
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return ChangeNotifierProvider(
          create: (_) => FollowListState(StateType.follower),
          child: FollowerListPage(userList: userList, profile: profile),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (context.watch<FollowListState>().isbusy) {
      return SizedBox(
        height: context.height,
        child: CustomScreenLoader(
          height: double.infinity,
          width: double.infinity,
          backgroundColor:
              isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
        ),
      );
    }
    return UsersListPage(
      pageTitle: 'Followers',
      userIdsList: userList,
      emptyScreenText: '${profile?.userName} doesn\'t have any followers',
      emptyScreenSubTileText:
          'When someone follow them, they\'ll be listed here.',
      isFollowing: (user) {
        return context.watch<FollowListState>().isFollowing(user);
      },
      onFollowPressed: (user) {
        context.read<FollowListState>().followUser(user);
      },
    );
  }
}
