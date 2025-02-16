import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Trusty/state/suggestionUserState.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:Trusty/state/searchState.dart';
import 'package:Trusty/ui/page/common/locator.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/state/help_center_state.dart';

import 'helper/routes.dart';
import 'state/appState.dart';
import 'state/authState.dart';
import 'state/chats/chatState.dart';
import 'state/feedState.dart';
import 'state/notificationState.dart';
import 'state/eventState.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  if (kDebugMode) {
    print("****************************************************");
    print("Running in debug mode");
    print("****************************************************");
  }

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
        FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
        print("🔥 Using Firebase Emulators");
      } catch (e) {
        print("Error configuring emulators: $e");
      }
    }

    setupDependencies();
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    // TODO: Production mode error handling
  });

  // Firebase işlemlerini uygulama çalıştıktan sonra yapalım
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM Token main: $token');
    } catch (e, stacktrace) {
      print('Error getting FCM token: $e');
      print('Stacktrace: $stacktrace');
    }

    try {
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      });
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, stacktrace) {
      print('Error setting notification permissions: $e');
      print('Stacktrace: $stacktrace');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
        ChangeNotifierProvider<FeedState>(create: (_) => FeedState()),
        ChangeNotifierProvider<ChatState>(create: (_) => ChatState()),
        ChangeNotifierProvider<SearchState>(create: (_) => SearchState()),
        ChangeNotifierProvider<EventState>(create: (_) => EventState()),
        ChangeNotifierProvider<HelpCenterState>(
            create: (_) => HelpCenterState()),
        ChangeNotifierProvider<NotificationState>(
            create: (_) => NotificationState()),
        ChangeNotifierProvider<SuggestionsState>(
            create: (_) => SuggestionsState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) => MaterialApp(
          title: 'Trusty',
          theme: AppTheme.appTheme.copyWith(
            textTheme: GoogleFonts.mulishTextTheme(
              ThemeData.light().textTheme,
            ),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.mulishTextTheme(
              ThemeData.dark().textTheme,
            ),
          ),
          themeMode: appState.isDark ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          routes: Routes.route(),
          onGenerateRoute: (settings) => Routes.onGenerateRoute(settings),
          onUnknownRoute: (settings) => Routes.onUnknownRoute(settings),
          initialRoute: "SplashPage",
        ),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bu fonksiyonun içinde Firebase SDK'nın kullanılabilmesi için initialize edilmesi gerekebilir
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}
