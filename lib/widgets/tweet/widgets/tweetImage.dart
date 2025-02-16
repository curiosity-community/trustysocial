import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/widgets/cache_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:provider/provider.dart';

class TweetImage extends StatelessWidget {
  const TweetImage(
      {Key? key, required this.model, this.type, this.isRetweetImage = false})
      : super(key: key);

  final FeedModel model;
  final TweetType? type;
  final bool isRetweetImage;
  @override
  Widget build(BuildContext context) {
    if (model.imagePath != null) assert(type != null);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      alignment: Alignment.centerRight,
      child: model.imagePath == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.all(
                  Radius.circular(isRetweetImage ? 0 : 20),
                ),
                onTap: () {
                  if (type == TweetType.ParentTweet) {
                    return;
                  }
                  var state = Provider.of<FeedState>(context, listen: false);
                  state.getPostDetailFromDatabase(model.key);
                  state.setTweetToReply = model;
                  state
                      .clearAllDetailAndReplyTweetStack(); // Clear previous image details
                  state.setFeedModel = model; // Set current model directly
                  Navigator.pushNamed(context, '/ImageViewPge');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(isRetweetImage ? 0 : 20),
                  ),
                  child: Container(
                    width: isRetweetImage
                        ? context.width - 8
                        : context.width *
                                (type == TweetType.Detail ? .95 : .82) -
                            8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: CacheImage(
                        path: model.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
