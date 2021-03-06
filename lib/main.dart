// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:DrugNotify/pages/check.dart';
import 'package:DrugNotify/pages/history.dart';
import 'package:DrugNotify/pages/home.dart';
import 'package:DrugNotify/pages/settings.dart';
import 'package:DrugNotify/utils/server.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: true,
  );

  await UserData.instance.loadPrefs();
  int startingIndex = 0;

  if (UserData.instance.mustInitialize()) {
    startingIndex = 2;
  }

  runApp(
    MaterialApp(
      initialRoute: '/home',
      routes: {
        '/home': (context) => Home(startingIndex: startingIndex),
        '/check': (context) => Check(),
        '/history': (context) => HistoryPage(),
        '/settings': (context) => SettingsPage(),
      },
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primaryTextTheme: TextTheme(
          headline6: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w200,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: Color(0xFFE8EDDF),
        primaryColor: Color(0xFF134611),
        accentColor: Color(0xFFD64045),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFD64045),
          unselectedItemColor: Color(0x66E8EDDF),
          backgroundColor: Color(0xFF134611),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF134611),
            padding: const EdgeInsets.all(10),
            onPrimary: Colors.white,
          ),
        ),
      ),
    ),
  );
}
