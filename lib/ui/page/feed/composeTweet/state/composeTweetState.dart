import 'dart:convert';
import 'dart:io';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart'; // Import for OAuth 2.0
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/model/feedModel.dart';
import 'package:Trusty/state/searchState.dart';

class ComposeTweetState extends ChangeNotifier {
  bool showUserList = false;
  bool enableSubmitButton = false;
  bool hideUserList = false;
  String description = "";
  final usernameRegex = r'(@\w*[a-zA-Z1-9]$)';

  bool _isScrollingDown = false;
  bool get isScrollingDown => _isScrollingDown;
  set setIsScrollingDown(bool value) {
    _isScrollingDown = value;
    notifyListeners();
  }
  //
  // final String serviceAccountPath = 'lib/config/firebase_config.json';
  // final String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/trusty-4db3d/messages:send';

  /// Method to obtain an OAuth 2.0 access token using service account credentials
  // Future<AccessCredentials> getAccessToken() async {
  //   final serviceAccountJson = File(serviceAccountPath).readAsStringSync();
  //   final serviceAccount = jsonDecode(serviceAccountJson);
  //   final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
  //   final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  //   final client = http.Client();
  //   final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
  //     accountCredentials,
  //     scopes,
  //     client,
  //   );
  //   client.close();
  //   return accessCredentials;
  // }

  /// Display/Hide user list on the basis of username availability in description
  bool get displayUserList {
    RegExp regExp = RegExp(usernameRegex);
    var status = regExp.hasMatch(description);
    return status && !hideUserList;
  }

  /// Hide user list when a user selects a username from the user list
  void onUserSelected() {
    hideUserList = true;
    notifyListeners();
  }

  /// Triggered when user writes tweet description.
  void onDescriptionChanged(String text, SearchState searchState) {
    description = text;
    hideUserList = false;
    if (text.isEmpty || text.length > 280) {
      enableSubmitButton = false;
      notifyListeners();
      return;
    }

    enableSubmitButton = true;
    var last = text.substring(text.length - 1, text.length);

    RegExp regExp = RegExp(usernameRegex);
    var status = regExp.hasMatch(text);
    if (status) {
      Iterable<Match> _matches = regExp.allMatches(text);
      var name = text.substring(_matches.last.start, _matches.last.end);

      if (last == "@") {
        searchState.filterByUsername("");
      } else {
        searchState.filterByUsername(name);
      }
    } else {
      hideUserList = false;
      notifyListeners();
    }
  }

  /// When user selects a user from user list, it adds the username in the description
  String getDescription(String username) {
    RegExp regExp = RegExp(usernameRegex);
    Iterable<Match> _matches = regExp.allMatches(description);
    var name = description.substring(0, _matches.last.start);
    description = '$name $username';
    return description;
  }

  /// Send notification to user once fcmToken is retrieved from firebase
  Future<void> sendNotification(FeedModel model, SearchState state) async {
    const usernameRegex = r"(@\w*[a-zA-Z1-9])";
    RegExp regExp = RegExp(usernameRegex);
    var status = regExp.hasMatch(description);

    if (status) {
      state.filterByUsername("");

      Iterable<Match> _matches = regExp.allMatches(description);
      print("${_matches.length} name found in description");

      await Future.forEach(_matches, (Match match) async {
        var name = description.substring(match.start, match.end);
        if (state.userlist!.any((x) => x.userName == name)) {
          final user = state.userlist!.firstWhere((x) => x.userName == name);
          //await sendNotificationToUser(model, user);
        } else {
          cprint("Name: $name ,", errorIn: "UserNot found");
        }
      });
    }
  }

  /// Send notification using Firebase Notification HTTP v1 API
//   Future<void> sendNotificationToUser(FeedModel model, UserModel user) async {
//     print("Send notification to: ${user.userName}");
//
//     if (user.fcmToken == null) {
//       return;
//     }
//
//     final accessToken = await getAccessToken();
//
//     var body = jsonEncode(<String, dynamic>{
//       'message': {
//         'token': user.fcmToken,
//         'notification': {
//           'body': model.description,
//           'title': "${model.user!.displayName} mentioned you in a tweet"
//         },
//         'data': {
//           'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//           'id': '1',
//           'status': 'done',
//           "type": NotificationType.Mention.toString(),
//           "senderId": model.user!.userId,
//           "receiverId": user.userId,
//           "title": "title",
//           "body": "",
//           "tweetId": model.key
//         },
//       }
//     });
//
//     var response = await http.post(
//       Uri.parse(fcmEndpoint),
//       headers: <String, String>{
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer ${accessToken.accessToken.data}',
//       },
//       body: body,
//     );
//     cprint(response.body.toString());
//   }
}
