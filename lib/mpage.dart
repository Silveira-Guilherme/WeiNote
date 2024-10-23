// ignore_for_file: library_private_types_in_public_api

import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:gymdo/trainings/edit.dart';
import 'package:gymdo/trainings/select.dart';
import 'package:gymdo/trainings/trainings.dart';
import 'package:intl/intl.dart';
import 'sql.dart';
import 'package:gymdo/trainings/create.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/trainings/trainings.dart' as tr;

class MPage extends StatefulWidget {
  @override
  _MPageState createState() => _MPageState();
}

class _MPageState extends State<MPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String names = 'User'; // Default name if none is fetched
  String dateStr = '', dayStr = '';

  // Replace this with a list of Training objects
  List<tr.Training> trainings = [];
  DateTime now = DateTime.now();

  // Chronometer variables
  Timer? _timer;
  int _elapsedMilliseconds = 0;
  bool _isRunning = false;

  Future<List<Map<String, dynamic>>> query(String query) async {
    return await dbHelper.customQuery(query);
  }

  Future<void> initInfo() async {
    // Fetch user name
    List<Map<String, dynamic>> username = await query("SELECT Name FROM User");
    names = username.isNotEmpty
        ? username[0]['Name']?.toString() ?? 'User'
        : 'User';

    // Extract the weekday
    dayStr = DateFormat('EEEE', 'pt_BR').format(now).toLowerCase();

    // Fetch the current training name, associated exercises, and days
    List<dynamic> trainingData = await query("""
    SELECT 
      t.IdTr,          -- Fetching Training ID
      t.Name as TrainingName, 
      e.IdExer,        -- Fetching Exercise ID
      e.Name as ExerciseName, 
      s.Peso, 
      s.Rep,
      td.Day as TrainingDay -- Fetching the day of training
    FROM 
      Tr t 
    LEFT JOIN 
      Tr_Day td ON t.IdTr = td.CodTr 
    LEFT JOIN 
      Tr_Exer te ON t.IdTr = te.CodTr 
    LEFT JOIN 
      Exer e ON te.CodExer = e.IdExer 
    LEFT JOIN 
      Serie s ON e.IdExer = s.CodExer  
    WHERE 
      t.IdTr IS NOT NULL
  """);

    // Clear previous data
    trainings.clear();

    // Group exercises by training name using the Training class
    Map<String, Training> trainingMap = {};

    for (var row in trainingData) {
      String trainingName = row['TrainingName'].toString();
      String? exerciseName = row['ExerciseName'];
      String? trainingDay = row['TrainingDay']?.toString().toLowerCase();
      int trainingId = row['IdTr']; // Retrieve Training ID
      int? exerciseId = row['IdExer']; // Retrieve Exercise ID

      // Initialize training if it doesn't exist
      if (!trainingMap.containsKey(trainingName)) {
        trainingMap[trainingName] = Training(
            id: trainingId, name: trainingName, exercises: [], days: []);
      }

      var training = trainingMap[trainingName]!;

      // Add the training day if it's not already in the list
      if (trainingDay != null && !training.days.contains(trainingDay)) {
        training.days.add(trainingDay);
      }

      // Only add exercises if exerciseName is not null
      if (exerciseName != null && exerciseId != null) {
        // Add exercise information
        var exercise = training.exercises.firstWhere(
          (ex) => ex.name == exerciseName,
          orElse: () => Exercise(
            id: exerciseId, // Set Exercise ID
            name: exerciseName,
            completed: false,
            isExpanded: false,
            weights: [],
          ),
        );

        // Add exercise to training if it's not already added
        if (!training.exercises.contains(exercise)) {
          training.exercises.add(exercise);
        }

        // Add weight and rep information
        if (row['Peso'] != null && row['Rep'] != null) {
          exercise.weights.add({
            'Peso': row['Peso'],
            'Rep': row['Rep'],
          });
        }
      }
    }

    // Convert the map to a list of trainings
    trainings = trainingMap.values.toList();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    dateStr = DateFormat('d', 'pt_BR').format(now).toString();
    initInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the page is returned to
    initInfo();
  }

  // Optionally, if you want to check updates when returning to this page,
  // you can also implement this method:
  @override
  void didUpdateWidget(MPage oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsedMilliseconds = 0; // Reset the timer
    });
  }

  // Time formatter in mm:ss:SS format
  String get _formattedTime {
    final minutes = (_elapsedMilliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds =
        ((_elapsedMilliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centiseconds =
        ((_elapsedMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return "$minutes:$seconds:$centiseconds"; // Return formatted time
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            title: Text(
              'Olá $names',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            titleSpacing: 10.0,
          ),
          body: RefreshIndicator(
            color: Colors.black,
            onRefresh: () async {
              await initInfo();
            },
            child: Column(children: [
              const SizedBox(height: 10),
              // Date and Chronometer Card
              SizedBox(
                height: 200,
                width: MediaQuery.of(context).size.width - 10,
                child: Card(
                  color: const Color.fromARGB(255, 48, 48, 48),
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
                                  height:
                                      MediaQuery.of(context).size.height / 7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 50.0,
                                        ),
                                      ),
                                      Text(dayStr),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Chronometer Card
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Card(
                                color: Colors.white,
                                elevation: 3,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height / 14,
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

              Expanded(
                child: ListView.builder(
                  itemCount: trainings.length,
                  itemBuilder: (context, index) {
                    Training training = trainings[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: const Color.fromARGB(255, 48, 48, 48),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            // Main ExpansionTile for training
                            ExpansionTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      training.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  // Edit Training Button Inline
                                  IconButton(
                                    onPressed: () {
                                      // Navigate to EditTrainingPage with the current training data
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditTrainingPage(
                                            training: training,
                                            // Pass current training to edit
                                          ),
                                        ),
                                      ).then((updatedTraining) {
                                        // When returning from the edit page, update the training list
                                        if (updatedTraining != null) {
                                          setState(() {
                                            // Update the training in the list
                                            training.exercises = updatedTraining
                                                .exercises; // Adjust according to how you handle updated training
                                          });
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.edit),
                                    color: Colors.white, // Button color
                                    padding: EdgeInsets
                                        .zero, // Remove default padding
                                  ),
                                ],
                              ),
                              iconColor: Colors.white,
                              collapsedIconColor: Colors.white,
                              children: [
                                // Check if there are exercises for this training
                                if (training.exercises.isEmpty)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    child: Center(
                                      child: Text(
                                        'No exercises available',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: training.exercises.length,
                                    itemBuilder: (context, exIndex) {
                                      Exercise exercise =
                                          training.exercises[exIndex];

                                      return Column(
                                        children: [
                                          // Exercise ExpansionTile
                                          ExpansionTile(
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  exercise.name,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Row(
                                                  children: [
                                                    Checkbox(
                                                      value: exercise.completed,
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          exercise.completed =
                                                              value!;
                                                        });
                                                      },
                                                      activeColor: Colors.red,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            iconColor: Colors.white,
                                            collapsedIconColor: Colors.white,
                                            children: exercise.weights.isEmpty
                                                ? [
                                                    const Text(
                                                      'No weights available',
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    )
                                                  ]
                                                : exercise.weights
                                                    .map<Widget>((weightData) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16.0,
                                                          vertical: 4.0),
                                                      child: Text(
                                                        'Peso: ${weightData['Peso']} kg, Reps: ${weightData['Rep']}',
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    );
                                                  }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ]),
          ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            overlayOpacity: 0.5,
            spacing: 12,
            children: [
              SpeedDialChild(
                child: const Icon(
                  Icons.add,
                ),
                label: 'Add Training',
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CPage()),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.edit),
                label: 'Edit',
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CPage()),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.visibility),
                label: 'See All Trainings',
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TrainingListPage()),
                  );
                },
              ),
            ],
          ),
        ));
  }
}
