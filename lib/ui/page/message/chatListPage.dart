import 'package:flutter/material.dart';
import 'package:Trusty/helper/constant.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/chatModel.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/chats/chatState.dart';
import 'package:Trusty/state/searchState.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/widgets/newWidget/rippleButton.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';

class ChatListPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatListPage({Key? key, required this.scaffoldKey}) : super(key: key);
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.setIsChatScreenOpen = true;

    // chatState.databaseInit(state.profileUserModel.userId,state.userId);
    chatState.getUserChatList(state.user!.uid);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) context.read<SearchState>().resetFilterList();
  }

  Widget _body() {
    final state = Provider.of<ChatState>(context);
    final searchState = Provider.of<SearchState>(context, listen: false);
    if (state.chatUserList == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: EmptyList(
          'No message available ',
          subTitle:
              'When someone sends you message,UserModel list\'ll show up here \n  To send message tap message button.',
        ),
      );
    } else {
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: state.chatUserList!.length,
        itemBuilder: (context, index) => Dismissible(
          key: Key(state.chatUserList![index].key ?? ''),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirm"),
                  content:
                      const Text("Are you sure you want to delete this chat?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("CANCEL"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("DELETE"),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            final chatState = Provider.of<ChatState>(context, listen: false);
            final authState = Provider.of<AuthState>(context, listen: false);
            if (state.chatUserList![index].key != null) {
              chatState.deleteConversation(
                  authState.user!.uid, state.chatUserList![index].key!);
            }
          },
          child: _userCard(
            searchState.userlist!.firstWhere(
              (x) => x.userId == state.chatUserList![index].key,
              orElse: () => UserModel(userName: "Unknown"),
            ),
            state.chatUserList![index],
          ),
        ),
        separatorBuilder: (context, index) {
          return const Divider();
        },
      );
    }
  }

  Widget _userCard(UserModel model, ChatMessage? lastMessage) {
    return Container(
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        onTap: () {
          final chatState = Provider.of<ChatState>(context, listen: false);
          final searchState = Provider.of<SearchState>(context, listen: false);
          chatState.setChatUser = model;
          if (searchState.userlist!.any((x) => x.userId == model.userId)) {
            chatState.setChatUser = searchState.userlist!
                .where((x) => x.userId == model.userId)
                .first;
          }
          Navigator.pushNamed(context, '/ChatScreenPage');
        },
        leading: RippleButton(
          onPressed: () {
            Navigator.push(
                context, ProfilePage.getRoute(profileId: model.userId!));
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(28),
              image: DecorationImage(
                  image: customAdvanceNetworkImage(
                    model.profilePic ?? Constants.dummyProfilePic,
                  ),
                  fit: BoxFit.cover),
            ),
          ),
        ),
        title: TitleText(
          model.displayName ?? "NA",
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyMedium!.color,
          fontWeight: FontWeight.w800,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: customText(
          getLastMessage(lastMessage?.message) ?? '@${model.displayName}',
          style: TextStyles.onPrimarySubTitleText
              .copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: lastMessage == null
            ? const SizedBox.shrink()
            : Text(
                Utility.getChatTime(lastMessage.createdAt).toString(),
                style: TextStyles.onPrimarySubTitleText.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  FloatingActionButton _newMessageButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/NewMessagePage');
      },
      child: customIcon(
        context,
        icon: AppIcon.newMessage,
        isTwitterIcon: false,
        //iconColor: Theme.of(context).colorScheme.onPrimary,
        size: 25,
      ),
    );
  }

  void onSettingIconPressed() {
    Navigator.pushNamed(context, '/DirectMessagesPage');
  }

  String? getLastMessage(String? message) {
    if (message != null && message.isNotEmpty) {
      if (message.length > 100) {
        message = message.substring(0, 80) + '...';
        return message;
      } else {
        return message;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        scaffoldKey: widget.scaffoldKey,
        title: customTitleText(
          'Messages',
        ),
        icon: AppIcon.settings,
        onActionPressed: onSettingIconPressed,
      ),
      floatingActionButton: _newMessageButton(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _body(),
    );
  }
}
