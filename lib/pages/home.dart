import 'dart:io';

import 'package:DrugNotify/pages/check.dart';
import 'package:DrugNotify/pages/history.dart';
import 'package:DrugNotify/pages/settings.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final int startingIndex;

  Home({this.startingIndex = 0});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex;
  final List<Widget> _children = [
    Check(),
    HistoryPage(),
    SettingsPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.startingIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
          onTap: () {
            if (Platform.isIOS) {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus &&
                  currentFocus.focusedChild != null) {
                FocusManager.instance.primaryFocus.unfocus();
              }
            }
          },
          // child: _children[_currentIndex],
          child: IndexedStack(
            children: _children,
            index: _currentIndex,
          )),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.medical_services,
            ),
            label: 'Check',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          )
        ],
      ),
    );
  }
}
