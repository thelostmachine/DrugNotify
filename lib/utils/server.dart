import 'package:DrugNotify/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class UserData {
  final String _phoneKey = 'phone';
  final String _firstNameKey = 'firstname';
  final String _lastNameKey = 'lastname';
  final String _codeKey = 'ivrcode';
  final String _morningKey = 'notifyMorning';
  final String _noonKey = 'notifyNoon';
  final String _tokenKey = 'fcmToken';

  String _phone, _firstName, _lastName, _ivrCode, _fcmToken;
  bool _notifyMorning, _notifyNoon;

  Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  static final UserData _singleton = UserData._internal();

  UserData._internal();

  static UserData get instance => _singleton;

  Future<void> loadPrefs() async {
    SharedPreferences prefs = await _preferences;
    String tempToken = await FirebaseMessaging.instance.getToken();

    _phone = prefs.getString(_phoneKey) ?? 'None';
    _firstName = prefs.getString(_firstNameKey) ?? 'None';
    _lastName = prefs.getString(_lastNameKey) ?? 'None';
    _ivrCode = prefs.getString(_codeKey) ?? 'None';
    _notifyMorning = prefs.getBool(_morningKey) ?? true;
    _notifyNoon = prefs.getBool(_noonKey) ?? true;

    _fcmToken = prefs.getString(_fcmToken) ?? tempToken;
  }

  String getPhone() {
    return _phone;
  }

  String getFirstName() {
    return _firstName;
  }

  String getLastName() {
    return _lastName;
  }

  String getIvrCode() {
    return _ivrCode;
  }

  bool mustInitialize() {
    if (_phone == 'None' ||
        _firstName == 'None' ||
        _lastName == 'None' ||
        _ivrCode == 'None') {
      return true;
    }

    return false;
  }

  void savePrefs(
      {String newPhone,
      String newFirst,
      String newLast,
      String newCode,
      bool newMorning = null,
      bool newNoon = null,
      String newToken}) async {
    final SharedPreferences prefs = await _preferences;

    if (newPhone.isNotEmpty) {
      prefs.setString(_phoneKey, newPhone).then((success) {
        _phone = newPhone;
      });
    }

    if (newFirst.isNotEmpty) {
      prefs.setString(_firstNameKey, newFirst).then((success) {
        _firstName = newFirst;
      });
    }

    if (newLast.isNotEmpty) {
      prefs.setString(_lastNameKey, newLast).then((success) {
        _lastName = newLast;
      });
    }

    if (newCode.isNotEmpty) {
      prefs.setString(_codeKey, newCode).then((success) {
        _ivrCode = newCode;
      });
    }

    if (newMorning != null) {
      prefs.setBool(_morningKey, newMorning).then((success) {
        _notifyMorning = newMorning;
      });
    }

    if (newNoon != null) {
      prefs.setBool(_noonKey, newNoon).then((success) {
        _notifyNoon = newNoon;
      });
    }

    if (newToken.isNotEmpty) {
      prefs.setString(_tokenKey, newToken).then((success) {
        _fcmToken = newToken;
      });
    }

    updateDB();
  }

  void checkForTokenUpdate() async {
    String tempToken = await FirebaseMessaging.instance.getToken();

    if (_fcmToken != tempToken) {
      savePrefs(newToken: tempToken);
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
      'notify_morning': _notifyMorning,
      'notify_noon': _notifyNoon,
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

  void test() async {
    String identifier = await getDeviceDetails();
    String url = '$baseUrl/check/';

    String json = convert.jsonEncode({
      'phone': _phone,
      'first_name': _firstName,
      'last_name': _lastName,
      'ivr_code': _ivrCode,
      'token': _fcmToken,
      'identifier': identifier,
    });

    var request = await http
        .post(url, body: json, headers: {'Content-Type': 'application/json'});

    if (request.statusCode == 200) {
      var response = convert.jsonDecode(request.body);
      print('here');
      print(response);
    }
  }
}
