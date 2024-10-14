import 'dart:async'; // For Timer
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sql.dart';
import 'package:gymdo/create.dart';

class MPage extends StatefulWidget {
  @override
  _MPageState createState() => _MPageState();
}

class _MPageState extends State<MPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String names = '0';
  dynamic exercises = 0;
  String data = '', dia = '', obj = 'Cardio';
  List<int> cards = [];
  List<bool> completed = [];
  List<bool> expandedList = [];
  DateTime now = DateTime.now();

  // Variables for chronometer with centiseconds (SS)
  Timer? _timer;
  int _elapsedMilliseconds = 0;
  bool _isRunning = false;

  void changeValue(bool value, int index) {
    setState(() {
      completed[index] = value;
      expandedList[index] = false;
    });
  }

  void changeExpanded(bool value, int index) {
    setState(() {
      expandedList[index] = value;
    });
  }

  Future<List<Map<String, dynamic>>> query(String query) async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery(query);
    print(queryResult);
    return queryResult;
  }

  Future<void> initInfo() async {
    List<Map<String, dynamic>> username = await query("select name from user");
    setState(() {
      for (var result in username) {
        names = result['name'].toString();
        print(result['name']);
      }
    });

    exercises = await query(
        "select * from Exer e, Dias d where e.coddia=d.iddia and d.name='$dia'");

    print(exercises);
  }

  @override
  void initState() {
    super.initState();
    data = DateFormat('d', 'pt_BR').format(now).toString();
    dia = DateFormat('EEEE', 'pt_BR').format(now).toString();

    initInfo();

    cards.add(0);
    completed.add(false);
    expandedList.add(false);
    cards.add(0);
    completed.add(false);
    expandedList.add(false);
  }

  // Chronometer logic with centiseconds (SS)
  void _startTimer() {
    if (!_isRunning) {
      _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
        setState(() {
          _elapsedMilliseconds += 10; // Increment by 10 milliseconds
        });
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsedMilliseconds = 0;
    });
  }

  // Time formatter in mm:ss:SS format
  String get _formattedTime {
    final minutes = (_elapsedMilliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds =
        ((_elapsedMilliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centiseconds =
        ((_elapsedMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return "$minutes:$seconds:$centiseconds";
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _textFieldController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Text(
          names.isNotEmpty ? 'Olá ${names}' : 'Olá',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        titleSpacing: 10.0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            width: MediaQuery.of(context).size.width - 10,
            child: Card(
              color: Color.fromARGB(255, 48, 48, 48),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Card(
                            color: Colors.white,
                            elevation: 3,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height / 7,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    data,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50.0,
                                    ),
                                  ),
                                  Text(dia),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 25,
                    ),

                    // Chronometer Card
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Card(
                            elevation: 3,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height / 14,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formattedTime,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24.0,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.play_arrow),
                                onPressed: _startTimer,
                                color: Colors.white,
                              ),
                              IconButton(
                                icon: Icon(Icons.pause),
                                onPressed: _stopTimer,
                                color: Colors.red,
                              ),
                              IconButton(
                                icon: Icon(Icons.stop),
                                onPressed: _resetTimer,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Card(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 5),
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.black,
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 25),
                              const Text(
                                'Seated Row',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Checkbox(
                                value: completed[index],
                                onChanged: (value) {
                                  changeValue(value!, index);
                                },
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: Icon(expandedList[index]
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                onPressed: () {
                                  changeExpanded(!expandedList[index], index);
                                },
                              ),
                            ],
                          ),
                          if (expandedList[index])
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              child: const Column(
                                children: [
                                  Text('Additional details about Seated Row'),
                                  // Add more detailed information here
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CPage(),
            ),
          );
        },
        child: Icon(Icons.edit),
      ),
    );
  }
}
