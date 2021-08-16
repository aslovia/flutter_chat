import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_chat/models/Users.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreCloud {
  static FirestoreCloud get instanace => FirestoreCloud();

  // About Firebase Database

  Future saveUserDataToFirebaseDatabase(userId, userName, userAvatar) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: userId)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      String myID = userId;
      String myName = userName;
      String myAvatar = userAvatar;
      if (documents.length == 0) {
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setString('userAvatar', userAvatar);
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'nickname': userName,
          'photoUrl': userAvatar,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'FCMToken': prefs.get('FCMToken') ?? 'NOToken',
        });
      } else {
        DocumentSnapshot documentSnapshot = documents[0];
        Users user = Users.fromDocument(documentSnapshot);
        myID = user.userId;
        myName = user.nickname;
        myAvatar = user.photoUrl;
        await prefs.setString('userId', myID);
        await prefs.setString('userName', myName);
        await prefs.setString('userAvatar', myAvatar);
      }
      return [myID, myName, myAvatar];
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> updateMyChatListValues(
      String myID, String groupChatID, bool isInRoom) async {
    var updateData =
        isInRoom ? {'inRoom': isInRoom, 'badgeCount': 0} : {'inRoom': isInRoom};
    final DocumentReference result = FirebaseFirestore.instance
        .collection('users')
        .doc(myID)
        .collection('chatlist')
        .doc(groupChatID);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(result);
      if (!snapshot.exists) {
        transaction.set(result, updateData);
      } else {
        transaction.update(result, updateData);
      }
    });
    int unReadMSGCount = await FirestoreCloud.instanace.getUnreadMSGCount(myID);
    FlutterAppBadger.updateBadgeCount(unReadMSGCount);
  }

  Future getUnreadMSGCount(String peerUserID) async {
    try {
      int unReadMSGCount = 0;
      QuerySnapshot userChatList = await FirebaseFirestore.instance
          .collection('users')
          .doc(peerUserID)
          .collection('chatlist')
          .get();
      List<QueryDocumentSnapshot> chatListDocuments = userChatList.docs;
      for (QueryDocumentSnapshot snapshot in chatListDocuments) {
        unReadMSGCount = unReadMSGCount + int.parse(snapshot['badgeCount']);
      }
      print('unread MSG count is $unReadMSGCount');
      return unReadMSGCount;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future sendMessageToChatRoom(
      groupChatId, myID, selectedUserID, messageContent, messageType) async {
    var documentReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        {
          'idFrom': myID,
          'idTo': selectedUserID,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': messageContent,
          'type': messageType,
          'isread': false,
        },
      );
    });
  }

  Future updateUserChatListField(String userId, String lastMessage,
      int typeMessage, groupChatID, myID, selectedUserID) async {
    var userBadgeCount = 0;
    var isRoom = false;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chatlist')
        .doc(groupChatID)
        .get();

    if (userDoc.data() != null) {
      isRoom = userDoc['inRoom'] ?? false;
      if (userDoc != null && userId != myID && !userDoc['inRoom']) {
        userBadgeCount = userDoc['badgeCount'];
        userBadgeCount++;
      }
    } else {
      userBadgeCount++;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chatlist')
        .doc(groupChatID)
        .set({
      'chatID': groupChatID,
      'chatWith': userId == myID ? selectedUserID : myID,
      'contentMessage': lastMessage,
      'typeMessage': typeMessage,
      'badgeCount': isRoom ? 0 : userBadgeCount,
      'inRoom': isRoom,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
}
