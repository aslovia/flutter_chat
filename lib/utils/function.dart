// For Chat List Functions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String makeGroupChatID(myID,selectedUserID) {
  String groupChatID;
  if (myID.hashCode <= selectedUserID.hashCode) {
    groupChatID = '$myID-$selectedUserID';
  } else {
    groupChatID = '$selectedUserID-$myID';
  }
  return groupChatID;
}

int countChatListUsers(myID,AsyncSnapshot<QuerySnapshot> snapshot) {
  int resultInt = snapshot.data!.docs.length;
  for (var data in snapshot.data!.docs) {
    if (data['userId'] == myID) {
      resultInt--;
    }
  }
  return resultInt;
}

String readTimestamp(int timestamp) {
  var now = DateTime.now();
  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
    if (diff.inHours > 0) {
      time = diff.inHours.toString() + 'h ago';
    }else if (diff.inMinutes > 0) {
      time = diff.inMinutes.toString() + 'm ago';
    }else if (diff.inSeconds > 0) {
      time = 'now';
    }else if (diff.inMilliseconds > 0) {
      time = 'now';
    }else if (diff.inMicroseconds > 0) {
      time = 'now';
    }else {
      time = 'now';
    }
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    time = diff.inDays.toString() + 'd ago';
  } else if (diff.inDays > 6){
    time = (diff.inDays / 7).floor().toString() + 'w ago';
  }else if (diff.inDays > 29) {
    time = (diff.inDays / 30).floor().toString() + 'm ago';
  }else if (diff.inDays > 365) {
    time = '${date.month}-${date.day}-${date.year}';
  }
  return time;
}