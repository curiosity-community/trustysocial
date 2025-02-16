import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as db;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Trusty/helper/enum.dart';
import 'package:Trusty/helper/shared_prefrence_helper.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/model/referral_code_model.dart';
import 'package:Trusty/ui/page/common/locator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as path;

import 'appState.dart';

class AuthState extends AppState {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  bool isSignInWithGoogle = false;
  User? user;
  late String userId;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  db.Query? _profileQuery;
  // List<UserModel> _profileUserModelList;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  UserModel? get profileUserModel => _userModel;

  /// Logout from device
  void logoutCallback() async {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    _userModel = null;
    user = null;
    _profileQuery!.onValue.drain();
    _profileQuery = null;
    if (isSignInWithGoogle) {
      _googleSignIn.signOut();
      Utility.logEvent('google_logout', parameter: {});
      isSignInWithGoogle = false;
    }
    _firebaseAuth.signOut();
    await getIt<SharedPreferenceHelper>().clearPreferenceValues();
    notifyListeners();
  }

  /// Alter select auth method, login and sign up page
  void openSignUpPage() {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    notifyListeners();
  }

  void databaseInit() {
    try {
      if (_profileQuery == null) {
        _profileQuery = kDatabase.child("profile").child(user!.uid);
        _profileQuery!.onValue.listen(_onProfileChanged);
        _profileQuery!.onChildChanged.listen(_onProfileUpdated);
      }
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
    }
  }

  /// Verify user's credentials for login
  Future<String?> signIn(String email, String password,
      {required BuildContext context}) async {
    try {
      isBusy = true;
      var result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      user = result.user;
      userId = user!.uid;
      return user!.uid;
    } on FirebaseException catch (error) {
      if (error.code == 'firebase_auth/user-not-found') {
        Utility.customSnackBar(context, 'User not found');
      } else {
        Utility.customSnackBar(
          context,
          error.message ?? 'Something went wrong',
        );
      }
      cprint(error, errorIn: 'signIn');
      return null;
    } catch (error) {
      Utility.customSnackBar(context, error.toString());
      cprint(error, errorIn: 'signIn');

      return null;
    } finally {
      isBusy = false;
    }
  }

