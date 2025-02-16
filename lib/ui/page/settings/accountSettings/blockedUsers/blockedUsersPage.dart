import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/searchState.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText('Blocked Accounts'),
      ),
      body: const BlockedUsersList(),
    );
  }
}

class BlockedUsersList extends StatelessWidget {
  const BlockedUsersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var authState = Provider.of<AuthState>(context);
    var searchState = Provider.of<SearchState>(context, listen: false);

    if (authState.userModel?.blockedList == null ||
        authState.userModel!.blockedList!.isEmpty) {
      return const Center(
        child: NotifyText(
          title: 'No Blocked Users',
          subTitle: 'When you block users, they\'ll show up here',
        ),
      );
    }

    return ListView.builder(
      itemCount: authState.userModel!.blockedList!.length,
      itemBuilder: (context, index) {
        String userId = authState.userModel!.blockedList![index];
        return FutureBuilder<UserModel?>(
          future: Future.value(searchState.getuserDetail([userId])[0]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            UserModel user = snapshot.data!;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(user.profilePic ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(user.displayName ?? ''),
              subtitle: Text('${user.userName}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TwitterColor.dodgeBlue,
                ),
                onPressed: () async {
                  await authState.unblockUser(userId);
                },
                child: const Text('Unblock',
                    style: TextStyle(color: Colors.white)),
              ),
            );
          },
        );
      },
    );
  }
}
