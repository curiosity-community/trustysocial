import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:http/http.dart' as http;
//import 'package:googleapis_auth/auth_io.dart'; // Import for OAuth 2.0
import 'package:firebase_database/firebase_database.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Trusty/model/chatModel.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/state/appState.dart';

class ChatState extends AppState {
  late bool setIsChatScreenOpen; //!obsolete
  //final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  List<ChatMessage>? _messageList;
  List<ChatMessage>? _chatUserList;
  UserModel? _chatUser;
  // final String serviceAccountPath = 'lib/config/firebase_config.json';
  // final String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/trusty-4db3d/messages:send';

  UserModel? get chatUser => _chatUser;
  set setChatUser(UserModel model) {
    _chatUser = model;
  }

  String? _channelName;
  Query? messageQuery;

  /// Contains list of chat messages on main chat screen
  /// List is sortBy message timeStamp
  /// Last message will be display on the bottom of screen
  List<ChatMessage>? get messageList {
    if (_messageList == null) {
      return null;
    } else {
      _messageList!.sort((x, y) => DateTime.parse(y.createdAt!)
          .toLocal()
          .compareTo(DateTime.parse(x.createdAt!).toLocal()));
      return _messageList;
    }
  }

  /// Contain list of users who have chat history with logged in user
  List<ChatMessage>? get chatUserList {
    if (_chatUserList == null) {
      return null;
    } else {
      return List.from(_chatUserList!);
    }
  }

  // Add these stream subscription variables at the class level
  StreamSubscription<DatabaseEvent>? _chatUserSubscription;
  StreamSubscription<DatabaseEvent>? _messageAddedSubscription;
  StreamSubscription<DatabaseEvent>? _messageChangedSubscription;

  // Modify databaseInit to store the subscriptions
  void databaseInit(String userId, String myId) async {
    _messageList = null;
    if (_channelName == null) {
      getChannelName(userId, myId);
    }

    // Store the subscription
    _chatUserSubscription = kDatabase
        .child("chatUsers")
        .child(myId)
        .onChildAdded
        .listen(_onChatUserAdded);

    if (messageQuery == null || _channelName != getChannelName(userId, myId)) {
      messageQuery = kDatabase.child("chats").child(_channelName!);
      _messageAddedSubscription =
          messageQuery!.onChildAdded.listen(_onMessageAdded);
      _messageChangedSubscription =
          messageQuery!.onChildChanged.listen(_onMessageChanged);
    }
  }

  // Add dispose method
  @override
  void dispose() {
    // Cancel all stream subscriptions
    _chatUserSubscription?.cancel();
    _messageAddedSubscription?.cancel();
    _messageChangedSubscription?.cancel();

    // Clear lists
    _chatUserList?.clear();
    _messageList?.clear();

    super.dispose();
  }

  /// Fetch OAuth 2.0 access token using the service account
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

