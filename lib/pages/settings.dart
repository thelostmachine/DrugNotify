import 'package:DrugNotify/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  TextEditingController _phoneController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _ivrcodeController = TextEditingController();

  final String _phoneKey = 'phone';
  final String _firstNameKey = 'firstname';
  final String _lastNameKey = 'lastname';
  final String _codeKey = 'ivrcode';
  final String _morningKey = 'notifyMorning';
  final String _noonKey = 'notifyNoon';
  final String _tokenKey = 'fcmToken';

  String _phone, _firstName, _lastName, _ivrCode, _fcmToken;
  bool _notifyMorning, _notifyNoon;

  bool _pendingMorningNotify, _pendingNoonNotify;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    _phoneController.addListener(() {
      checkDirty();
    });

    _firstNameController.addListener(() {
      checkDirty();
    });

    _lastNameController.addListener(() {
      checkDirty();
    });

    _ivrcodeController.addListener(() {
      checkDirty();
    });
  }

  void _loadPrefs() async {
    SharedPreferences prefs = await _preferences;
    String tempToken = await FirebaseMessaging.instance.getToken();

    setState(() {
      _phone = prefs.getString(_phoneKey);
      _firstName = prefs.getString(_firstNameKey);
      _lastName = prefs.getString(_lastNameKey);
      _ivrCode = prefs.getString(_codeKey);
      _notifyMorning = prefs.getBool(_morningKey) ?? true;
      _notifyNoon = prefs.getBool(_noonKey) ?? true;

      _fcmToken = prefs.getString(_tokenKey) ?? tempToken;

      _firstNameController.text = _firstName;
      _lastNameController.text = _lastName;
      _phoneController.text = _phone;
      _ivrcodeController.text = _ivrCode;
      _pendingMorningNotify = _notifyMorning;
      _pendingNoonNotify = _notifyNoon;
    });

    checkDirty();
  }

  void checkDirty() {
    if (_firstNameController.text != _firstName ||
        _lastNameController.text != _lastName ||
        _phoneController.text != _phone ||
        _ivrcodeController.text != _ivrCode ||
        _pendingMorningNotify != _notifyMorning ||
        _pendingNoonNotify != _notifyNoon) {
      setState(() {
        _isDirty = true;
      });
    } else {
      setState(() {
        _isDirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('First Name'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'First Name',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('Last Name'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Last Name',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('Drug Testing Phone Number'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        // phone formatter
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Phone Number',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('ID Number'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ivrcodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'ID Number',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('8 AM'),
                  ),
                  Switch(
                    value: _pendingMorningNotify,
                    onChanged: (value) {
                      setState(() {
                        _pendingMorningNotify = value;

                        checkDirty();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text('12 PM'),
                  ),
                  Switch(
                    value: _pendingNoonNotify,
                    onChanged: (value) {
                      setState(() {
                        _pendingNoonNotify = value;

                        checkDirty();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: !_isDirty
                      ? null
                      : () {
                          print('saving');
                          save(context);
                        },
                  child: Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  bool validateInputs() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _ivrcodeController.text.isNotEmpty;
  }

  void save(BuildContext context) async {
    if (!validateInputs()) {
      final snackBar = SnackBar(
          content: Text('Data cannot be empty'),
          action: SnackBarAction(
            label: 'Fix',
            onPressed: () {},
          ));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final SharedPreferences prefs = await _preferences;

      prefs.setString(_phoneKey, _phoneController.text).then((success) {
        setState(() {
          _phone = _phoneController.text;
        });
      });

      prefs.setString(_firstNameKey, _firstNameController.text).then((success) {
        setState(() {
          _firstName = _firstNameController.text;
        });
      });

      prefs.setString(_lastNameKey, _lastNameController.text).then((success) {
        setState(() {
          _lastName = _lastNameController.text;
        });
      });

      prefs.setString(_codeKey, _ivrcodeController.text).then((success) {
        setState(() {
          _ivrCode = _ivrcodeController.text;
        });
      });

      prefs.setBool(_morningKey, _pendingMorningNotify).then((success) {
        setState(() {
          _notifyMorning = _pendingMorningNotify;
        });
      });

      prefs.setBool(_noonKey, _pendingNoonNotify).then((success) {
        setState(() {
          _notifyNoon = _pendingNoonNotify;
        });
      });

      updateDB();
      setState(() {
        _isDirty = false;
      });
    }
  }

  void updateDB() async {
    String url = '$baseUrl/users';

    String identifier = await getDeviceDetails();

    String json = convert.jsonEncode({
      'phone': _phone,
      'first_name': _firstName,
      'last_name': _lastName,
      'ivr_code': _ivrCode,
      'identifier': identifier,
      'token': _fcmToken,
      'notify_morning': _pendingMorningNotify,
      'notify_noon': _pendingNoonNotify,
    });

    final response = await http.post('$url/',
        body: json, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      print('Successfully added user to DB');
    } else {
      print('User already exists');

      final putResponse = await http.put('$url/$identifier/',
          body: json, headers: {'Content-Type': 'application/json'});

      if (putResponse.statusCode == 200) {
        print('Successfully updated user');
      } else {
        print('Failed to update user');
      }
    }
  }
}
