import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:gymdo/trainings/select.dart';
import 'package:intl/intl.dart';
import 'sql.dart';
import 'package:gymdo/trainings/create.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class MPage extends StatefulWidget {
  @override
  _MPageState createState() => _MPageState();
}

class _MPageState extends State<MPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String names = '0';
  String currentTrainingName = 'No Training Selected'; // For training name
  List<Map<String, dynamic>> exercises =
      []; // List of exercises for the selected training
  String data = '', dia = '';
  List<bool> completed = [];
  List<bool> expandedList = [];
  bool trainingExpanded = false; // Track expanded state for training details
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

  void toggleTrainingExpanded() {
    setState(() {
      trainingExpanded =
          !trainingExpanded; // Toggle the training expanded state
    });
  }

  Future<List<Map<String, dynamic>>> query(String query) async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery(query);
    print(queryResult); // Log results for debugging
    return queryResult;
  }

  Future<void> initInfo() async {
    // Fetch user name
    List<Map<String, dynamic>> username = await query("SELECT Name FROM User");
    if (username.isNotEmpty) {
      setState(() {
        names = username[0]['Name'].toString();
      });
    }

    // Extract the weekday from data string
    String weekday =
        dia.toLowerCase(); // Convert to lowercase to match the database

    // Fetch the current training name and associated exercises
    List<Map<String, dynamic>> trainingData =
        await query("SELECT t.Name as TrainingName, e.* FROM Tr t "
            "LEFT JOIN Tr_Day td ON t.IdTr = td.CodTr "
            "LEFT JOIN Tr_Exer te ON t.IdTr = te.CodTr "
            "LEFT JOIN Exer e ON te.CodExer = e.IdExer "
            "WHERE LOWER(td.Day) = '$weekday'");

    if (trainingData.isNotEmpty) {
      setState(() {
        currentTrainingName = trainingData[0]['TrainingName'];
        exercises = trainingData; // Store the exercises related to the training
        completed = List.generate(exercises.length, (_) => false);
        expandedList = List.generate(exercises.length, (_) => false);
      });
    } else {
      // Handle the case when there are no training data
      setState(() {
        currentTrainingName = 'No Training Selected'; // Keep the message
        exercises.clear(); // Clear exercises if no data
        completed.clear(); // Clear completed list
        expandedList.clear(); // Clear expanded list
      });
    }
  }

  @override
  void initState() {
    super.initState();
    data = DateFormat('d', 'pt_BR').format(now).toString();
    dia = DateFormat('EEEE', 'pt_BR').format(now).toString();
    initInfo();
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
          // Training Name is now below the date and chronometer card
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
                                icon: const Icon(Icons.play_arrow),
                                onPressed: _startTimer,
                                color: Colors.white,
                              ),
                              IconButton(
                                icon: const Icon(Icons.pause),
                                onPressed: _stopTimer,
                                color: Colors.red,
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop),
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

          // Display the "No Training Selected" message below the date and chronometer card
          if (currentTrainingName == 'No Training Selected')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'No Training Selected',
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          // Training card with exercises
          if (currentTrainingName != 'No Training Selected')
            Card(
              color: Color.fromARGB(255, 48, 48, 48),
              elevation: 1,
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      currentTrainingName,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: Icon(trainingExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: toggleTrainingExpanded,
                    ),
                  ),
                  if (trainingExpanded) // Show exercises if expanded
                    Column(
                      children: List.generate(exercises.length, (index) {
                        return Card(
                          color: Color.fromARGB(
                              255, 60, 60, 60), // Card color for exercises
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  exercises[index]['Name'] ?? 'Exercise',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Details for ${exercises[index]['Name']}', // Replace with actual details if available
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: Checkbox(
                                  value: completed[index],
                                  onChanged: (value) {
                                    changeValue(value!, index);
                                  },
                                ),
                              ),
                              if (expandedList[
                                  index]) // Show additional details if expanded
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Additional details about ${exercises[index]['Name']}',
                                  ),
                                ),
                              // Details Button for each exercise
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
                        );
                      }),
                    ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    // This is removed since exercises will now be in the training card
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8.0,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Add Training',
            backgroundColor: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CPage(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.edit),
            label: 'Edit',
            backgroundColor: Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CPage(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.visibility),
            label: 'See All Trainings',
            backgroundColor: Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
