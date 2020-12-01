import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class Check extends StatefulWidget {
  @override
  _CheckState createState() => _CheckState();
}

class _CheckState extends State<Check> {

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

  String _uniqueIdentifier = '';

  String receivedNotification;

  Future<String> _token;

  final String baseUrl = (kReleaseMode) ? 'https://drugs.shaheermirza.dev/' : 'http://192.168.0.2:8000/';

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

    _token = _firebaseMessaging.getToken().then((token) {
      assert(token != null);
      print('Token: $token');

      return token;
    });

    // _prefs.then((SharedPreferences prefs) {
    //   final String phone = prefs.get(phoneKey) ?? 'None';
    //   final String name = prefs.get(nameKey) ?? 'None';
    //   final String ivrcode = prefs.get(codeKey) ?? 'None';

    //   if (phone == 'None' || name == 'None' || ivrcode == 'None') {
    //     setState(() {
    //       _editing = true;
    //     });
    //   } else {
    //     _phoneController = TextEditingController(text: phone);
    //     _nameController = TextEditingController(text: name);
    //     _ivrcodeController = TextEditingController(text: ivrcode);
    //   }
    // });
    
    _phone = _prefs.then((SharedPreferences prefs) {
      var phone = prefs.get(phoneKey) ?? 'None';
      if (phone == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _phoneController = TextEditingController(text: phone);
      }

      return phone;
    });

    _name = _prefs.then((SharedPreferences prefs) {
      var name = prefs.get(nameKey) ?? 'None';

      if (name == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _nameController = TextEditingController(text: name);
      }

      return name;
    });

    _ivrcode = _prefs.then((SharedPreferences prefs) {
      var ivrCode = prefs.get(codeKey) ?? 'None';

      if (ivrCode == 'None') {
        setState(() {
          _editing = true;
        });
      } else {
        _ivrcodeController = TextEditingController(text: ivrCode);
      }

      return ivrCode;
    });

    // _phone.then((phone) {
    //   if (phone == 'None') {
    //     setState(() {
    //       _editing = true;
    //     });
    //   } else {
    //     _phoneController = TextEditingController(text: phone);
    //   }
    // });

    // _name.then((name) {
    //   if (name == 'None') {
    //     setState(() {
    //       _editing = true;
    //     });
    //   } else {
    //     _nameController = TextEditingController(text: name);
    //   }
    // });

    // _ivrcode.then((ivrcode) {
    //   if (ivrcode == 'None') {
    //     setState(() {
    //       _editing = true;
    //     });
    //   } else {
    //     _ivrcodeController = TextEditingController(text: ivrcode);
    //   }
    // });
    getDeviceDetails().then((identifier) {
      setState(() {
        notificationString = identifier;
        _uniqueIdentifier = identifier;
      });
      print('checking');
      checkUserForUpdates();
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
    String url = baseUrl + 'users/';

    String json = convert.jsonEncode({
      'phone' : phone,
      'last_name' : name,
      'ivr_code' : ivrcode,
      'token': await _token,
      // 'token' : 'hello',
      'identifier': this._uniqueIdentifier
    });
    print(json);

    final response = await http.post(url, body: json, headers: {
      'Content-Type': 'application/json'
    });

    if (response.statusCode == 200) {
      print('success');
    } else {
      // Record already exists in DB, so replace the token in the DB
      print('here');

      final existing = await http.get(url + '?search=$_uniqueIdentifier');
      var id = convert.jsonDecode(existing.body)[0]['identifier'];

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
    await checkUserForUpdates();
    String url = baseUrl + 'check/';

    String json = convert.jsonEncode({
      'phone' : phone,
      'last_name' : name,
      'ivr_code' : ivrcode,
      'token': await _token,
      'identifier': _uniqueIdentifier
    });

    var request = await http.post(url, body: json, headers: {
      'Content-Type': 'application/json'
    });

    if (request.statusCode == 200) {
      var response = convert.jsonDecode(request.body);
      print(response);
    }

  }

  Future<void> checkUserForUpdates() async {
    final String phone = _phoneController.text ?? 'None';
    final String name = _nameController.text ?? 'None';
    final String ivrCode = _ivrcodeController.text ?? 'None';

    try {
      final request = await http.get(baseUrl + 'users/?search=$_uniqueIdentifier', headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      });

      if (request.statusCode == 200) {
        var response = convert.jsonDecode(request.body) as List;
        print('found $response');
        
        String thisToken = await _token;
        if (response != null && response.length > 0) {
          if (response[0]['token'] != thisToken) {
            print(thisToken);
            final putResponse = await http.put(baseUrl + 'users/$_uniqueIdentifier/', body: generateJson(phone, name, ivrCode, thisToken), headers: {
              'Content-Type': 'application/json'
            });

            if (putResponse.statusCode == 200) {
              print('update success');
            } else {
              print ('update fail');
            }
          }
        }
        else if (response.length == 0) {
          post(phone, name, ivrCode);
        }
        else {
          print(response);
        }
      } else {
        print('nothing found');
      }
    } catch (exception) {
      print(exception);
      return;
    }
  }

  String generateJson(String phone, String name, String ivrCode, String token) {
    String json = convert.jsonEncode({
      'phone' : phone,
      'last_name' : name,
      'ivr_code' : ivrCode,
      'token': token,
      'identifier': _uniqueIdentifier
    });

    return json;
  }


  static Future<String> getDeviceDetails() async {
    String identifier;
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        identifier = build.androidId;
      }
      else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        identifier = data.identifierForVendor;
      }
    } on PlatformException {
      print('Failed to get platform version');
    }

    return identifier;
  }
}