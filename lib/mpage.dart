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
  String names = 'User'; // Default name if none is fetched
  String currentTrainingName = 'No Training Selected'; // For training name
  String dateStr = '', dayStr = '';
  List<bool> completed = [];
  List<bool> trainingExpanded = []; // Track expanded state for training details
  List<List<bool>> exerciseExpanded =
      []; // Track expanded state for each exercise in each training
  DateTime now = DateTime.now();
  Map<String, List<Map<String, dynamic>>> trainingExercisesMap = {};

  // Variables for chronometer with centiseconds (SS)
  Timer? _timer;
  int _elapsedMilliseconds = 0;
  bool _isRunning = false;

  void changeValue(bool value, int index) {
    setState(() {
      completed[index] = value; // Update completed state
    });
  }

  Future<List<Map<String, dynamic>>> query(String query) async {
    return await dbHelper.customQuery(query);
  }

  Future<void> initInfo() async {
    // Fetch user name
    List<Map<String, dynamic>> username = await query("SELECT Name FROM User");
    if (username.isNotEmpty) {
      setState(() {
        names = username[0]['Name']?.toString() ??
            'User'; // Fallback to 'User' if null
      });
    }

    // Extract the weekday from the data string
    dayStr = DateFormat('EEEE', 'pt_BR')
        .format(now)
        .toLowerCase(); // Convert to lowercase to match the database

    // Fetch the current training name and associated exercises
    List<dynamic> trainingData = await query("""
      SELECT 
        t.Name as TrainingName, 
        e.IdExer, 
        e.Name as ExerciseName, 
        s.IdSerie, 
        s.Peso, 
        s.Rep 
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
        LOWER(td.Day) = '$dayStr'
    """);

    // Clear previous data
    trainingExercisesMap.clear();
    print(trainingData);
    // Grouping exercises by training name
    for (var row in trainingData) {
      String trainingName =
          row['TrainingName']?.toString() ?? 'Unnamed Training';
      String exerciseName = row['ExerciseName'] ?? 'Unnamed Exercise';

      // Add training if not already present
      if (!trainingExercisesMap.containsKey(trainingName)) {
        trainingExercisesMap[trainingName] = [];
      }

      // Add exercise info if the exercise is not already added
      List<Map<String, dynamic>> exercisesList =
          trainingExercisesMap[trainingName]!;
      bool exerciseExists = exercisesList
          .any((exercise) => exercise['ExerciseName'] == exerciseName);

      if (!exerciseExists && row['ExerciseName'] != null) {
        exercisesList.add({
          'ExerciseName': exerciseName,
          'Series': [],
          'isExpanded': false,
        });
      }

      // Add series information
      if (row['IdSerie'] != null) {
        var exerciseIndex = exercisesList
            .indexWhere((exercise) => exercise['ExerciseName'] == exerciseName);
        if (exerciseIndex != -1) {
          exercisesList[exerciseIndex]['Series'].add({
            'IdSerie': row['IdSerie'],
            'Peso': row['Peso'] ?? 'N/A',
            'Rep': row['Rep'] ?? 'N/A',
          });
        }
      }
    }

    // If there are trainings available, update state accordingly
    if (trainingExercisesMap.isNotEmpty) {
      setState(() {
        currentTrainingName =
            trainingExercisesMap.keys.first; // Get the first training name
        completed = List.generate(
            trainingExercisesMap[currentTrainingName]!.length,
            (_) => false); // Initialize completed state
        trainingExpanded = List.generate(trainingExercisesMap.length,
            (_) => false); // Initialize trainingExpanded
        exerciseExpanded = List.generate(
            trainingExercisesMap.length,
            (index) => List.generate(
                trainingExercisesMap.values.elementAt(index).length,
                (_) => false)); // Initialize exerciseExpanded
      });
    } else {
      setState(() {
        currentTrainingName = 'No Training Selected'; // Keep the message
        completed.clear(); // Clear completed list
      });
    }
  }

  @override
  void initState() {
    super.initState();
    dateStr = DateFormat('d', 'pt_BR').format(now).toString();
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
    return PopScope(
        canPop: false,
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
              // Training Name is now below the date and chronometer card
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

              // Training exercises display
              // Inside the build method, within the ListView.builder for exercises
              Expanded(
                child: ListView.builder(
                  itemCount: trainingExercisesMap.length,
                  itemBuilder: (context, index) {
                    String trainingName =
                        trainingExercisesMap.keys.elementAt(index);
                    List<Map<String, dynamic>> exercises =
                        trainingExercisesMap[trainingName]!;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: const Color.fromARGB(255, 48, 48, 48),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                //"Nome Treino " +
                                trainingName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 20),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  trainingExpanded[index]
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    trainingExpanded[index] = !trainingExpanded[
                                        index]; // Toggle expansion of training
                                  });
                                },
                              ),
                            ),
                            if (trainingExpanded[index]) ...[
                              if (exercises.isEmpty) ...[
                                // Display "Quim" when there are no exercises
                                const Text(
                                  'Sem Exercicios Registados',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    //fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else ...[
                                // Loop through exercises if they exist
                                for (var exerciseIndex = 0;
                                    exerciseIndex < exercises.length;
                                    exerciseIndex++)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Row for exercise title, completed selection, and expand button
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Exercise Title
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 50),
                                              child: Text(
                                                // "Nomes Exercicios " +
                                                exercises[exerciseIndex]
                                                    ['ExerciseName'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  //fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Completed Selection Button
                                          Checkbox(
                                            value: completed[exerciseIndex],
                                            onChanged: (value) {
                                              changeValue(value!,
                                                  exerciseIndex); // Update completed state
                                            },
                                            activeColor: Colors.red,
                                          ),
                                          // Expand/Collapse Button for exercise details
                                          IconButton(
                                            icon: Icon(
                                              exerciseExpanded[index]
                                                      [exerciseIndex]
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                exerciseExpanded[index]
                                                        [exerciseIndex] =
                                                    !exerciseExpanded[index][
                                                        exerciseIndex]; // Toggle expansion of exercise
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Display Series only when exercise is expanded
                                      if (exerciseExpanded[index]
                                          [exerciseIndex]) ...[
                                        for (var series
                                            in exercises[exerciseIndex]
                                                ['Series'])
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 50),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Peso: ${series['Peso']}kg           Reps: ${series['Rep']}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                            ),
                                          )
                                      ],
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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
