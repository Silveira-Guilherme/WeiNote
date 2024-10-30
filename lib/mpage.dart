// ignore_for_file: library_private_types_in_public_api
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:gymdo/main.dart';
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
    List<Map<String, dynamic>> username =
        await dbHelper.customQuery('select name from user');
    names = username.isNotEmpty
        ? username[0]['name']?.toString() ?? 'User'
        : 'User';

    // Extract the weekday (e.g., Monday, Tuesday)
    dayStr = DateFormat('EEEE', 'en_US').format(now).toLowerCase();

    // Clear previous training data
    trainings.clear();

    try {
      // Your SQL query here
      List<dynamic> trainingData = await dbHelper.customQuery("""
      SELECT 
        t.IdTr, 
        t.Name AS TrainingName, 
        t.Type AS TrainingType,
        e.IdExer, 
        e.Name AS ExerciseName, 
        s.Peso, 
        s.Rep,
        td.CodDay AS TrainingDay,
        mt.MacroOrder,
        te.ExerOrder AS ExerciseOrder
      FROM 
        Tr t
      LEFT JOIN 
        Tr_Day td ON t.IdTr = td.CodTr 
      LEFT JOIN 
        Tr_Exer te ON t.IdTr = te.CodTr 
      LEFT JOIN 
        Exer e ON te.CodExer = e.IdExer 
      LEFT JOIN 
        Exer_Macro mt ON mt.CodExer = e.IdExer AND mt.CodMacro IN (SELECT CodMacro FROM Tr_Macro WHERE CodTr = t.IdTr)
      LEFT JOIN 
        Serie s ON e.IdExer = s.CodExer  
      LEFT JOIN 
        Day d ON td.CodDay = d.IdDay
      WHERE 
        LOWER(d.name) = '${dayStr.toLowerCase()}' 
      ORDER BY 
        t.IdTr, MacroOrder, ExerciseOrder
    """);
      print(trainingData);
      // Temporary map to hold exercises by training ID
      Map<int, Training> trainingMap = {};

      // Process the results and populate the trainings list
      for (var item in trainingData) {
        int trainingId = item['IdTr'];

        // If the training is not already in the map, create a new Training object
        if (!trainingMap.containsKey(trainingId)) {
          trainingMap[trainingId] = Training(
            id: trainingId,
            name: item['TrainingName'],
            type: item['TrainingType'],
            exercises: [], // Initialize with an empty list
          );
        }

        // Check if the exercise exists and has a valid ID
        if (item['IdExer'] != null) {
          int exerciseId = item['IdExer'];
          var training = trainingMap[trainingId]!;

          // Try to find the exercise by id manually
          Exercise? existingExercise;
          for (var ex in training.exercises) {
            if (ex.id == exerciseId) {
              existingExercise = ex;
              break;
            }
          }

          if (existingExercise != null) {
            // If the exercise already exists, add the weight and rep data to the weights list
            existingExercise.weights.add({
              'Peso': item['Peso'],
              'Rep': item['Rep'],
            });
          } else {
            // If exercise doesn't exist, create a new one with the initial weight data
            Exercise newExercise = Exercise(
              id: exerciseId,
              name: item['ExerciseName'],
              order: item['ExerciseOrder'] ?? 0,
              weights: [
                {
                  'Peso': item['Peso'],
                  'Rep': item['Rep'],
                }
              ],
            );

            // Add the new exercise to the training
            training.exercises.add(newExercise);
          }
        }
      }

      // Convert the map back to a list for your trainings variable
      trainings = trainingMap.values.toList();
    } catch (error) {
      // Handle error
      print('Error fetching training data: $error');
    }

    // Trigger a rebuild
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    dateStr = DateFormat('d', 'en_US').format(now).toString();
    initInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the page is returned to
    initInfo();
  }

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
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            title: Text(
              'Olá $names',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                  color: secondaryColor),
            ),
            centerTitle: true,
            titleSpacing: 10.0,
          ),
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              initInfo();
              // For example, you could call initInfo();
            },
            child: ListView(
              children: [
                const SizedBox(height: 10),
                // Date and Chronometer Card
                SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width - 10,
                  child: Card(
                    color: accentColor1,
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
                                  color: secondaryColor,
                                  elevation: 3,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    height:
                                        MediaQuery.of(context).size.height / 7,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  color: secondaryColor,
                                  elevation: 3,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    height:
                                        MediaQuery.of(context).size.height / 14,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        color: secondaryColor),
                                    IconButton(
                                      icon: const Icon(Icons.pause),
                                      onPressed: _stopTimer,
                                      color: accentColor2,
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.stop),
                                        onPressed: _resetTimer,
                                        color: accentColor2),
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
                // Your trainings list
                trainings.length > 0
                    ? ListView.builder(
                        itemCount: trainings.length,
                        shrinkWrap:
                            true, // This allows the ListView to take the height of its children
                        physics:
                            const NeverScrollableScrollPhysics(), // Prevents scrolling of the inner ListView
                        itemBuilder: (context, index) {
                          Training training = trainings[index];

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: accentColor1,
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
                                              color: secondaryColor,
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
                                                  trainingId: training.id,
                                                  onSave: initInfo,
                                                  // Pass current training to edit
                                                ),
                                              ),
                                            ).then((updatedTraining) {
                                              // When returning from the edit page, update the training list
                                              if (updatedTraining != null) {
                                                setState(() {
                                                  // Update the training in the list
                                                  training.exercises =
                                                      updatedTraining
                                                          .exercises; // Adjust according to how you handle updated training
                                                });
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.edit),
                                          color: secondaryColor,
                                          padding: EdgeInsets
                                              .zero, // Remove default padding
                                        ),
                                      ],
                                    ),
                                    iconColor: secondaryColor,
                                    collapsedIconColor: secondaryColor,
                                    children: [
                                      // Check if there are exercises for this training
                                      if (training.exercises.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Center(
                                            child: Text(
                                              'No exercises available',
                                              style: TextStyle(
                                                color: secondaryColor,
                                              ),
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
                                                          color: secondaryColor,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Checkbox(
                                                            value: exercise
                                                                .completed,
                                                            onChanged:
                                                                (bool? value) {
                                                              setState(() {
                                                                exercise.completed =
                                                                    value!;
                                                              });
                                                            },
                                                            activeColor:
                                                                accentColor2,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  iconColor: secondaryColor,
                                                  collapsedIconColor:
                                                      secondaryColor,
                                                  children: exercise
                                                          .weights.isEmpty
                                                      ? [
                                                          const Text(
                                                            'No weights available',
                                                            style: TextStyle(
                                                              color:
                                                                  secondaryColor,
                                                            ),
                                                          )
                                                        ]
                                                      : exercise.weights
                                                          .map<Widget>(
                                                              (weightData) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16.0,
                                                                    vertical:
                                                                        4.0),
                                                            child: Text(
                                                              'Peso: ${weightData['Peso']} kg, Reps: ${weightData['Rep']}',
                                                              style:
                                                                  const TextStyle(
                                                                color:
                                                                    secondaryColor,
                                                              ),
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
                        })
                    : Center(
                        // Center the text "Quim" when the list is empty
                        child: Text(
                          "No trainings saved",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Make it bold
                            fontSize: 16, // Adjust font size
                            color: primaryColor, // You can customize the color
                          ),
                        ),
                      ),
              ],
            ),
          ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: primaryColor,
            foregroundColor: secondaryColor,
            overlayOpacity: 0.5,
            spacing: 12,
            children: [
              SpeedDialChild(
                child: const Icon(
                  Icons.add,
                ),
                label: 'Add Training',
                foregroundColor: secondaryColor,
                backgroundColor: accentColor2,
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
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
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
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
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
