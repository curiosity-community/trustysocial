import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/state/bookmarkState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/widgets/tweet/tweet.dart';
import 'package:provider/provider.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  static Route<T> getRoute<T>() {
    return MaterialPageRoute(
      builder: (_) {
        return Provider(
          create: (_) => BookmarkState(),
          child: ChangeNotifierProvider(
            create: (BuildContext context) => BookmarkState(),
            builder: (_, child) => const BookmarkPage(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: Text("Bookmark", style: TextStyles.titleStyle),
        isBackButton: true,
      ),
      body: const BookmarkPageBody(),
    );
  }
}

class BookmarkPageBody extends StatelessWidget {
  const BookmarkPageBody({Key? key}) : super(key: key);

  Widget _tweet(BuildContext context, FeedModel model) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Tweet(
        model: model,
        type: TweetType.Tweet,
        scaffoldKey: GlobalKey<ScaffoldState>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<BookmarkState>(context);
    var list = state.tweetList;
    if (state.isbusy) {
      return const SizedBox(
        height: 3,
        child: LinearProgressIndicator(),
      );
    } else if (list == null || list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: EmptyList(
          'No Bookmark available yet',
          subTitle: 'When new bookmark found, they\'ll show up here.',
        ),
      );
    }
    return ListView.builder(
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) => _tweet(context, list[index]),
      itemCount: list.length,
    );
  }
}
