import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/models/Users.dart';
import 'package:flutter_chat/utils/Loading.dart';
import 'package:flutter_chat/utils/function.dart';
import 'package:flutter_chat/widgets/LocalNotificationWidgets.dart';

class HomeWidgets {
  Widget buildFriendsList(
      int _limit, String myID, Function _moveToChatRoom, listScrollController) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .limit(_limit)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => HomeWidgets().buildItemFriends(
                  context, snapshot.data?.docs[index], myID, _moveToChatRoom),
              itemCount: snapshot.data?.docs.length,
              controller: listScrollController,
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildItemFriends(BuildContext context, DocumentSnapshot? document,
      String myId, Function _moveToChatRoom) {
    if (document != null) {
      Users userChat = Users.fromDocument(document);
      if (userChat.userId == myId) {
        return SizedBox.shrink();
      } else {
        return Container(
          child: TextButton(
            child: Row(
              children: <Widget>[
                Material(
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50.0,
                          height: 50.0,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  value: loadingProgress.expectedTotalBytes !=
                                              null &&
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return Icon(
                              Icons.account_circle,
                              size: 50.0,
                              color: Colors.grey,
                            );
                          },
                        )
                      : Icon(
                          Icons.account_circle,
                          size: 50.0,
                          color: Colors.grey,
                        ),
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                Flexible(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(
                            userChat.nickname,
                            maxLines: 1,
                            style: TextStyle(color: Colors.black),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        Container(
                          child: Text(
                            'Tentang Saya: ${userChat.aboutMe}',
                            maxLines: 1,
                            style: TextStyle(color: Colors.black),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20.0),
                  ),
                ),
              ],
            ),
            onPressed: () {
              _moveToChatRoom(userChat.userId, userChat.nickname,
                  userChat.photoUrl, userChat.fcmToken);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  Widget buildHistory(BuildContext context, String myID, int _limit,
      ScrollController listScrollController, Function _moveToChatRoom) {
    final size = MediaQuery.of(context).size;
    return Container(
      child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> userSnapshot) {
            if (!userSnapshot.hasData) return Loading();
            return countChatListUsers(myID, userSnapshot) > 0
                ? Stack(
                    children: [
                      ListView(
                          children: userSnapshot.data!.docs.map((userData) {
                        if (userData['userId'] == myID) {
                          return Container();
                        } else {
                          return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(myID)
                                  .collection('chatlist')
                                  .where('chatWith',
                                      isEqualTo: userData['userId'])
                                  .snapshots(),
                              builder: (context, chatListSnapshot) {
                                return chatListSnapshot.hasData &&
                                        chatListSnapshot.data!.docs.length > 0
                                    ? ListTile(
                                        leading: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            child: userData['photoUrl']
                                                    .isNotEmpty
                                                ? Image.network(
                                                    userData['photoUrl'],
                                                    fit: BoxFit.cover,
                                                    width: 50.0,
                                                    height: 50.0,
                                                    loadingBuilder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        width: 50,
                                                        height: 50,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            color: Colors.black,
                                                            value: loadingProgress
                                                                            .expectedTotalBytes !=
                                                                        null &&
                                                                    loadingProgress
                                                                            .expectedTotalBytes !=
                                                                        null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context,
                                                        object, stackTrace) {
                                                      return Icon(
                                                        Icons.account_circle,
                                                        size: 50.0,
                                                        color: Colors.grey,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.account_circle,
                                                    size: 50.0,
                                                    color: Colors.grey,
                                                  )),
                                        title: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                userData['userId'] == myID
                                                    ? "Pesan Tersimpan"
                                                    : userData['nickname'],
                                                maxLines: 1,
                                                style: TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ),
                                            Text(
                                              (chatListSnapshot.hasData &&
                                                      chatListSnapshot.data!
                                                              .docs.length >
                                                          0)
                                                  ? readTimestamp(
                                                      chatListSnapshot.data!
                                                          .docs[0]['timestamp'])
                                                  : '',
                                              style: TextStyle(
                                                  fontSize: size.width * 0.03),
                                            )
                                          ],
                                        ),
                                        subtitle: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            chatListSnapshot.data?.docs[0]
                                                        ['typeMessage'] ==
                                                    0
                                                ? Container()
                                                : chatListSnapshot.data?.docs[0]
                                                            ['typeMessage'] ==
                                                        1
                                                    ? Icon(
                                                        Icons.image,
                                                        color: Colors.grey,
                                                        size: 15,
                                                      )
                                                    : Icon(
                                                        Icons.sticky_note_2,
                                                        color: Colors.grey,
                                                        size: 15,
                                                      ),
                                            Expanded(
                                              child: Container(
                                                child: Text(
                                                  chatListSnapshot.data?.docs[0]
                                                              ['typeMessage'] ==
                                                          0
                                                      ? chatListSnapshot
                                                              .data?.docs[0]
                                                          ['contentMessage']
                                                      : chatListSnapshot.data
                                                                      ?.docs[0][
                                                                  'typeMessage'] ==
                                                              1
                                                          ? "Foto"
                                                          : "Stiker",
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                alignment: Alignment.centerLeft,
                                                margin: EdgeInsets.fromLTRB(
                                                    0.0, 0.0, 0.0, 0.0),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  10.0, 0.0, 0.0, 0.0),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 5, 0, 0),
                                                  child: CircleAvatar(
                                                    radius: 9,
                                                    child: Text(
                                                      chatListSnapshot.data!
                                                                      .docs[0][
                                                                  'badgeCount'] ==
                                                              null
                                                          ? ''
                                                          : ((chatListSnapshot
                                                                          .data!
                                                                          .docs[0]
                                                                      [
                                                                      'badgeCount'] !=
                                                                  0
                                                              ? '${chatListSnapshot.data!.docs[0]['badgeCount']}'
                                                              : '')),
                                                      style: TextStyle(
                                                          fontSize: 10),
                                                    ),
                                                    backgroundColor: chatListSnapshot
                                                                    .data!
                                                                    .docs[0][
                                                                'badgeCount'] ==
                                                            null
                                                        ? Colors.transparent
                                                        : (chatListSnapshot
                                                                        .data!
                                                                        .docs[0]
                                                                    [
                                                                    'badgeCount'] !=
                                                                0
                                                            ? Colors.red[400]
                                                            : Colors
                                                                .transparent),
                                                    foregroundColor:
                                                        Colors.white,
                                                  )),
                                            )
                                          ],
                                        ),
                                        onTap: () => _moveToChatRoom(
                                            userData['userId'],
                                            userData['nickname'],
                                            userData['photoUrl'],
                                            userData['FCMToken']),
                                      )
                                    : Container();
                              });
                        }
                      }).toList()),
                      LocalNotificationView().localNotificationCard(size)
                    ],
                  )
                : Container(
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.forum,
                          color: Colors.grey[700],
                          size: 64,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'There are no users except you.\nPlease use other devices to chat.',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )),
                  );
          }),
    );
  }
}
