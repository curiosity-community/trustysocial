import 'package:firebase_database/firebase_database.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/model/hashTagModel.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/state/feedState.dart';
import 'appState.dart';

class SearchState extends AppState {
  bool isBusy = false;
  List<HashtagModel>? _hashtagSearchResults;
  List<HashtagModel>? get hashtagSearchResults => _hashtagSearchResults;
  String? searchQuery;
  SortUser sortBy = SortUser.MaxFollower;
  List<UserModel>? _userFilterList;
  List<UserModel>? _userlist;
  List<HashtagModel>? _trendingHashtags;
  List<HashtagModel>? get trendingHashtags => _trendingHashtags;
  String? aiResponseMessage;

  Future<void> getTrendingHashtags() async {
    try {
      isBusy = true;
      notifyListeners();

      var snapshot = await kDatabase
          .child('hashtags')
          .orderByChild('count')
          .limitToLast(10)
          .once();

      _trendingHashtags = [];

      if (snapshot.snapshot.value != null) {
        var map = snapshot.snapshot.value as Map;
        map.forEach((key, value) {
          if (value['tag'] != null && value['count'] != null) {
            _trendingHashtags!.add(HashtagModel.fromJson(value));
          }
        });
        _trendingHashtags!.sort((a, b) => b.count.compareTo(a.count));
      }

      isBusy = false;
      notifyListeners();
    } catch (e) {
      isBusy = false;
      _trendingHashtags = [];
      notifyListeners();
      cprint(e, errorIn: 'getTrendingHashtags');
    }
  }

  List<UserModel>? get userlist {
    if (_userFilterList == null) {
      return null;
    } else {
      return List.from(_userFilterList!);
    }
  }

  /// get [UserModel list] from firebase realtime Database
  void getDataFromDatabase() {
    try {
      isBusy = true;
      kDatabase.child('profile').once().then(
        (DatabaseEvent event) {
          final snapshot = event.snapshot;
          _userlist = <UserModel>[];
          _userFilterList = <UserModel>[];
          if (snapshot.value != null) {
            var map = snapshot.value as Map?;
            if (map != null) {
              map.forEach((key, value) {
                var model = UserModel.fromJson(value);
                model.key = key;
                _userlist!.add(model);
                _userFilterList!.add(model);
              });
              _userFilterList!
                  .sort((x, y) => y.followers!.compareTo(x.followers!));
              notifyListeners();
            }
          } else {
            _userlist = null;
          }
          isBusy = false;
        },
      );
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getDataFromDatabase');
    }
  }

  /// It will reset filter list
  /// If user has use search filter and change screen and came back to search screen It will reset user list.
  /// This function call when search page open.
  void resetFilterList() {
    if (_userlist != null && _userlist!.length != _userFilterList!.length) {
      _userFilterList = List.from(_userlist!);
      _userFilterList!.sort((x, y) => y.followers!.compareTo(x.followers!));
      // notifyListeners();
    }
  }

  /// This function call when search fiels text change.
  /// UserModel list on  search field get filter by `name` string
  void filterByUsername(String? query) {
    searchQuery = query;
    _hashtagSearchResults = null;

    if (query == null || query.isEmpty) {
      resetFilterList();
      notifyListeners();
      return;
    }

    if (query.startsWith('#')) {
      kDatabase.child('hashtags').once().then((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          _hashtagSearchResults = [];
          var map = event.snapshot.value as Map;
          String searchText = query
              .substring(1)
              .toLowerCase(); // Remove # and convert to lowercase

          map.forEach((key, value) {
            var model = HashtagModel.fromJson(value);
            // Filter hashtags that contain search text
            if (model.tag.toLowerCase().contains(searchText)) {
              _hashtagSearchResults!.add(model);
            }
          });
          _hashtagSearchResults!.sort((a, b) => b.count.compareTo(a.count));
        }
        notifyListeners();
      });
      return;
    }

    _userFilterList = _userlist!
        .where((x) =>
            x.userName != null &&
            x.userName!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    notifyListeners();
  }

  /// Sort user list on search user page.
  set updateUserSortPrefrence(SortUser val) {
    sortBy = val;
    notifyListeners();
  }

  String get selectedFilter {
    switch (sortBy) {
      case SortUser.Alphabetically:
        _userFilterList!
            .sort((x, y) => x.displayName!.compareTo(y.displayName!));
        return "Alphabetically";

      case SortUser.MaxFollower:
        _userFilterList!.sort((x, y) => y.followers!.compareTo(x.followers!));
        return "Popular";

      case SortUser.Newest:
        _userFilterList!.sort((x, y) => DateTime.parse(y.createdAt!)
            .compareTo(DateTime.parse(x.createdAt!)));
        return "Newest user";

      case SortUser.Oldest:
        _userFilterList!.sort((x, y) => DateTime.parse(x.createdAt!)
            .compareTo(DateTime.parse(y.createdAt!)));
        return "Oldest user";

      case SortUser.Verified:
        _userFilterList!.sort((x, y) =>
            y.isVerified.toString().compareTo(x.isVerified.toString()));
        return "Verified user";

      default:
        return "Unknown";
    }
  }

  /// Return user list relative to provided `userIds`
  /// Method is used on
  List<UserModel> userList = [];
  List<UserModel> getuserDetail(List<String> userIds) {
    final list = _userlist!.where((x) {
      if (userIds.contains(x.key)) {
        return true;
      } else {
        return false;
      }
    }).toList();
    return list;
  }

  void filterByHashtag(BuildContext context, String hashtag) {
    try {
      var feedState = Provider.of<FeedState>(context, listen: false);
      feedState.getDataFromDatabaseByHashtag(hashtag);
      Navigator.pushNamed(context, '/HashtagFeedPage/$hashtag');
    } catch (error) {
      cprint(error, errorIn: 'filterByHashtag');
    }
  }

  Future<void> updateHashtagCount(String hashtag) async {
    try {
      String safeTag = hashtag.replaceAll('#', '').trim();
      if (safeTag.isEmpty) return;
      var snapshot = await kDatabase.child('hashtags').child(safeTag).once();

      if (snapshot.snapshot.value != null) {
        var currentCount = (snapshot.snapshot.value as Map)['count'] ?? 0;
        await kDatabase
            .child('hashtags')
            .child(hashtag)
            .update({'count': currentCount + 1});
      } else {
        await kDatabase.child('hashtags').child(hashtag).set({
          'tag': hashtag,
          'count': 1,
          'createdAt': DateTime.now().toUtc().toString(),
        });
      }
    } catch (e) {
      cprint(e, errorIn: 'updateHashtagCount');
    }
  }

  List<UserModel> getVerifiedProfessionals() {
    return _userlist!.where((user) => user.isProfessional ?? false).toList();
  }

  List<dynamic> _professionals = [];

  List<dynamic> getProfessionalUsers() => _professionals;

  void updateAISearchResults(Map<String, dynamic> searchResponse) {
    aiResponseMessage = searchResponse['response'] as String;
    _professionals = searchResponse['users'] as List;
    notifyListeners();
  }

  void resetAISearchResults() {
    aiResponseMessage = null;
    _professionals = [];
    notifyListeners();
  }
}
