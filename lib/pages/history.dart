import 'dart:async';

import 'package:DrugNotify/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final String url = (kReleaseMode)
      ? 'https://drugnotify.herokuapp.com/'
      : 'http://192.168.0.19:8000/';
  String _identifier;

  // static Widget _testIcon = Container(
  //   decoration: new BoxDecoration(
  //     color: Color(0xFFD64045).withAlpha(225)
  //   ),
  // );

  Future fetchHistory() async {
    final response = await http.get(url + '?search=$_identifier', headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });

    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body) as List;
    } else {
      throw Exception('Failed to load history');
    }
  }

  loadHistory() async {
    fetchHistory().then((res) async {
      EventList<Event> datesChecked = EventList();
      for (var s in res) {
        print(s);
        bool testing = s['testing'];
        if (testing) {
          String dateString = s['date_checked'];
          DateTime date = DateFormat('yyyy-MM-dd').parse(dateString);
          datesChecked.add(
              date,
              Event(
                  date: date,
                  title: 'No',
                  icon: Container(
                    decoration: new BoxDecoration(
                        color: Color(0xFFD64045).withAlpha(225)),
                  )));
        }
      }

      setState(() {
        _markedDateMap = datesChecked;
        print('set');
      });
      return res;
    });
  }

  showSnack() {
    return scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text('New Content Loaded'),
      ),
    );
  }

  Future<Null> _handleRefresh() async {
    fetchHistory().then((res) async {
      EventList<Event> datesChecked = EventList();
      for (var s in res) {
        print(s);
        bool testing = s['testing'];
        if (testing) {
          String dateString = s['date_checked'];
          DateTime date = DateFormat('yyyy-MM-dd').parse(dateString);
          datesChecked.add(
              date,
              Event(
                  date: date,
                  title: 'No',
                  icon: Container(
                    decoration: new BoxDecoration(
                        color: Color(0xFFD64045).withAlpha(225)),
                  )));
        }
      }

      setState(() {
        _markedDateMap = datesChecked;
        for (var v in _markedDateMap.events.keys) {
          List<Event> e = _markedDateMap.getEvents(v);
          for (var s in e) {
            print('$v - $s');
          }
        }
      });
      showSnack();
      return null;
    });
  }

  @override
  void initState() {
    getDeviceDetails().then((id) {
      setState(() {
        _identifier = id;
      });
      loadHistory();
    });

    super.initState();
  }

  CalendarCarousel _calendarCarousel;
  EventList<Event> _markedDateMap;
  DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    _calendarCarousel = CalendarCarousel<Event>(
      onDayPressed: (DateTime date, List<Event> events) {
        this.setState(() => _currentDate = date);
        events.forEach((event) => print(event.title));
      },

      showOnlyCurrentMonthDate: false,
      markedDatesMap: _markedDateMap,
      height: 420.0,
      selectedDateTime: _currentDate,
      showIconBehindDayText: true,
      customGridViewPhysics: NeverScrollableScrollPhysics(),
      pageScrollPhysics: ClampingScrollPhysics(),
      markedDateShowIcon: true,

      iconColor: Theme.of(context).accentColor,
      pageSnapping: true,
      nextDaysTextStyle: TextStyle(
        color: Colors.grey,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),

      prevDaysTextStyle: TextStyle(
        color: Colors.grey,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),

      daysTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
      // markedDateMoreShowTotal: null,
      // markedDateCustomTextStyle: ,
      markedDateIconBuilder: (event) {
        return event.icon;
      },

      markedDateCustomTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),

      weekdayTextStyle: TextStyle(
        color: Theme.of(context).accentColor,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),

      headerTextStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 28,
        fontWeight: FontWeight.w300,
      ),

      weekendTextStyle: TextStyle(
        color: Theme.of(context).accentColor,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),

      selectedDayTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
      selectedDayButtonColor: Colors.amber,

      todayTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
      todayButtonColor: Colors.transparent,
      todayBorderColor: Colors.transparent,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: CustomClampScrollPhysics(),
          child: Container(
            child: Column(
              children: [_calendarCarousel],
            ),
            height: MediaQuery.of(context).size.height,
          ),
        ),
      ),
    );
  }
}
