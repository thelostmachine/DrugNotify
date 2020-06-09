import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future<String> _phone;
  Future<String> _name;
  Future<String> _ivrcode;

  TextEditingController _phoneController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ivrcodeController = TextEditingController();

  bool _editing = false;

  // final phoneFormatter = _UsNumberTextInputFormatter();

  final String phoneKey = 'phone';
  final String nameKey = 'name';
  final String codeKey = 'ivrcode';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  String notificationString = 'No Data Available. Wait until 6am';

  String receivedNotification;

  String token;

  @override
  void initState() {
    super.initState();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        receivedNotification = message['aps']['alert']['body'];
        print('message');
        setState(() {
          notificationString = receivedNotification;
        });
      },
      onResume: (Map<String, dynamic> message) async {
        receivedNotification = message['aps']['alert']['body'];
        print('resume');
        print(receivedNotification);
        setState(() {
          notificationString = receivedNotification;
        });
      },
      onLaunch: (Map<String, dynamic> message) async {
        receivedNotification = message['aps']['alert']['body'];
        print('launch');
        print(receivedNotification);
        setState(() {
          notificationString = receivedNotification;
        });
      }
    );

    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
        provisional: true
      )
    );

    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print('Settings registered: $settings');
    });

    _firebaseMessaging.getToken().then((token) {
      assert(token != null);
      print('Token: $token');

      setState(() {
        this.token = token;
      });

    });

    _phone = _prefs.then((SharedPreferences prefs) {
      return prefs.get(phoneKey) ?? 'None';
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.get(nameKey) ?? 'None';
    });

    _ivrcode = _prefs.then((SharedPreferences prefs) {
      return prefs.get(codeKey) ?? 'None';
    });

    _phone.then((phone) {
      if (phone == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _phoneController = TextEditingController(text: phone);
      }
    });

    _name.then((name) {
      if (name == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _nameController = TextEditingController(text: name);
      }
    });

    _ivrcode.then((ivrcode) {
      if (ivrcode == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _ivrcodeController = TextEditingController(text: ivrcode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome!')
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 70,
            vertical: 70
          ),
          child: Center(
            child: Column(
              children: [
                
                // Expanded(
                  // child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // children: [
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        firstChild: savedInfo(),
                        secondChild: editInfo(),
                        crossFadeState: _editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      )
                    // ],
                  // )
                // )
              ]
            )
          )
        )
      )
    );
  }

  Widget getPref(Future<String> pref) {
    return FutureBuilder<String>(
      future: pref,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          default:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(
                snapshot.data
              );
            }
        }
      },
    );
  }

  Widget button() {
    return RaisedButton(
      onPressed: () {
        if (_editing) {
          save();
        }

        FocusScope.of(context).unfocus();

        setState(() {
          _editing = !_editing;
        });
      },
      padding: const EdgeInsets.all(10),
      color: Colors.blue,
      textColor: Colors.white,
      child: Text(_editing ? 'Save' : 'Edit')
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
          )
        ),
        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Drug Testing Phone',
              style: TextStyle(fontSize: 16)
            ),
            getPref(_phone)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last Name',
              style: TextStyle(fontSize: 16)
            ),
            getPref(_name)
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ID Number',
              style: TextStyle(fontSize: 16)),
            getPref(_ivrcode)
          ],
        ),
        SizedBox(height: 140),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RaisedButton(
              onPressed: () {
                setState(() {
                  notificationString = "Checking...";
                });
                test(_phoneController.text, _nameController.text, _ivrcodeController.text);
              },
              padding: const EdgeInsets.all(10),
              color: Colors.blue,
              textColor: Colors.white,
              child: Text('Check')
            ),
            button()
          ],
        )
      ],
    );
  }

  Widget editInfo() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            // phoneFormatter
          ],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Drug Testing Phone Number'
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Last Name'
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _ivrcodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'ID Number'
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RaisedButton(
              onPressed: () {
                
                FocusScope.of(context).unfocus();

                setState(() {
                  _editing = !_editing;
                });
              },
              padding: const EdgeInsets.all(10),
              color: Colors.blue,
              textColor: Colors.white,
              child: Text('Cancel')
            ),
            button()
          ],
        )
      ]
    );
  }

  void save() async {
    final SharedPreferences prefs = await _prefs;
    final String phone = _phoneController.text ?? 'None';
    final String name = _nameController.text ?? 'None';
    final String ivrcode = _ivrcodeController.text ?? 'None';

    setState(() {
      _phone = prefs.setString(phoneKey, phone).then((success) {
        return phone;
      });

      _name = prefs.setString(nameKey, name).then((success) {
        return name;
      });

      _ivrcode = prefs.setString(codeKey, ivrcode).then((success) {
        return ivrcode;
      });
    });

    post(phone, name, ivrcode);
  }

  void post(String phone, String name, String ivrcode) async {
    String url = 'https://drugs.shaheermirza.dev/users/';

    String json = convert.jsonEncode({
      'phone' : phone,
      'last_name' : name,
      'ivr_code' : ivrcode,
      'token': this.token
    });

    final response = await http.post(url, body: json, headers: {
      'Content-Type': 'application/json'
    });

    if (response.statusCode == 200) {
      print('success');
    } else {
      final existing = await http.get(url + '?search=$token');
      var id = convert.jsonDecode(existing.body)[0]['id'];

      final putResponse = await http.put(url + '$id/', body: json, headers: {
        'Content-Type': 'application/json'
      });

      if (putResponse.statusCode == 200) {
        print('success');
      } else {
        print('failed to update');
      }
    }
  }

  void test(String phone, String name, String ivrcode) async {
    String url = 'https://drugs.shaheermirza.dev/test/';

    String json = convert.jsonEncode({
      'phone' : phone,
      'last_name' : name,
      'ivr_code' : ivrcode,
      'token': this.token
    });

    http.post(url, body: json, headers: {
      'Content-Type': 'application/json'
    });
  }
}

/// Format incoming numeric text to fit the format of (###) ###-#### ##...
class _UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue
  ) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;
    final StringBuffer newText = StringBuffer();
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1)
        selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
      if (newValue.selection.end >= 3)
        selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
      if (newValue.selection.end >= 6)
        selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
      if (newValue.selection.end >= 10)
        selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex)
      newText.write(newValue.text.substring(usedSubstringIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}