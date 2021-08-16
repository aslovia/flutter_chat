import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/network/FirestoreCloud.dart';
import 'package:flutter_chat/widgets/ChatWidgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat/widgets/LocalNotificationWidgets.dart';

class ChatScreen extends StatefulWidget {
  final String myID,
      myName,
      myAvatar,
      selectedUserToken,
      selectedUserID,
      groupChatID,
      selectedUserName,
      selectedUserAvatar;

  ChatScreen(
      this.myID,
      this.myName,
      this.myAvatar,
      this.selectedUserToken,
      this.selectedUserID,
      this.groupChatID,
      this.selectedUserName,
      this.selectedUserAvatar);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  int _limit = 20;
  int _limitIncrement = 20;

  SharedPreferences? prefs;

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  bool isShowLocalNotification = false;

  // LocalNotificationData localNotificationData = LocalNotificationData(
  //   userImage : "",
  //   userName: "User Name",
  //   userMessage: "User Message",
  // );

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('didChangeAppLifecycleState');
    setState(() {
      switch (state) {
        case AppLifecycleState.resumed:
          FirestoreCloud.instanace
              .updateMyChatListValues(widget.myID, widget.groupChatID, true);
          print('AppLifecycleState.resumed');
          break;
        case AppLifecycleState.inactive:
          print('AppLifecycleState.inactive');
          FirestoreCloud.instanace
              .updateMyChatListValues(widget.myID, widget.groupChatID, false);
          break;
        case AppLifecycleState.paused:
          print('AppLifecycleState.paused');
          FirestoreCloud.instanace
              .updateMyChatListValues(widget.myID, widget.groupChatID, false);
          break;
        case AppLifecycleState.detached:
          // TODO: Handle this case.
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    WidgetsBinding.instance!.addObserver(this);
    FirestoreCloud.instanace
        .updateMyChatListValues(widget.myID, widget.groupChatID, true);

    if (mounted) {
      isShowLocalNotification = true;
      _savedChatId(widget.groupChatID);
      LocalNotificationView().checkLocalNotification(
          localNotificationAnimation, widget.groupChatID);
    }
  }

  void localNotificationAnimation(List<dynamic> data) {
    if (mounted) {
      setState(() {
        if (data[1] == 1.0) {
          LocalNotificationView().localNotificationData = data[0];
        }
        LocalNotificationView().localNotificationAnimationOpacity =
            data[1] as double;
      });
    }
  }

  @override
  void dispose() {
    isShowLocalNotification = false;
    FirestoreCloud.instanace
        .updateMyChatListValues(widget.myID, widget.groupChatID, false);
    _savedChatId("");
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Future<void> _savedChatId(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("inRoomChatId", value);
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedUserName,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              ChatWidgets().buildListMessage(
                  widget.groupChatID,
                  _limit,
                  listScrollController,
                  widget.selectedUserID,
                  widget.selectedUserAvatar,
                  widget.myID),

              // Sticker
              isShowSticker
                  ? ChatWidgets().buildSticker(onSendMessage)
                  : Container(),

              // Input content
              ChatWidgets().buildInput(context, _getImage, getSticker,
                  onSendMessage, textEditingController, focusNode)
            ],
          ),

          // Loading
          ChatWidgets().buildLoading(isLoading)
        ],
      ),
    );
  }

  void onSendMessage(String content, int type) async {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      await FirestoreCloud.instanace.updateUserChatListField(
          widget.selectedUserID,
          content,
          type,
          widget.groupChatID,
          widget.myID,
          widget.selectedUserID);
      await FirestoreCloud.instanace.updateUserChatListField(
          widget.myID,
          content,
          type,
          widget.groupChatID,
          widget.myID,
          widget.selectedUserID);
      await FirestoreCloud.instanace.sendMessageToChatRoom(widget.groupChatID,
          widget.myID, widget.selectedUserID, content, type);
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.black,
          textColor: Colors.red);
    }
  }

  Future _getImage(BuildContext context, ImageSource source) async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile;

    pickedFile = await imagePicker.getImage(source: source);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(imageFile!);

    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }
}
