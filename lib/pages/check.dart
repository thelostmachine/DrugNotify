import 'package:DrugNotify/utils/server.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class Check extends StatefulWidget {
  @override
  _CheckState createState() => _CheckState();
}

class _CheckState extends State<Check> {
  String notificationString = 'No Data Available. Wait until 6am';

  String receivedNotification;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print(
            'Message also contained a notification: ${message.notification.body}');

        setState(() {
          notificationString = message.notification.body;
        });
      }
    });

    UserData.instance.checkForTokenUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome!')),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 70, vertical: 70),
          child: Center(
            child: savedInfo(),
          ),
        ),
      ),
    );
  }

  Widget savedInfo() {
    return Column(
      children: [
        Text(
          notificationString,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Drug Testing Phone', style: TextStyle(fontSize: 16)),
            Text(UserData.instance.getPhone()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('First Name', style: TextStyle(fontSize: 16)),
            Text(UserData.instance.getFirstName()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Last Name', style: TextStyle(fontSize: 16)),
            Text(UserData.instance.getLastName()),
          ],
        ),
        SizedBox(height: 30),
        Center(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                notificationString = "Checking...";
              });
              UserData.instance.test();
            },
            child: Text('Check'),
          ),
        ),
      ],
    );
  }
}
