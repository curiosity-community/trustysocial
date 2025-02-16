import 'package:flutter/material.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/widgets/tweet/tweet.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:provider/provider.dart';

class HashtagFeedPage extends StatefulWidget {
  final String hashtag;

  const HashtagFeedPage({
    Key? key,
    required this.hashtag,
  }) : super(key: key);

  @override
  State<HashtagFeedPage> createState() => _HashtagFeedPageState();
}

class _HashtagFeedPageState extends State<HashtagFeedPage> {
  late FeedState _feedState;

  @override
  void initState() {
    super.initState();
    _feedState = Provider.of<FeedState>(context, listen: false);
  }

  @override
  void dispose() {
    _feedState.clearFilteredList();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        isBackButton: true,
        title: Text(widget.hashtag), // Note: use widget.hashtag here
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Consumer<FeedState>(
      builder: (context, state, child) {
        if (state.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.feedList == null || state.feedList!.isEmpty) {
          return const Center(
            child: EmptyList(
              'No Tweets found',
              subTitle: 'Tweets with this hashtag will appear here',
            ),
          );
        }

        return ListView.builder(
          itemCount: state.feedList!.length,
          itemBuilder: (context, index) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Tweet(
                model: state.feedList![index],
                type: TweetType.Tweet,
                scaffoldKey: GlobalKey<ScaffoldState>(),
              ),
            );
          },
        );
      },
    );
  }
}
