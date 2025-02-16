import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/share_widget.dart';
import 'package:Trusty/widgets/tweet/tweet.dart';
import 'package:provider/provider.dart';

class TweetBottomSheet {
  Widget tweetOptionIcon(BuildContext context,
      {required FeedModel model,
      required TweetType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    return Container(
      width: 25,
      height: 25,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: customIcon(context,
          icon: AppIcon.arrowDown,
          isTwitterIcon: true,
          iconColor: AppColor.lightGrey),
    ).ripple(
      () {
        _openBottomSheet(context,
            type: type, model: model, scaffoldKey: scaffoldKey);
      },
      borderRadius: BorderRadius.circular(20),
    );
  }

  void _openBottomSheet(BuildContext context,
      {required TweetType type,
      required FeedModel model,
      required GlobalKey<ScaffoldState> scaffoldKey}) async {
    var authState = Provider.of<AuthState>(context, listen: false);
    bool isMyTweet = authState.userId == model.userId;
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: context.height *
                (type == TweetType.Tweet
                    ? (isMyTweet ? .25 : .44)
                    : (isMyTweet ? .38 : .52)),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: type == TweetType.Tweet
                ? _tweetOptions(context,
                    scaffoldKey: scaffoldKey,
                    isMyTweet: isMyTweet,
                    model: model,
                    type: type)
                : _tweetDetailOptions(context,
                    scaffoldKey: scaffoldKey,
                    isMyTweet: isMyTweet,
                    model: model,
                    type: type));
      },
    );
  }

  Widget _tweetDetailOptions(BuildContext context,
      {required bool isMyTweet,
      required FeedModel model,
      required TweetType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        // _widgetBottomSheetRow(context, AppIcon.link,
        //     text: 'Copy link to Post', isEnable: true, onPressed: () async {
        //   Navigator.pop(context);
        //   var uri = await Utility.createLinkToShare(
        //     context,
        //     "tweet/${model.key}",
        //     socialMetaTagParameters: SocialMetaTagParameters(
        //         description: model.description ??
        //             "${model.user!.displayName} posted on Trusty.",
        //         title: "Post on Trusty app",
        //         imageUrl: Uri.parse(
        //             "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw")),
        //   );

        //   Utility.copyToClipBoard(
        //       context: context,
        //       text: uri.toString(),
        //       message: "Post link copy to clipboard");
        // }),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.delete,
                text: 'Delete Post',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete"),
                      content: const Text('Do you want to delete this Post?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              TwitterColor.dodgeBlue,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              TwitterColor.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteTweet(
                              context,
                              type,
                              model.key!,
                              parentkey: model.parentkey,
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                isEnable: true,
              )
            : Container(),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Pin to profile',
              )
            : _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Unfollow ${model.user!.userName}',
              ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.mute,
                text: 'Mute ${model.user!.userName}',
              ),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.edit,
                text: 'Edit Post',
                isEnable: true,
                onPressed: () => _handleEditTweet(context, model),
              )
            : Container(),
        _widgetBottomSheetRow(
          context,
          AppIcon.mute,
          text: 'Mute this conversation',
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.viewHidden,
          text: 'View hidden replies',
        ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.block,
                text: 'Block ${model.user!.userName}',
              ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.report,
                text: 'Report Post',
                isEnable: true,
                onPressed: () async {
                  var authState =
                      Provider.of<AuthState>(context, listen: false);
                  final slackWebhookUrl =
                      'https://hooks.slack.com/services/XXXX/XXXX/XXXX';

                  try {
                    await http.post(
                      Uri.parse(slackWebhookUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'text':
                            '*Post Reported*\nReported by: ${authState.userModel?.email}\nPost content: ${model.description}\nPost ID: ${model.key}'
                      }),
                    );
                    Navigator.pop(context);
                    Utility.customSnackBar(
                        context, 'Post reported successfully');
                  } catch (e) {
                    print(e);
                    Utility.customSnackBar(context, 'Failed to report post');
                  }
                },
              ),
      ],
    );
  }

  Widget _tweetOptions(BuildContext context,
      {required bool isMyTweet,
      required FeedModel model,
      required TweetType type,
      required GlobalKey<ScaffoldState> scaffoldKey}) {
    var authState = Provider.of<AuthState>(context, listen: false);
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        // _widgetBottomSheetRow(context, AppIcon.link,
        //     text: 'Copy link to tweet', isEnable: true, onPressed: () async {
        //   var uri = await Utility.createLinkToShare(
        //     context,
        //     "tweet/${model.key}",
        //     socialMetaTagParameters: SocialMetaTagParameters(
        //         description: model.description ??
        //             "${model.user!.displayName} posted a tweet on Trusty.",
        //         title: "Tweet on Trusty app",
        //         imageUrl: Uri.parse(
        //             "https://play-lh.googleusercontent.com/e66XMuvW5hZ7HnFf8R_lcA3TFgkxm0SuyaMsBs3KENijNHZlogUAjxeu9COqsejV5w=s180-rw")),
        //   );

        //   Navigator.pop(context);
        //   Utility.copyToClipBoard(
        //       context: context,
        //       text: uri.toString(),
        //       message: "Tweet link copy to clipboard");
        // }),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.delete,
                text: 'Delete Post',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete"),
                      content: const Text('Do you want to delete this Post?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              TwitterColor.dodgeBlue,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              TwitterColor.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteTweet(
                              context,
                              type,
                              model.key!,
                              parentkey: model.parentkey,
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                isEnable: true,
              )
            : Container(),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.thumbpinFill,
                text: 'Pin to profile',
              )
            : _widgetBottomSheetRow(
                context,
                AppIcon.sadFace,
                text: 'Not interested in this',
              ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.unFollow,
                text: 'Unfollow ${model.user!.userName}',
              ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.mute,
                text: 'Mute ${model.user!.userName}',
              ),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(context, AppIcon.block,
                text: 'Block ${model.user!.userName}',
                isEnable: true, onPressed: () {
                var state = Provider.of<AuthState>(context, listen: false);
                state.blockUser(model.user!.userId!);
                Navigator.pop(context);
              }),
        isMyTweet
            ? Container()
            : _widgetBottomSheetRow(
                context,
                AppIcon.report,
                text: 'Report Post',
                isEnable: true,
                onPressed: () async {
                  var authState =
                      Provider.of<AuthState>(context, listen: false);
                  final slackWebhookUrl =
                      'https://hooks.slack.com/services/XXXX/XXXX/XXXX';

                  try {
                    await http.post(
                      Uri.parse(slackWebhookUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'text':
                            '*Post Reported*\nReported by: ${authState.userModel?.email}\nPost content: ${model.description}\nPost ID: ${model.key}'
                      }),
                    );
                    Navigator.pop(context);
                    Utility.customSnackBar(
                        context, 'Post reported successfully');
                  } catch (e) {
                    print(e);
                    Utility.customSnackBar(context, 'Failed to report post');
                  }
                },
              ),
        isMyTweet
            ? _widgetBottomSheetRow(
                context,
                AppIcon.edit,
                text: 'Edit Post',
                isEnable: true,
                onPressed: () => _handleEditTweet(context, model),
              )
            : Container(),
        if (authState.userModel?.isOrganizer ?? false)
          _widgetBottomSheetRow(
            context,
            AppIcon.viewHidden,
            text: model.isHidden! ? 'Unhide Post' : 'Hide Post',
            isEnable: true,
            onPressed: () {
              var state = Provider.of<FeedState>(context, listen: false);
              state.toggleTweetVisibility(model);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _widgetBottomSheetRow(BuildContext context, IconData icon,
      {required String text, Function? onPressed, bool isEnable = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            customIcon(
              context,
              icon: icon,
              isTwitterIcon: true,
              size: 25,
              paddingIcon: 8,
              iconColor:
                  onPressed != null ? AppColor.darkGrey : AppColor.lightGrey,
            ),
            const SizedBox(
              width: 15,
            ),
            customText(
              text,
              context: context,
              style: TextStyle(
                color: isEnable
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
          ],
        ),
      ).ripple(() {
        if (onPressed != null) {
          onPressed();
        } else {
          Navigator.pop(context);
        }
      }),
    );
  }

  void _deleteTweet(BuildContext context, TweetType type, String tweetId,
      {String? parentkey}) {
    var state = Provider.of<FeedState>(context, listen: false);
    state.deleteTweet(tweetId, type, parentkey: parentkey);
    // CLose bottom sheet
    Navigator.of(context).pop();
    if (type == TweetType.Detail) {
      // Close Tweet detail page
      Navigator.of(context).pop();
      // Remove last tweet from tweet detail stack page
      state.removeLastTweetDetail(tweetId);
    }
  }

  void openRetweetBottomSheet(BuildContext context,
      {TweetType? type,
      required FeedModel model,
      required GlobalKey<ScaffoldState> scaffoldKey}) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: 130,
            width: context.width,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _retweet(context, model, type));
      },
    );
  }

  Widget _retweet(BuildContext context, FeedModel model, TweetType? type) {
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.retweet,
          isEnable: true,
          text: 'Repost',
          onPressed: () async {
            var state = Provider.of<FeedState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var myUser = authState.userModel;
            myUser = UserModel(
                displayName: myUser!.displayName ?? myUser.email!.split('@')[0],
                profilePic: myUser.profilePic,
                userId: myUser.userId,
                isVerified: authState.userModel!.isVerified,
                userName: authState.userModel!.userName);
            // Prepare current Tweet model to reply
            FeedModel post = FeedModel(
                childRetwetkey: model.getTweetKeyToRetweet,
                createdAt: DateTime.now().toUtc().toString(),
                user: myUser,
                userId: myUser.userId!);
            state.createTweet(post);

            Navigator.pop(context);
            var sharedPost = await state.fetchTweet(post.childRetwetkey!);
            if (sharedPost != null) {
              sharedPost.retweetCount ??= 0;
              sharedPost.retweetCount = sharedPost.retweetCount! + 1;
              state.updateTweet(sharedPost);
            }
          },
        ),
        _widgetBottomSheetRow(
          context,
          AppIcon.edit,
          text: 'Repost with comment',
          isEnable: true,
          onPressed: () {
            var state = Provider.of<FeedState>(context, listen: false);
            // Prepare current Tweet model to reply
            state.setTweetToReply = model;
            Navigator.pop(context);

            /// `/ComposeTweetPage/retweet` route is used to identify that tweet is going to be retweet.
            /// To simple reply on any `Tweet` use `ComposeTweetPage` route.
            Navigator.of(context).pushNamed('/ComposeTweetPage/retweet');
          },
        )
      ],
    );
  }

  void openShareTweetBottomSheet(
      BuildContext context, FeedModel model, TweetType? type) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            padding: const EdgeInsets.only(top: 5, bottom: 0),
            height: 180,
            width: context.width,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _shareTweet(context, model, type));
      },
    );
  }

  void _handleEditTweet(BuildContext context, FeedModel model) async {
    var state = Provider.of<FeedState>(context, listen: false);

    // Close bottom sheet before showing dialog
    Navigator.pop(context);

    // Small delay to allow bottom sheet to close
    await Future.delayed(const Duration(milliseconds: 200));

    if (!state.isTweetEditable(model)) {
      Utility.customSnackBar(
          context, 'Post can only be edited within 5 minutes');
      return;
    }

    // Show edit dialog
    final controller = TextEditingController(text: model.description);
    final newText = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLength: 280,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (newText != null && newText != model.description) {
      await state.editTweet(model, newText);
    }
  }

  Widget _shareTweet(BuildContext context, FeedModel model, TweetType? type) {
    var socialMetaTagParameters = SocialMetaTagParameters(
        description: model.description ?? "",
        title: "${model.user!.displayName} posted on Trusty.",
        imageUrl: Uri.parse(model.user?.profilePic ??
            "https://firebasestorage.googleapis.com/v0/b/trusty-4db3d.firebasestorage.app/o/user%2Fprofile%2Fdefault%2Fdefault_avatar.jpg?alt=media"));
    return Column(
      children: <Widget>[
        Container(
          width: context.width * .1,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<bool>(
          future: Provider.of<FeedState>(context, listen: false)
              .isBookmarked(model.key!),
          builder: (context, snapshot) {
            bool isBookmarked = snapshot.data ?? false;
            return _widgetBottomSheetRow(
              context,
              isBookmarked ? AppIcon.bookmark : AppIcon.bookmark,
              isEnable: true,
              text: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
              onPressed: () async {
                var state = Provider.of<FeedState>(context, listen: false);

                if (isBookmarked) {
                  await state.removeBookmark(model.key!);
                  Navigator.pop(context);
                  ScaffoldMessenger.maybeOf(context)!.showSnackBar(
                    const SnackBar(content: Text("Bookmark removed")),
                  );
                } else {
                  await state.addBookmark(model.key!);
                  Navigator.pop(context);
                  ScaffoldMessenger.maybeOf(context)!.showSnackBar(
                    const SnackBar(content: Text("Bookmark saved!")),
                  );
                }
              },
            );
          },
        ),
        // const SizedBox(height: 8),
        // _widgetBottomSheetRow(
        //   context,
        //   AppIcon.link,
        //   isEnable: true,
        //   text: 'Share Link',
        //   onPressed: () async {
        //     Navigator.pop(context);
        //     var url = Utility.createLinkToShare(
        //       context,
        //       "tweet/${model.key}",
        //       socialMetaTagParameters: socialMetaTagParameters,
        //     );
        //     var uri = await url;
        //     Utility.share(uri.toString(), subject: "Tweet");
        //   },
        // ),
        // const SizedBox(height: 8),
        _widgetBottomSheetRow(
          context,
          AppIcon.image,
          text: 'Share Post',
          isEnable: true,
          onPressed: () {
            socialMetaTagParameters = SocialMetaTagParameters(
                description: model.description ?? "",
                title: "${model.user!.displayName} posted on Trusty.",
                imageUrl: Uri.parse(model.user?.profilePic ??
                    "https://firebasestorage.googleapis.com/v0/b/trusty-4db3d.firebasestorage.app/o/user%2Fprofile%2Fdefault%2Fdefault_avatar.jpg?alt=media"));
            Navigator.pop(context);
            Navigator.push(
              context,
              ShareWidget.getRoute(
                  child: type != null
                      ? Tweet(
                          model: model,
                          type: type,
                          scaffoldKey: GlobalKey<ScaffoldState>(),
                        )
                      : Tweet(
                          model: model,
                          scaffoldKey: GlobalKey<ScaffoldState>()),
                  id: "tweet/${model.key}",
                  socialMetaTagParameters: socialMetaTagParameters),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
