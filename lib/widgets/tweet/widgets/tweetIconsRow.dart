import 'package:flutter/material.dart';
import 'package:Trusty/helper/customRoute.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/ui/page/common/usersListPage.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/tweet/widgets/tweetBottomSheet.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';

class TweetIconsRow extends StatelessWidget {
  final FeedModel model;
  final Color iconColor;
  final Color iconEnableColor;
  final double? size;
  final bool isTweetDetail;
  final TweetType? type;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const TweetIconsRow(
      {Key? key,
      required this.model,
      required this.iconColor,
      required this.iconEnableColor,
      this.size,
      this.isTweetDetail = false,
      this.type,
      required this.scaffoldKey})
      : super(key: key);

  Widget _likeCommentsIcons(BuildContext context, FeedModel model) {
    var authState = Provider.of<AuthState>(context, listen: false);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 0, top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            width: 20,
          ),
          _iconWidget(
            context,
            text: isTweetDetail ? '' : model.commentCount.toString(),
            icon: AppIcon.reply,
            iconColor: iconColor,
            size: size ?? 20,
            onPressed: () {
              var state = Provider.of<FeedState>(context, listen: false);
              state.setTweetToReply = model;
              Navigator.of(context).pushNamed('/ComposeTweetPage');
            },
          ),
          _iconWidget(context,
              text: isTweetDetail ? '' : model.retweetCount.toString(),
              icon: AppIcon.retweet,
              iconColor: iconColor,
              size: size ?? 20, onPressed: () {
            TweetBottomSheet().openRetweetBottomSheet(context,
                type: type, model: model, scaffoldKey: scaffoldKey);
          }),
          _iconWidget(
            context,
            text: isTweetDetail ? '' : model.likeCount.toString(),
            icon: model.likeList!.any((userId) => userId == authState.userId)
                ? AppIcon.heartFill
                : AppIcon.heartEmpty,
            onPressed: () {
              addLikeToTweet(context);
            },
            iconColor:
                model.likeList!.any((userId) => userId == authState.userId)
                    ? iconEnableColor
                    : iconColor,
            size: size ?? 20,
          ),
          if (model.isAiChecked != null) // Only show if isAiChecked is set
            _iconWidget(
              context,
              text: '',
              icon: model.isAiChecked == true
                  ? AppIcon.aiChecked
                  : AppIcon.aialert,
              size: size ?? 20,
              onPressed: () => _showAiCheckPopup(context, model),
              iconColor:
                  model.isAiChecked == true ? Colors.green : Colors.amber,
            ),
          _iconWidget(
            context,
            text: '',
            icon: AppIcon.bookmark,
            sysIcon: null,
            onPressed: () {
              shareTweet(context);
            },
            iconColor: iconColor,
            size: size ?? 20,
          ),
        ],
      ),
    );
  }

  Widget _iconWidget(BuildContext context,
      {required String text,
      IconData? icon,
      Function? onPressed,
      IconData? sysIcon,
      required Color iconColor,
      double size = 20}) {
    if (sysIcon == null) assert(icon != null);
    if (icon == null) assert(sysIcon != null);

    return Expanded(
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              if (onPressed != null) onPressed();
            },
            icon: sysIcon != null
                ? Icon(sysIcon, color: iconColor, size: size)
                : customIcon(
                    context,
                    size: size,
                    icon: icon!,
                    isTwitterIcon: true,
                    iconColor: iconColor,
                  ),
          ),
          customText(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontSize: size - 5,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  void _showAiCheckPopup(BuildContext context, FeedModel model) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: Icon(
                      model.isAiChecked == true
                          ? Icons.check_circle
                          : Icons.warning,
                      color: model.isAiChecked == true
                          ? Colors.green
                          : Colors.amber,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: 20),
                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        FadeAnimatedText(
                          model.isAiChecked == true
                              ? 'AI Content Detected'
                              : 'AI Content Detected',
                          duration: Duration(seconds: 20),
                          fadeOutBegin: 0.9,
                          fadeInEnd: 0.1,
                        ),
                      ],
                      isRepeatingAnimation: true,
                      repeatForever: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: model.isAiChecked == true
                          ? Colors.green.withOpacity(0.5)
                          : Colors.amber.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          model.isAiChecked == true
                              ? "This content is AI-generated and safe"
                              : "AI-generated content detected",
                          speed: Duration(milliseconds: 50),
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: model.isAiChecked == true
                            ? Colors.green.withOpacity(0.7)
                            : Colors.amber.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const SizedBox(width: 5),
            customText(Utility.getPostTime2(model.createdAt),
                style: TextStyles.textStyle14),
            const SizedBox(width: 10),
            customText('Trusty',
                style: TextStyle(color: Theme.of(context).primaryColor))
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _likeCommentWidget(BuildContext context) {
    bool isLikeAvailable =
        model.likeCount != null ? model.likeCount! > 0 : false;
    bool isRetweetAvailable = model.retweetCount! > 0;
    bool isLikeRetweetAvailable = isRetweetAvailable || isLikeAvailable;
    return Column(
      children: <Widget>[
        const Divider(
          height: 0,
          thickness: 0.5, // Optional: adjust divider thickness
        ),
        AnimatedContainer(
          padding:
              EdgeInsets.symmetric(vertical: isLikeRetweetAvailable ? 12 : 0),
          duration: const Duration(milliseconds: 500),
          child: !isLikeRetweetAvailable
              ? const SizedBox.shrink()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    !isRetweetAvailable
                        ? const SizedBox.shrink()
                        : customText(model.retweetCount.toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                    !isRetweetAvailable
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 5),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: customText('Retweets',
                          style: TextStyles.subtitleStyle),
                      crossFadeState: !isRetweetAvailable
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 800),
                    ),
                    !isRetweetAvailable
                        ? const SizedBox.shrink()
                        : const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        onLikeTextPressed(context);
                      },
                      child: AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Row(
                          children: <Widget>[
                            customSwitcherWidget(
                              duraton: const Duration(milliseconds: 300),
                              child: customText(model.likeCount.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  key: ValueKey(model.likeCount)),
                            ),
                            const SizedBox(width: 5),
                            customText('Likes', style: TextStyles.subtitleStyle)
                          ],
                        ),
                        crossFadeState: !isLikeAvailable
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    )
                  ],
                ),
        ),
        !isLikeRetweetAvailable
            ? const SizedBox.shrink()
            : const Divider(
                height: 0,
                thickness: 0.5, // Optional: adjust divider thickness
              ),
      ],
    );
  }

  Widget customSwitcherWidget(
      {required child, Duration duraton = const Duration(milliseconds: 500)}) {
    return AnimatedSwitcher(
      duration: duraton,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(child: child, scale: animation);
      },
      child: child,
    );
  }

  void addLikeToTweet(BuildContext context) {
    var state = Provider.of<FeedState>(context, listen: false);
    var authState = Provider.of<AuthState>(context, listen: false);
    state.addLikeToTweet(model, authState.userId);
  }

  void onLikeTextPressed(BuildContext context) {
    Navigator.of(context).push(
      CustomRoute<bool>(
        builder: (BuildContext context) => UsersListPage(
          pageTitle: "Liked by",
          userIdsList: model.likeList!.map((userId) => userId).toList(),
          emptyScreenText: "This tweet has no like yet",
          emptyScreenSubTileText:
              "Once a user likes this tweet, user list will be shown here",
        ),
      ),
    );
  }

  void shareTweet(BuildContext context) async {
    TweetBottomSheet().openShareTweetBottomSheet(context, model, type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        isTweetDetail ? _timeWidget(context) : const SizedBox(),
        isTweetDetail ? _likeCommentWidget(context) : const SizedBox(),
        _likeCommentsIcons(context, model)
      ],
    );
  }
}
