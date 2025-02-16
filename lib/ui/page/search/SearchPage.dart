import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/searchState.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/ui/page/feed/hashtag_feed_page.dart';
import 'package:Trusty/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/model/hashTagModel.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key, this.scaffoldKey}) : super(key: key);
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<SearchState>(context, listen: false);
      state.resetFilterList();
      state.getTrendingHashtags(); // Add this to fetch trending hashtags
    });
    super.initState();
  }

  void onSettingIconPressed() {
    Navigator.pushNamed(context, '/TrendsPage');
  }

  Widget _buildHashtagItem(BuildContext context, HashtagModel hashtag) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () {
          final state = Provider.of<SearchState>(context, listen: false);
          state.filterByHashtag(context, hashtag.tag);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HashtagFeedPage(hashtag: hashtag.tag),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hashtag.tag,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${hashtag.count} tweets',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection(BuildContext context, SearchState state) {
    if (state.trendingHashtags == null || state.trendingHashtags!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take only top 5 hashtags
    var topHashtags = state.trendingHashtags!.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Trending Hashtags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: topHashtags.length,
            itemBuilder: (context, index) {
              final hashtag = topHashtags[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    // Filter hashtags
                    onTap: () => state.filterByHashtag(context, hashtag.tag),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index == 0)
                            const Text(
                              '🔥 ',
                              style: TextStyle(fontSize: 16),
                            ),
                          Text(
                            hashtag.tag,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildUserList(List<UserModel>? users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users?.length ?? 0,
      separatorBuilder: (context, index) => const Divider(height: 0),
      itemBuilder: (context, index) => _UserTile(user: users![index]),
    );
  }

  Widget _buildHashtagResults(SearchState state) {
    final results = state.hashtagSearchResults;

    if (results == null || results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hashtags found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final hashtag = results[index];
        return ListTile(
          leading: const Icon(Icons.tag),
          title: Text(hashtag.tag),
          subtitle: Text('${hashtag.count} tweets'),
          onTap: () => state.filterByHashtag(context, hashtag.tag),
          //{
          // Handle hashtag selection
          //state.filterByHashtag(hashtag.tag);
          //print("search page: " + hashtag.tag);
          //},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: CustomAppBar(
            scaffoldKey: widget.scaffoldKey,
            icon: AppIcon.settings,
            onActionPressed: onSettingIconPressed,
            onSearchChanged: (text) {
              state.filterByUsername(text);
            },
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              state.getDataFromDatabase();
              state.getTrendingHashtags();
              return Future.value();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTrendingSection(context, state),
                  if (state.searchQuery?.startsWith('#') ?? false)
                    _buildHashtagResults(state)
                  else
                    _buildUserList(state.userlist),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({Key? key, required this.user}) : super(key: key);
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        if (kReleaseMode) {
          kAnalytics.logViewSearchResults(searchTerm: user.userName!);
        }
        Navigator.push(context, ProfilePage.getRoute(profileId: user.userId!));
      },
      leading: CircularImage(path: user.profilePic, height: 40),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: TitleText(
              user.displayName!,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          user.isVerified!
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: customIcon(
                    context,
                    icon: AppIcon.blueTick,
                    isTwitterIcon: true,
                    iconColor: AppColor.primary,
                    size: 15,
                    paddingIcon: 3,
                  ),
                )
              : const SizedBox(width: 0),
          user.isOrganizer!
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: customIcon(
                    context,
                    icon: AppIcon.organizer,
                    isTwitterIcon: true,
                    iconColor: AppColor.primary,
                    size: 15,
                    paddingIcon: 3,
                  ),
                )
              : const SizedBox(width: 0),
          user.isProfessional!
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: customIcon(
                    context,
                    icon: AppIcon.world,
                    isTwitterIcon: true,
                    iconColor: AppColor.primary,
                    size: 15,
                    paddingIcon: 3,
                  ),
                )
              : const SizedBox(width: 0),
        ],
      ),
      subtitle: Text(user.userName!),
    );
  }
}
