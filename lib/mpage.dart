// ignore_for_file: library_private_types_in_public_api, deprecated_member_use
import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:gymdo/exercises/allexercises.dart';
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
  const MPage({super.key});

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
    te.CodTr, te.ExerOrder, s.Peso;

    """);
      print(exerciseData);

      // Fetch macro data related to trainings
      List<dynamic> macroData = await dbHelper.customQuery("""
SELECT DISTINCT 
  m.idmacro AS MacroId,
  tm.CodTr, 
  m.IdMacro, 
  mt.MacroOrder, 
  m.Qtt AS MacroQtt,
  m.qtt,
  m.rserie,
  m.rexer,
  e.IdExer, 
  e.Name AS ExerciseName, 
  te.ExerOrder,
  s.Peso, 
  s.Rep
FROM 
  Tr_Macro tm
LEFT JOIN 
  Macro m ON tm.CodMacro = m.IdMacro
LEFT JOIN 
  Exer_Macro mt ON mt.CodMacro = m.IdMacro
LEFT JOIN 
  Exer e ON mt.CodExer = e.IdExer
LEFT JOIN 
  Tr_Exer te ON te.CodExer = e.IdExer AND te.CodTr = tm.CodTr
LEFT JOIN 
  Serie s ON e.IdExer = s.CodExer
WHERE 
  tm.CodTr IN (SELECT IdTr FROM Tr)
