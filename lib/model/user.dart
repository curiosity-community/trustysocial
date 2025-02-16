import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class UserModel extends Equatable {
  String? key;
  String? email;
  String? userId;
  String? displayName;
  String? userName;
  String? webSite;
  String? profilePic;
  String? bannerImage;
  String? contact;
  String? bio;
  String? location;
  String? dob;
  String? createdAt;
  bool? isVerified;
  bool? hasChangedUsername;
  int? followers;
  int? following;
  String? fcmToken;
  List<String>? followersList;
  List<String>? followingList;
  List<String>? blockedList;
  bool? isOrganizer;
  bool? isProfessional;
  double? rating;
  String? professionalKeywords;

  UserModel(
      {this.email,
      this.userId,
      this.displayName,
      this.profilePic,
      this.bannerImage,
      this.key,
      this.contact,
      this.bio,
      this.dob,
      this.location,
      this.createdAt,
      this.userName,
      this.hasChangedUsername,
      this.followers,
      this.following,
      this.webSite,
      this.isVerified,
      this.fcmToken,
      this.followersList,
      this.followingList,
      this.blockedList,
      this.isOrganizer,
      this.isProfessional,
      this.rating,
      this.professionalKeywords});

  UserModel.fromJson(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return;
    }
    followersList ??= [];
    email = map['email'];
    userId = map['userId'];
    displayName = map['displayName'];
    profilePic = map['profilePic'];
    bannerImage = map['bannerImage'];
    key = map['key'];
    dob = map['dob'];
    bio = map['bio'];
    location = map['location'];
    contact = map['contact'];
    createdAt = map['createdAt'];
    followers = map['followers'];
    following = map['following'];
    userName = map['userName'];
    hasChangedUsername = map['hasChangedUsername'] ?? false;
    webSite = map['webSite'];
    fcmToken = map['fcmToken'];
    isVerified = map['isVerified'] ?? false;
    isOrganizer = map['isOrganizer'] ?? false;
    isProfessional = map['isProfessional'] ?? false;
    rating = (map['rating'] ?? 0).toDouble();
    professionalKeywords = map['professionalKeywords'];
    if (map['followerList'] != null) {
      followersList = <String>[];
      map['followerList'].forEach((value) {
        if (value != null) {
          // Null kontrolü eklendi
          followersList!.add(value);
        }
      });
    }
    followers = followersList != null ? followersList!.length : null;
    if (map['followingList'] != null) {
      followingList = <String>[];
      map['followingList'].forEach((value) {
        if (value != null) {
          // Null kontrolü eklendi
          followingList!.add(value);
        }
      });
    }
    if (map['blockedList'] != null) {
      blockedList = <String>[];
      map['blockedList'].forEach((value) {
        if (value != null) {
          blockedList!.add(value);
        }
      });
    }
    following = followingList != null ? followingList!.length : null;
  }
  toJson() {
    return {
      'key': key,
      "userId": userId,
      "email": email,
      'displayName': displayName,
      'profilePic': profilePic,
      'bannerImage': bannerImage,
      'contact': contact,
      'dob': dob,
      'bio': bio,
      'location': location,
      'createdAt': createdAt,
      'followers': followersList != null ? followersList!.length : null,
      'following': followingList != null ? followingList!.length : null,
      'userName': userName,
      'hasChangedUsername': hasChangedUsername ?? false,
      'webSite': webSite,
      'isVerified': isVerified ?? false,
      'isOrganizer': isOrganizer ?? false,
      'fcmToken': fcmToken,
      'followerList': followersList,
      'followingList': followingList,
      'blockedList': blockedList,
      'isProfessional': isProfessional ?? false,
      'rating': rating ?? 0,
      'professionalKeywords': professionalKeywords,
    };
  }

  UserModel copyWith({
    String? email,
    String? userId,
    String? displayName,
    String? profilePic,
    String? key,
    String? contact,
    String? bio,
    String? dob,
    String? bannerImage,
    String? location,
    String? createdAt,
    String? userName,
    int? followers,
    int? following,
    String? webSite,
    bool? isVerified,
    String? fcmToken,
    List<String>? followingList,
    List<String>? followersList,
    bool? isOrganizer,
    bool? isProfessional,
    double? rating,
    String? professionalKeywords,
  }) {
    return UserModel(
      email: email ?? this.email,
      bio: bio ?? this.bio,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      dob: dob ?? this.dob,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isVerified: isVerified ?? this.isVerified,
      key: key ?? this.key,
      location: location ?? this.location,
      profilePic: profilePic ?? this.profilePic,
      bannerImage: bannerImage ?? this.bannerImage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      webSite: webSite ?? this.webSite,
      fcmToken: fcmToken ?? this.fcmToken,
      followersList: followersList ?? this.followersList,
      followingList: followingList ?? this.followingList,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isProfessional: isProfessional ?? this.isProfessional,
      rating: rating ?? this.rating,
      professionalKeywords: professionalKeywords ?? this.professionalKeywords,
    );
  }

  String get getFollower {
    return '${followers ?? 0}';
  }

  String get getFollowing {
    return '${following ?? 0}';
  }

  @override
  List<Object?> get props => [
        key,
        email,
        userId,
        displayName,
        userName,
        webSite,
        profilePic,
        bannerImage,
        contact,
        bio,
        location,
        dob,
        createdAt,
        isVerified,
        followers,
        following,
        fcmToken,
        followersList,
        followingList,
        isOrganizer,
        isProfessional,
        rating,
        professionalKeywords
      ];
}
