// ignore_for_file: library_private_types_in_public_api
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:gymdo/exercises/allexercises.dart';
import 'package:gymdo/exercises/createexec.dart';
import 'package:gymdo/macro/allmacros.dart';
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
    dynamic username = await dbHelper.customQuery('SELECT Name FROM User');
    names = username.isNotEmpty ? username[0]['Name']?.toString() ?? 'User' : 'User';

    dayStr = DateFormat('EEEE', 'en_US').format(now).toLowerCase();
    trainings.clear();

    try {
      // Fetch training data
      List<dynamic> trainingData = await dbHelper.customQuery("""
      SELECT 
        t.IdTr, 
        t.Name AS TrainingName, 
        t.Type AS TrainingType
      FROM 
        Tr t
    """);

      // Fetch exercise data related to trainings
      List<dynamic> exerciseData = await dbHelper.customQuery("""
      SELECT 
        te.CodTr, 
        e.IdExer, 
        e.Name AS ExerciseName, 
        te.ExerOrder,
        s.Peso, 
        s.Rep
      FROM 
        Tr_Exer te
      LEFT JOIN 
        Exer e ON te.CodExer = e.IdExer 
      LEFT JOIN 
        Serie s ON e.IdExer = s.CodExer  
      WHERE 
        te.CodTr IN (SELECT IdTr FROM Tr)
      ORDER BY 
        te.CodTr, te.ExerOrder
    """);

      // Fetch macro data related to trainings
      List<dynamic> macroData = await dbHelper.customQuery("""
      SELECT 
      m.idmacro as MacroId,
        tm.CodTr, 
        m.IdMacro, 
        mt.MacroOrder, 
        m.Qtt AS MacroQtt
      FROM 
        Tr_Macro tm
      LEFT JOIN 
        Macro m ON tm.CodMacro = m.IdMacro
      LEFT JOIN 
        Exer_Macro mt ON mt.CodMacro = m.IdMacro
      WHERE 
        tm.CodTr IN (SELECT IdTr FROM Tr)
      ORDER BY 
        tm.CodTr, mt.MacroOrder
    """);

      // Initialize training map
      Map<int, Training> trainingMap = {};

      // Populate training data
      for (var item in trainingData) {
        int trainingId = item['IdTr'];
        trainingMap[trainingId] = Training(
          id: trainingId,
          name: item['TrainingName'],
          type: item['TrainingType'],
          exercises: [],
          macros: [],
        );
      }

      // Populate exercise data
      for (var item in exerciseData) {
        int trainingId = item['CodTr'];
        int exerciseId = item['IdExer'];

        if (trainingMap.containsKey(trainingId) && exerciseId != null) {
          Training training = trainingMap[trainingId]!;
          // Find or create exercise entry
          Exercise exercise = training.exercises.firstWhere(
            (ex) => ex.id == exerciseId,
            orElse: () {
              Exercise newExercise = Exercise(
                id: exerciseId,
                name: item['ExerciseName'] ?? '',
                order: item['ExerOrder'] ?? 0,
                weights: [],
              );
              training.exercises.add(newExercise);
              return newExercise;
            },
          );

          // Add weights to exercise
          if (item['Peso'] != null && item['Rep'] != null) {
            exercise.weights.add({'Peso': item['Peso'], 'Rep': item['Rep']});
          }
        }
      }

      // Populate macro data
      for (var item in macroData) {
        int macroid = item['MacroId'];
        int trainingId = item['CodTr'];
        int macroOrder = item['MacroOrder'] ?? 0;
        int macroQtt = item['MacroQtt'] ?? 0;

        if (trainingMap.containsKey(trainingId) && macroQtt > 0) {
          Training training = trainingMap[trainingId]!;

          // Retrieve or create Macro
          Macro? macro = training.macros.firstWhere(
            (m) => m.order == macroOrder,
            orElse: () {
              Macro newMacro = Macro(
                id: macroid,
                order: macroOrder,
                name: 'Macro Qtt: $macroQtt', // Display Qtt as Macro's name
                exercises: [],
              );
              training.macros.add(newMacro);
              return newMacro;
            },
          );

          // Add exercise to the macro if it exists
          if (item['IdExer'] != null) {
            int exerciseId = item['IdExer'];

            // Check if exercise is already part of the macro
            Exercise macroExercise = macro.exercises.firstWhere(
              (ex) => ex.id == exerciseId,
              orElse: () {
                Exercise newMacroExercise = Exercise(
                  id: exerciseId,
                  name: item['ExerciseName'] ?? '',
                  order: item['ExerOrder'] ?? 0,
                  weights: [],
                );
                macro.exercises.add(newMacroExercise);
                return newMacroExercise;
              },
            );

            // Add weights to macro exercise
            if (item['Peso'] != null && item['Rep'] != null) {
              macroExercise.weights.add({'Peso': item['Peso'], 'Rep': item['Rep']});
            }
          }
        }
      }

      // Assign the final list of trainings
      trainings = trainingMap.values.toList();
    } catch (error) {
      print('Error fetching training data: $error');
    }

    setState(() {}); // Trigger UI rebuild
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
    final seconds = ((_elapsedMilliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final centiseconds = ((_elapsedMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: secondaryColor),
            ),
            centerTitle: true,
            titleSpacing: 10.0,
          ),
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              initInfo();
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
                                    height: MediaQuery.of(context).size.height / 7,
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
                                  color: secondaryColor,
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
                                    IconButton(icon: const Icon(Icons.play_arrow), onPressed: _startTimer, color: secondaryColor),
                                    IconButton(
                                      icon: const Icon(Icons.pause),
                                      onPressed: _stopTimer,
                                      color: accentColor2,
                                    ),
                                    IconButton(icon: const Icon(Icons.stop), onPressed: _resetTimer, color: accentColor2),
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
                trainings.isNotEmpty
                    ? ListView.builder(
                        itemCount: trainings.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          Training training = trainings[index];
                          List<Widget> trainingWidgets = [];

                          // Create a combined list that merges exercises and macros by their order
                          List<dynamic> combinedList = [];

                          // Add exercises to the combined list
                          for (var exercise in training.exercises) {
                            combinedList.add({'type': 'exercise', 'item': exercise});
                          }

                          // Add macros to the combined list
                          for (var macro in training.macros) {
                            combinedList.add({'type': 'macro', 'item': macro});
                          }

                          // Sort combinedList by order (handle both exercises and macros)
                          combinedList.sort((a, b) {
                            int orderA = a['type'] == 'exercise' ? a['item'].order : a['item'].order; // Use order directly
                            int orderB = b['type'] == 'exercise' ? b['item'].order : b['item'].order; // Use order directly
                            return orderA.compareTo(orderB);
                          });

                          // Build UI based on the combined list
                          for (var item in combinedList) {
                            if (item['type'] == 'exercise') {
                              Exercise exercise = item['item'];
                              trainingWidgets.add(
                                ExpansionTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.name,
                                          style: const TextStyle(color: secondaryColor),
                                        ),
                                      ),
                                      Checkbox(
                                        value: exercise.completed,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            exercise.completed = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  children: exercise.weights.map<Widget>((weight) {
                                    return ListTile(
                                      title: Text(
                                        'Peso: ${weight['Peso']} kg, Reps: ${weight['Rep']}',
                                        style: const TextStyle(color: secondaryColor),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            } else if (item['type'] == 'macro') {
                              Macro macro = item['item'];
                              trainingWidgets.add(
                                ExpansionTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Macro ID: ${macro.order}', // Display macro ID instead of quantity
                                          style: const TextStyle(color: secondaryColor),
                                        ),
                                      ),
                                      Checkbox(
                                        value: macro.completed,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            macro.completed = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  children: macro.exercises.map<Widget>((exercise) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          title: Text(
                                            exercise.name,
                                            style: const TextStyle(color: secondaryColor),
                                          ),
                                          trailing: Checkbox(
                                            value: exercise.completed,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                exercise.completed = value!;
                                              });
                                            },
                                          ),
                                        ),
                                        // Displaying weights for each exercise within the macro
                                        ...exercise.weights.map<Widget>((weight) {
                                          return ListTile(
                                            title: Text(
                                              'Peso: ${weight['Peso']} kg, Reps: ${weight['Rep']}',
                                              style: const TextStyle(color: secondaryColor),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: accentColor1,
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    training.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: secondaryColor, fontSize: 20),
                                  ),
                                  ...trainingWidgets,
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          "No trainings saved",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                      )
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
                child: const Icon(Icons.add),
                label: 'See All Exercises',
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllExercisesPage()),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'See All Macros',
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllMacrosPage()),
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