  /// Create user from `google login`
  /// If user is new then it create a new user
  /// If user is old then it just `authenticate` user and return firebase user data
  Future<User?> handleGoogleSignIn() async {
    try {
      /// Record log in firebase kAnalytics about Google login
      kAnalytics.logLogin(loginMethod: 'google_login');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google login cancelled by user');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      user = (await _firebaseAuth.signInWithCredential(credential)).user;
      authStatus = AuthStatus.LOGGED_IN;
      userId = user!.uid;
      isSignInWithGoogle = true;
      createUserFromGoogleSignIn(user!);
      notifyListeners();
      return user;
    } on PlatformException catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } on Exception catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    }
  }

  /// Create user profile from google login
  void createUserFromGoogleSignIn(User user) {
    var diff = DateTime.now().difference(user.metadata.creationTime!);
    // Check if user is new or old
    // If user is new then add new user to firebase realtime kDatabase
    if (diff < const Duration(seconds: 15)) {
      UserModel model = UserModel(
        bio: 'Edit profile to update bio',
        dob: DateTime(1950, DateTime.now().month, DateTime.now().day + 3)
            .toString(),
        location: 'Somewhere in universe',
        profilePic: user.photoURL!,
        displayName: user.displayName!,
        email: user.email!,
        key: user.uid,
        userId: user.uid,
        contact: user.phoneNumber!,
        isVerified: user.emailVerified,
      );
      createUser(model, newUser: true);
    } else {
      cprint('Last login at: ${user.metadata.lastSignInTime}');
    }
  }

  /// Create new user's profile in db
  Future<String?> signUp(UserModel userModel,
      {required BuildContext context,
      required String password,
      required String referralCode}) async {
    try {
      isBusy = true;

      var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: userModel.email!,
        password: password,
      );
      user = result.user;

      // Kullanıcı oluşturulduktan sonra referans kodunu kullanıldı olarak işaretle
      await _markReferralCodeAsUsed(referralCode, user!.uid);

      authStatus = AuthStatus.LOGGED_IN;
      kAnalytics.logSignUp(signUpMethod: 'register');

      result.user!.updateDisplayName(userModel.displayName);
      result.user!.updatePhotoURL(userModel.profilePic);

      _userModel = userModel;
      _userModel!.key = user!.uid;
      _userModel!.userId = user!.uid;
      createUser(_userModel!, newUser: true);
      return user!.uid;
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'signUp');
      Utility.customSnackBar(context, error.toString());
      return null;
    }
  }

  Future<void> _markReferralCodeAsUsed(
      String referralCode, String userId) async {
    try {
      final event = await kDatabase.child('referralCodes').once();
      final snapshot = event.snapshot;

      if (snapshot.value != null) {
        var codes = snapshot.value as Map<dynamic, dynamic>;
        var codeEntry = codes.entries.firstWhere(
          (entry) => entry.value['code'] == referralCode,
          orElse: () => MapEntry('', null),
        );

        if (codeEntry.value != null && codeEntry.key.isNotEmpty) {
          await kDatabase
              .child('referralCodes')
              .child(codeEntry.key)
              .child('usedBy')
              .set(userId);
        }
      }
    } catch (error) {
      cprint(error, errorIn: '_markReferralCodeAsUsed');
    }
  }

  /// `Create` and `Update` user
  /// IF `newUser` is true new user is created
  /// Else existing user will update with new values
  void createUser(UserModel user, {bool newUser = false}) {
    if (newUser) {
      // Create username by the combination of name and id
      user.userName =
          Utility.getUserName(id: user.userId!, name: user.displayName!);
      kAnalytics.logEvent(name: 'create_newUser');

      // Time at which user is created
      user.createdAt = DateTime.now().toUtc().toString();
    }

    kDatabase.child('profile').child(user.userId!).set(user.toJson());
    _userModel = user;
    isBusy = false;
  }

  /// Fetch current user profile
  Future<User?> getCurrentUser() async {
    try {
      isBusy = true;
      Utility.logEvent('get_currentUSer', parameter: {});
      user = _firebaseAuth.currentUser;
      if (user != null) {
        await getProfileUser();
        authStatus = AuthStatus.LOGGED_IN;
        userId = user!.uid;

        await fetchReferralCodes();
      } else {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      }
      isBusy = false;
      return user;
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getCurrentUser');
      authStatus = AuthStatus.NOT_LOGGED_IN;
      return null;
    }
  }

  /// Reload user to get refresh user data
  void reloadUser() async {
    await user!.reload();
    user = _firebaseAuth.currentUser;
    if (user!.emailVerified) {
      userModel!.isVerified = true;
      // If user verified his email
      // Update user in firebase realtime kDatabase
      createUser(userModel!);
      cprint('UserModel email verification complete');
      Utility.logEvent('email_verification_complete',
          parameter: {userModel!.userName!: user!.email!});
    }
  }

  /// Send email verification link to email2
  Future<void> sendEmailVerification(BuildContext context) async {
    User user = _firebaseAuth.currentUser!;
    user.sendEmailVerification().then((_) {
      Utility.logEvent('email_verification_sent',
          parameter: {userModel!.displayName!: user.email!});
      Utility.customSnackBar(
        context,
        'An email verification link is send to your email.',
      );
    }).catchError((error) {
      cprint(error.message, errorIn: 'sendEmailVerification');
      Utility.logEvent('email_verification_block',
          parameter: {userModel!.displayName!: user.email!});
      Utility.customSnackBar(
        context,
        error.message,
      );
    });
  }

  /// Send password reset link to the provided email
  Future<void> sendPasswordResetEmail(
      String email, BuildContext context) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      Utility.logEvent('password_reset_email_sent',
          parameter: {'email': email});
      Utility.customSnackBar(
        context,
        'A password reset link has been sent to $email.',
      );
    } catch (error) {
      cprint(error.toString(), errorIn: 'sendPasswordResetEmail');
      Utility.logEvent('password_reset_email_failed',
          parameter: {'email': email});
      Utility.customSnackBar(
        context,
        'Failed to send password reset email. Please try again.',
      );
    }
  }

  /// Username can be change once
  Future<void> updateUsername(String newUsername) async {
    if (userModel != null) {
      try {
        userModel!.userName = newUsername;
        userModel!.hasChangedUsername = true;

        createUser(userModel!); // Bu metod zaten kullanıcıyı günceller

        notifyListeners(); // UI'nin güncellenmesi için
      } catch (error) {
        cprint(error, errorIn: 'updateUsername');
        throw Exception('Failed to update username');
      }
    } else {
      throw Exception('User model is null');
    }
  }

  /// Check username is taken
  Future<bool> isUsernameTaken(String username) async {
    // Replace with the appropriate database query logic to check if the username exists
    var snapshot = await kDatabase
        .child('profile')
        .orderByChild('userName')
        .equalTo(username)
        .once();
    return snapshot.snapshot.value != null; // Return true if a match is found
  }

  /// Check if user's email is verified
  Future<bool> emailVerified() async {
    User user = _firebaseAuth.currentUser!;
    return user.emailVerified;
  }

  /// Send password reset link to email
  Future<void> forgetPassword(String email,
      {required BuildContext context}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email).then((value) {
        Utility.customSnackBar(context,
            'A reset password link is sent yo your mail.You can reset your password from there');
        Utility.logEvent('forgot+password', parameter: {});
      }).catchError((error) {
        cprint(error.message);
      });
    } catch (error) {
      Utility.customSnackBar(context, error.toString());
      return Future.value(false);
    }
  }

  /// `Update user` profile
  Future<void> updateUserProfile(UserModel? userModel,
      {File? image, File? bannerImage}) async {
    try {
      if (image == null && bannerImage == null) {
        createUser(userModel!);
      } else {
        /// upload profile image if not null
        if (image != null) {
          /// get image storage path from server
          userModel!.profilePic = await _uploadFileToStorage(image,
              'user/profile/${userModel.userName}/${path.basename(image.path)}');
          // print(fileURL);
          var name = userModel.displayName ?? user!.displayName;
          _firebaseAuth.currentUser!.updateDisplayName(name);
          _firebaseAuth.currentUser!.updatePhotoURL(userModel.profilePic);
          Utility.logEvent('user_profile_image');
        }

        /// upload banner image if not null
        if (bannerImage != null) {
          /// get banner storage path from server
          userModel!.bannerImage = await _uploadFileToStorage(bannerImage,
              'user/profile/${userModel.userName}/${path.basename(bannerImage.path)}');
          Utility.logEvent('user_banner_image');
        }

        if (userModel != null) {
          createUser(userModel);
        } else {
          createUser(_userModel!);
        }
      }

      Utility.logEvent('update_user');
    } catch (error) {
      cprint(error, errorIn: 'updateUserProfile');
    }
  }

  Future<String> _uploadFileToStorage(File file, path) async {
    var task = _firebaseStorage.ref().child(path);
    var status = await task.putFile(file);
    cprint(status.state.name);

    /// get file storage path from server
    return await task.getDownloadURL();
  }

  /// `Fetch` user `detail` whose userId is passed
  Future<UserModel?> getUserDetail(String userId) async {
    UserModel user;
    var event = await kDatabase.child('profile').child(userId).once();

    final map = event.snapshot.value as Map?;
    if (map != null) {
      user = UserModel.fromJson(map);
      user.key = event.snapshot.key!;
      return user;
    } else {
      return null;
    }
  }

  /// Fetch user profile
  /// If `userProfileId` is null then logged in user's profile will fetched
  FutureOr<void> getProfileUser({String? userProfileId}) {
    try {
      userProfileId = userProfileId ?? user!.uid;
      kDatabase
          .child("profile")
          .child(userProfileId)
          .once()
          .then((DatabaseEvent event) async {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            if (userProfileId == user!.uid) {
              _userModel = UserModel.fromJson(map);
              _userModel!.isVerified = user!.emailVerified;
              if (!user!.emailVerified) {
                // Check if logged in user verified his email address or not
                // reloadUser();
              }

              // Update FCM token everytime user profile is fetched
              updateFCMToken();

              // if (_userModel!.fcmToken == null) {
              //   updateFCMToken();
              // }

              getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
            }

            //Utility.logEvent('get_profile', parameter: {});
          }
        }
        isBusy = false;
      });
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getProfileUser');
    }
  }

  /// if firebase token not available in profile
  /// Then get token from firebase and save it to profile
  /// When someone sends you a message FCM token is used
  void updateFCMToken() async {
    if (_userModel == null) return;

    try {
      String? newFcmToken = await FirebaseMessaging.instance.getToken();

      // Check if the new token is different from the existing one
      if (newFcmToken != _userModel!.fcmToken) {
        _userModel!.fcmToken = newFcmToken;
        Utility.logEvent('update_fcm_token', parameter: {});
        createUser(_userModel!); // Update user in the database
      }
    } catch (e) {
      cprint("FCM Token Error: $e");
    }
  }

  /// Trigger when logged-in user's profile change or updated
  /// Firebase event callback for profile update
  void _onProfileChanged(DatabaseEvent event) {
    final val = event.snapshot.value;
    if (val is Map) {
      final updatedUser = UserModel.fromJson(val);
      _userModel = updatedUser;
      cprint('UserModel Updated');
      getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
      notifyListeners();
    }
  }

  void _onProfileUpdated(DatabaseEvent event) {
    final val = event.snapshot.value;
    if (val is List &&
        ['following', 'followers'].contains(event.snapshot.key)) {
      final list = val.cast<String>().map((e) => e).toList();
      if (event.previousChildKey == 'following') {
        _userModel = _userModel!.copyWith(
          followingList: val.cast<String>().map((e) => e).toList(),
          following: list.length,
        );
      } else if (event.previousChildKey == 'followers') {
        _userModel = _userModel!.copyWith(
          followersList: list,
          followers: list.length,
        );
      }
      getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
      cprint('UserModel Updated');
      notifyListeners();
    }
  }

  Future<String?> getMasterReferralCode() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      return remoteConfig.getString('master_referral_code');
    } catch (error) {
      print("Error fetching master referral code: $error");
      return null;
    }
  }

  Future<bool> validateAndUseReferralCode(
      String referralCode, String newUserId) async {
    try {
      // Önce master kodu kontrol et
      String? masterCode = await getMasterReferralCode();
      print("Master code: $masterCode");
      if (masterCode == referralCode) {
        return true;
      }

      // Normal referans kodlarını kontrol et
      final event = await kDatabase.child('referralCodes').once();
      final snapshot = event.snapshot;

      if (snapshot.value != null) {
        var codes = snapshot.value as Map<dynamic, dynamic>;

        // Geçerli bir referans kodu bul
        var validCode = codes.entries.firstWhere(
          (entry) =>
              entry.value['code'] == referralCode &&
              !entry.value.containsKey('usedBy'),
          orElse: () => MapEntry('', null),
        );

        if (validCode.value != null) {
          // Kodu kullanıldı olarak işaretle
          await kDatabase
              .child('referralCodes')
              .child(validCode.key)
              .child('usedBy')
              .set(newUserId);
          return true;
        }
      }

      return false;
    } catch (error) {
      print("Error validating referral code: $error");
      return false;
    }
  }

  List<ReferralCode> _referralCodes = [];
  List<ReferralCode> get referralCodes => _referralCodes;

  Future<void> fetchReferralCodes() async {
    try {
      // Eğer kullanıcı girişi yapılmamışsa işlemi durdur
      if (user == null) {
        _referralCodes = [];
        return;
      }

      print("Current user ID: ${user!.uid}");

      final event = await kDatabase.child('referralCodes').once();
      final snapshot = event.snapshot;

      _referralCodes = [];
      if (snapshot.value != null) {
        var map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          var code = ReferralCode.fromJson(value);
          // Kullanıcının ID'sini user.uid'den al
          if (code.createdFor == user!.uid && code.usedBy == null) {
            _referralCodes.add(code);
          }
        });
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching referral codes: $error");
      cprint(error, errorIn: 'fetchReferralCodes');
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      isBusy = true;
      notifyListeners();

      // Store user ID before deletion since we'll lose it after auth deletion
      final String currentUserId = userId;

      // First delete the user from Firebase Auth to prevent any new data access
      await user?.delete();

      // Then delete user data from Firebase Database
      await kDatabase.child('profile').child(currentUserId).remove();
      await kDatabase.child('notification').child(currentUserId).remove();
      await kDatabase.child('bookmark').child(currentUserId).remove();

      // Delete user's tweets
      await kDatabase
          .child('tweet')
          .orderByChild('userId')
          .equalTo(currentUserId)
          .once()
          .then((DatabaseEvent event) async {
        if (event.snapshot.value != null) {
          Map tweets = event.snapshot.value as Map;
          tweets.forEach((key, value) async {
            await kDatabase.child('tweet').child(key).remove();
          });
        }
      });

      await kDatabase.child('chatUsers').child(currentUserId).remove();

      // Clear all local state
      authStatus = AuthStatus.NOT_LOGGED_IN;
      userId = '';
      _userModel = null;
      user = null;
      if (_profileQuery != null) {
        _profileQuery!.onValue.drain();
        _profileQuery = null;
      }

      // Clear shared preferences
      await getIt<SharedPreferenceHelper>().clearPreferenceValues();

      // Notify listeners before navigation
      notifyListeners();

      // Navigate to welcome page and clear all routes
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/WelcomePage', (route) => false);
      }
    } catch (error) {
      isBusy = false;
      notifyListeners();
      if (context.mounted) {
        Utility.customSnackBar(
          context,
          'Failed to delete account. Please try again.',
        );
      }
      cprint(error, errorIn: 'deleteAccount');
    }
  }

  /// Block user
  Future<void> blockUser(String userToBlockId) async {
    try {
      userModel!.blockedList ??= [];
      userModel!.blockedList!.add(userToBlockId);

      // Update in database
      await kDatabase
          .child('profile')
          .child(userModel!.userId!)
          .child('blockedList')
          .set(userModel!.blockedList);

      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: 'blockUser');
    }
  }

  /// Unblock user
  Future<void> unblockUser(String userToUnblockId) async {
    try {
      userModel!.blockedList?.remove(userToUnblockId);

      await kDatabase
          .child('profile')
          .child(userModel!.userId!)
          .child('blockedList')
          .set(userModel!.blockedList);

      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: 'unblockUser');
    }
  }

  Future<void> getLatestReferralCodes() async {
    try {
      // Eğer kullanıcı girişi yapılmamışsa işlemi durdur
      if (user == null) {
        _referralCodes = [];
        return;
      }

      final event = await kDatabase.child('referralCodes').once();
      final snapshot = event.snapshot;

      _referralCodes = [];
      if (snapshot.value != null) {
        var map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          var code = ReferralCode.fromJson(value);
          if (code.createdFor == user!.uid && code.usedBy == null) {
            _referralCodes.add(code);
          }
        });
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching referral codes: $error");
      cprint(error, errorIn: 'getLatestReferralCodes');
    }
  }
}
