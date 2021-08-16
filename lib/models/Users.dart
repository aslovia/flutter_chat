import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  String userId;
  String photoUrl;
  String nickname;
  String aboutMe;
  String fcmToken;
  String createAt;
  String pushToken;

  Users(
      {required this.userId,
      required this.photoUrl,
      required this.nickname,
      required this.aboutMe,
      required this.fcmToken,
      required this.createAt,
      required this.pushToken});

  factory Users.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "",
        photoUrl = "",
        nickname = "",
        fcmToken = "",
        pushToken = "",
        createAt = "";
    try {
      aboutMe = doc.get('aboutMe');
    } catch (e) {}
    try {
      fcmToken = doc.get('FCMToken');
    } catch (e) {}
    try {
      fcmToken = doc.get('pushToken');
    } catch (e) {}
    try {
      photoUrl = doc.get('photoUrl');
    } catch (e) {}
    try {
      nickname = doc.get('nickname');
    } catch (e) {}
    return Users(
        userId: doc.id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
        fcmToken: fcmToken,
        pushToken: pushToken,
        createAt: createAt);
  }
}
