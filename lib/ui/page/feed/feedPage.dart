import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/feedState.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/customLoader.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/widgets/tweet/tweet.dart';
import 'package:Trusty/widgets/tweet/widgets/tweetBottomSheet.dart';
import 'package:provider/provider.dart';

class FeedPage extends StatelessWidget {
  const FeedPage(
      {Key? key, required this.scaffoldKey, this.refreshIndicatorKey})
      : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  Widget _floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/CreateFeedPage/tweet');
      },
      // child: customIcon(
      //   context,
      //   icon: AppIcon.settings,
      //   isTwitterIcon: true,
      //   iconColor: Theme.of(context).colorScheme.onPrimary,
      //   size: 25,
      // ),
      //backgroundColor: Theme.of(context).colorScheme.surface,
      child: Image.asset(
        'assets/images/trusty-plus-icon.png',
        height: 40, // Adjust as necessary
      ),
      shape: const CircleBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _floatingActionButton(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SizedBox(
          height: context.height,
          width: context.width,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  key: refreshIndicatorKey,
                  onRefresh: () async {
                    /// refresh home page feed
                    var feedState =
                        Provider.of<FeedState>(context, listen: false);
                    feedState.getDataFromDatabase();
                    feedState.clearFilteredList();
                    return Future.value(true);
                  },
                  child: _FeedPageBody(
                    refreshIndicatorKey: refreshIndicatorKey,
                    scaffoldKey: scaffoldKey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedPageBody extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const _FeedPageBody(
      {Key? key, required this.scaffoldKey, this.refreshIndicatorKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var authState = Provider.of<AuthState>(context, listen: false);
    return Consumer<FeedState>(
      builder: (context, state, child) {
        final List<FeedModel>? list = state.getTweetList(authState.userModel);
        return CustomScrollView(
          slivers: <Widget>[
            child!,
            state.isBusy && list == null
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: context.height - 135,
                      child: CustomScreenLoader(
                        height: double.infinity,
                        width: double.infinity,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  )
                : !state.isBusy && list == null
                    ? const SliverToBoxAdapter(
                        child: EmptyList(
                          'No Post added yet',
                          subTitle:
                              'When new Post added, they\'ll show up here \n Tap plus button to add new',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate(
                          list!.map(
                            (model) {
                              return Container(
                                color: Theme.of(context)
                                    .appBarTheme
                                    .backgroundColor,
                                child: Tweet(
                                  model: model,
                                  trailing: TweetBottomSheet().tweetOptionIcon(
                                      context,
                                      model: model,
                                      type: TweetType.Tweet,
                                      scaffoldKey: scaffoldKey),
                                  scaffoldKey: scaffoldKey,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      )
          ],
        );
      },
      child: SliverAppBar(
        floating: true,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                scaffoldKey.currentState!.openDrawer();
              },
            );
          },
        ),
        title: Image.asset('assets/images/trusty-icon.png', height: 40),
        centerTitle: true,
        actions: [
          Consumer<FeedState>(
            builder: (context, state, _) {
              if (state.filteredFeedList != null) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 1.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      backgroundColor: Colors.blueGrey.withOpacity(0.6),
                      foregroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      minimumSize: const Size(0, 28), // Set minimum height
                    ),
                    onPressed: () {
                      state.clearFilteredList();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(width: 3.0),
                        Icon(Icons.filter_list_off, size: 14),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        bottom: PreferredSize(
          child: Builder(
            builder: (context) => Container(
              color: Theme.of(context).dividerColor,
              height: 0.5,
            ),
          ),
          preferredSize: const Size.fromHeight(0.0),
        ),
      ),
    );
  }
}