ORDER BY 
  tm.CodTr, mt.MacroOrder, te.ExerOrder


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

        if (trainingMap.containsKey(trainingId)) {
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
      for (var item in macroData) {
        int trainingId = item['CodTr'];
        int macroId = item['MacroId'];
        int macroOrder = item['MacroOrder'] ?? 0;
        int macroQtt = item['MacroQtt'] ?? 0;
        int macrorserie = item['RSerie'] ?? 0;
        int macrorexer = item['RExer'] ?? 0;

        if (trainingMap.containsKey(trainingId) && macroQtt > 0) {
          Training training = trainingMap[trainingId]!;

          // Check if the macro already exists in the training's macros list
          Macro? macro = training.macros.firstWhere(
            (m) => m.id == macroId,
            orElse: () {
              // If the macro doesn't exist, create and add it to the training's macros list
              Macro newMacro = Macro(
                id: macroId,
                order: macroOrder,
                qtt: macroQtt.toString(),
                rserie: macrorserie.toString(),
                rexer: macrorexer.toString(), // Display Qtt as Macro
                exercises: [],
              );
              training.macros.add(newMacro);
              return newMacro;
            },
          );

          // Now add the exercise to the existing macro (or newly created one)
          if (item['IdExer'] != null) {
            int exerciseId = item['IdExer'];

            // Check if exercise is already part of the macro to avoid duplicates
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

            // Add weights to the exercise only if they haven't been added already
            if (item['Peso'] != null && item['Rep'] != null) {
              // Check if the same weights already exist to avoid duplication
              bool weightExists = macroExercise.weights.any((weight) {
                return weight['Peso'] == item['Peso'] && weight['Rep'] == item['Rep'];
              });

              // Only add the weight if it doesn't already exist
              if (!weightExists) {
                macroExercise.weights.add({'Peso': item['Peso'], 'Rep': item['Rep']});
              }
            }
          }
        }
      }
      // Assign the final list of trainings
      trainings = trainingMap.values.toList();
    } catch (error) {
      //print('Error fetching training data: $error');
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
            title: Text('Olá $names',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                  color: secondaryColor,
                )),
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
                // Date and Chronometer Card
                SizedBox(
                  height: 210, // Total height of the container
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Card(
                      color: accentColor1,
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Square Date Card
                            AspectRatio(
                              aspectRatio: 1, // Forces a perfect square
                              child: Card(
                                color: secondaryColor,
                                elevation: 3,
                                child: Center(
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
                            ),
                            const SizedBox(width: 10),
                            // Timer Card with Buttons
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Timer Display
                                  Card(
                                    color: secondaryColor,
                                    elevation: 3,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.4, // Slightly reduced width
                                      height: 70, // Adjust height to balance proportions
                                      child: Center(
                                        child: Text(
                                          _formattedTime,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Buttons Row
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left Button
                                        IconButton(
                                          icon: const Icon(Icons.play_arrow),
                                          onPressed: _startTimer,
                                          color: secondaryColor,
                                        ),

                                        // Center Button

                                        IconButton(
                                          icon: const Icon(Icons.pause),
                                          onPressed: _stopTimer,
                                          color: accentColor2,
                                        ),

                                        // Right Button
                                        IconButton(
                                          icon: const Icon(Icons.stop),
                                          onPressed: _resetTimer,
                                          color: accentColor2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

                          // Create a single list to store both exercises and macros by order
                          List<dynamic> combinedList = [];

                          // Add exercises to the combined list
                          for (var exercise in training.exercises) {
                            combinedList.add({'type': 'exercise', 'item': exercise});
                          }

                          // Add macros to the combined list
                          for (var macro in training.macros) {
                            combinedList.add({'type': 'macro', 'item': macro});
                          }

                          // Sort the combined list by the 'order' field
                          combinedList.sort((a, b) {
                            return a['item'].order.compareTo(b['item'].order);
                          });

                          // Build the UI based on the combined list
                          for (var item in combinedList) {
                            if (item['type'] == 'exercise') {
                              Exercise exercise = item['item'];

                              trainingWidgets.add(
                                ExpansionTile(
                                  iconColor: secondaryColor,
                                  collapsedIconColor: secondaryColor,
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
                                        activeColor: accentColor2,
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

                              // Create a string with the names of the exercises separated by " - "
                              String exerciseNames = macro.exercises.map((exercise) => exercise.name).join(' - ');

                              trainingWidgets.add(ExpansionTile(
                                iconColor: secondaryColor,
                                collapsedIconColor: secondaryColor,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Circuit: $exerciseNames',
                                            style: const TextStyle(
                                              color: secondaryColor,
                                            ),
                                          ),
                                          Text(
                                            'Series: ${macro.qtt}, RSerie: ${macro.rserie}, RExer: ${macro.rexer}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: macro.completed,
                                      activeColor: accentColor2,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          macro.completed = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Series: ${macro.qtt}\n"
                                            "Rest between Series: ${macro.rserie}s\n"
                                            "Rest between Exercises: ${macro.rexer}s",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: secondaryColor,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...macro.exercises.map<Widget>((exercise) {
                                    return Column(
                                      children: [
                                        ExpansionTile(
                                          iconColor: secondaryColor,
                                          collapsedIconColor: secondaryColor,
                                          title: Text(
                                            exercise.name,
                                            style: const TextStyle(color: secondaryColor),
                                          ),
                                          children: exercise.weights.map<Widget>((weight) {
                                            return ListTile(
                                              title: Text(
                                                'Peso: ${weight['Peso']} kg, Reps: ${weight['Rep']}',
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      ],
                                    );
                                  }),
                                ],
                              ));
                            }
                          }

                          // Add the training widget with ExpansionTile
                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: accentColor1,
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  ExpansionTile(
                                    iconColor: secondaryColor,
                                    collapsedIconColor: secondaryColor,
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              training.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: secondaryColor,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              training.type.toString(),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: secondaryColor),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditTrainingPage(
                                                  trainingId: training.id,
                                                  onSave: initInfo,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    onExpansionChanged: (bool expanded) {
                                      setState(() {
                                        training.isExpanded = expanded;
                                      });
                                    },
                                    children: training.isExpanded
                                        ? [
                                            ...trainingWidgets,
                                          ]
                                        : [],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
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
                    MaterialPageRoute(
                        builder: (context) => CPage(
                              onSave: initInfo,
                            )),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.fitness_center),
                label: 'See All Exercises',
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllExercisesPage(
                              onSave: initInfo,
                            )),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.change_circle),
                label: 'See All Circuits',
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllMacrosPage(
                              onSave: initInfo,
                            )),
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
                    MaterialPageRoute(
                        builder: (context) => TrainingListPage(
                              onSave: initInfo,
                            )),
                  );
                },
              ),
            ],
          ),
        ));
  }
}