  /// Fetch users list to who have ever engaged in chat message with logged-in user
  void getUserChatList(String userId) {
    try {
      kDatabase
          .child('chatUsers')
          .child(userId)
          .once()
          .then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        _chatUserList = <ChatMessage>[];
        if (snapshot.value != null) {
          var map = snapshot.value as Map?;
          if (map != null) {
            map.forEach((key, value) {
              var model = ChatMessage.fromJson(value);
              model.key = key;
              _chatUserList!.add(model);
            });
          }
          _chatUserList!.sort((x, y) {
            if (x.createdAt != null && y.createdAt != null) {
              return DateTime.parse(y.createdAt!)
                  .compareTo(DateTime.parse(x.createdAt!));
            } else {
              if (x.createdAt != null) {
                return 0;
              } else {
                return 1;
              }
            }
          });
        } else {
          _chatUserList = null;
        }
        notifyListeners();
      });
    } catch (error) {
      cprint(error);
    }
  }

  /// Fetch all chat messages
  /// `_channelName` is used as primary key for chat message table
  /// `_channelName` is created from  by combining first 5 letters from user ids of two users
  void getChatDetailAsync() async {
    try {
      kDatabase
          .child('chats')
          .child(_channelName!)
          .once()
          .then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        _messageList = <ChatMessage>[];
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            map.forEach((key, value) {
              var model = ChatMessage.fromJson(value);
              model.key = key;
              _messageList!.add(model);
            });
          }
        } else {
          _messageList = null;
        }
        notifyListeners();
      });
    } catch (error) {
      cprint(error);
    }
  }

  /// Send message to other user
  void onMessageSubmitted(
    ChatMessage message,
  ) {
    print(chatUser!.userId);
    try {
      // if (_messageList == null || _messageList.length < 1) {
      kDatabase
          .child('chatUsers')
          .child(message.senderId)
          .child(message.receiverId)
          .set(message.toJson());

      kDatabase
          .child('chatUsers')
          .child(chatUser!.userId!)
          .child(message.senderId)
          .set(message.toJson());

      kDatabase
          .child('chats')
          .child(_channelName!)
          .push()
          .set(message.toJson());
      //sendAndRetrieveMessage(message);
      Utility.logEvent('send_message', parameter: {});
    } catch (error) {
      cprint(error);
    }
  }

  // This is removed, push notification will be handled on firebase functions
  /// Push notification will be sent to other user when you send them a message
  // void sendAndRetrieveMessage(ChatMessage model) async {
  //   if (chatUser!.fcmToken == null) {
  //     return;
  //   }
  //
  //   // Fetch access token
  //   final accessToken = await getAccessToken();
  //
  //   var body = jsonEncode(<String, dynamic>{
  //     'message': {
  //       'token': chatUser!.fcmToken,
  //       'notification': {
  //         'body': model.message,
  //         'title': "Message from ${model.senderName}"
  //       },
  //       'data': {
  //         'click_action': 'FLUTTER_NOTIFICATION_CLICK',
  //         'id': '1',
  //         'status': 'done',
  //         "type": NotificationType.Message.toString(),
  //         "senderId": model.senderId,
  //         "receiverId": model.receiverId,
  //         "title": "title",
  //         "body": model.message,
  //       },
  //     }
  //   });
  //
  //   var response = await http.post(
  //     Uri.parse(fcmEndpoint),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer ${accessToken.accessToken.data}',
  //     },
  //     body: body,
  //   );
  //
  //   if (response.reasonPhrase!.contains("INVALID_KEY")) {
  //     cprint(
  //       "You are using Invalid FCM key",
  //       errorIn: "sendAndRetrieveMessage",
  //     );
  //     return;
  //   }
  //   cprint(response.body.toString());
  // }

  String getChannelName(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    _channelName = '${list[0]}-${list[1]}';
    return _channelName!;
  }

  /// Method will trigger every time when you send/receive  from/to someone message.
  void _onMessageAdded(DatabaseEvent event) {
    _messageList ??= <ChatMessage>[];
    if (event.snapshot.value != null) {
      var map = event.snapshot.value as Map;
      // ignore: unnecessary_null_comparison
      if (map != null) {
        var model = ChatMessage.fromJson(map);
        model.key = event.snapshot.key!;
        if (_messageList!.isNotEmpty &&
            _messageList!.any((x) => x.key == model.key)) {
          return;
        }
        _messageList!.add(model);
      }
    } else {
      _messageList = null;
    }
    notifyListeners();
  }

  void _onMessageChanged(DatabaseEvent event) {
    _messageList ??= <ChatMessage>[];
    if (event.snapshot.value != null) {
      var map = event.snapshot.value as Map<dynamic, dynamic>;
      // ignore: unnecessary_null_comparison
      if (map != null) {
        var model = ChatMessage.fromJson(map);
        model.key = event.snapshot.key!;
        if (_messageList!.isNotEmpty &&
            _messageList!.any((x) => x.key == model.key)) {
          return;
        }
        _messageList!.add(model);
      }
    } else {
      _messageList = null;
    }
    notifyListeners();
  }

  void _onChatUserAdded(DatabaseEvent event) {
    _chatUserList ??= <ChatMessage>[];
    if (event.snapshot.value != null) {
      var map = event.snapshot.value as Map;
      // ignore: unnecessary_null_comparison
      if (map != null) {
        var model = ChatMessage.fromJson(map);
        model.key = event.snapshot.key!;
        if (_chatUserList!.isNotEmpty &&
            _chatUserList!.any((x) => x.key == model.key)) {
          return;
        }
        _chatUserList!.add(model);
      }
    } else {
      _chatUserList = null;
    }
    notifyListeners();
  }

  // update last message on chat user list screen when main chat screen get closed.
  void onChatScreenClosed() {
    if (_chatUserList != null &&
        _chatUserList!.isNotEmpty &&
        _chatUserList!.any((element) => element.key == chatUser!.userId)) {
      var user = _chatUserList!.firstWhere((x) => x.key == chatUser!.userId);
      if (_messageList != null) {
        user.message = _messageList!.first.message;
        user.createdAt = _messageList!.first.createdAt;
        _messageList = null;
        notifyListeners();
      }
    }
  }

  void getFCMServerKey() {}

  Future<void> deleteConversation(String userId, String otherId) async {
    try {
      // 1. Only delete from current user's chatUsers list
      await kDatabase.child('chatUsers').child(userId).child(otherId).remove();

      // 2. Add last message preview for remote user
      ChatMessage lastMessage = ChatMessage(
          message: "This conversation was deleted",
          createdAt: DateTime.now().toUtc().toString(),
          senderId: userId,
          receiverId: otherId,
          seen: false,
          timeStamp: DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
          senderName: "System");

      await kDatabase
          .child('chatUsers')
          .child(otherId)
          .child(userId)
          .set(lastMessage.toJson());

      // After successful deletion, refresh chat list
      getUserChatList(userId);

      // 3. Clear local message list
      _messageList?.clear();
      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: 'deleteConversation');
    }
  }
}
