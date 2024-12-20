// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/exercises/selectexec.dart';
import 'package:gymdo/main.dart';
import 'package:gymdo/trainings/edit.dart';
import '/../sql.dart';

class TrainingDetailsPage extends StatefulWidget {
  final int trainingId;
  final VoidCallback onSave;

  const TrainingDetailsPage({super.key, required this.trainingId, required this.onSave});

  @override
  TrainingDetailsPageState createState() => TrainingDetailsPageState();
}

class TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String trainingName = '';
  String trainingType = '';
  List<String> trainingDays = [];
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  Future<void> fetchTrainingDetails() async {
    try {
      // Fetch training details
      var trainingResult = await dbHelper.customQuery("SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");
      var daysResult = await dbHelper.customQuery("""
      SELECT DISTINCT d.Name AS Day 
      FROM Day d 
      INNER JOIN Tr_Day td ON d.IdDay = td.CodDay 
      WHERE td.CodTr = ${widget.trainingId}
    """);

      var exercisesResult = await dbHelper.customQuery("""
    SELECT e.Name AS itemName, e.IdExer, 'exercise' AS itemType, te.Exerorder AS Exerorder,
       GROUP_CONCAT(DISTINCT s.Peso) AS pesos, GROUP_CONCAT(DISTINCT s.Rep) AS reps
FROM Exer e
INNER JOIN Tr_Exer te ON e.IdExer = te.CodExer
LEFT JOIN Serie s ON s.CodExer = e.IdExer
WHERE te.CodTr = ${widget.trainingId}
GROUP BY e.IdExer
    """);

      var macrosResult = await dbHelper.customQuery("""
      SELECT m.IdMacro, m.Qtt, m.RExer, m.RSerie, e.Name AS exerciseName, e.IdExer AS exerciseId, tm.Exerorder AS Exerorder,
             GROUP_CONCAT(DISTINCT s.Peso) AS Peso, GROUP_CONCAT(DISTINCT s.Rep) AS Rep, 'macro' AS itemType
      FROM Macro m
      JOIN Exer_Macro em ON m.IdMacro = em.CodMacro
      JOIN Exer e ON em.CodExer = e.IdExer
      LEFT JOIN Serie s ON s.CodExer = e.IdExer
      JOIN Tr_Macro tm ON tm.CodMacro = m.IdMacro
      WHERE tm.CodTr = ${widget.trainingId}
      GROUP BY m.IdMacro, m.Qtt, e.Name, e.IdExer, tm.Exerorder
      ORDER BY tm.Exerorder
    """);

      // Processing data
      List<Map<String, dynamic>> combinedItems = [];
      Set<int> seenExercises = {};

      // Process exercises (standalone exercises outside macros)
      List<Map<String, dynamic>> exercises = [];
      for (var exercise in exercisesResult) {
        List<String> pesos = exercise['pesos']?.split(',') ?? [];
        List<String> reps = exercise['reps']?.split(',') ?? [];

        // Remove duplicates from the pesoList and repsList
        pesos = pesos.toSet().toList();
        reps = reps.toSet().toList();

        if (!seenExercises.contains(exercise['IdExer'])) {
          exercises.add({
            'itemName': exercise['itemName'],
            'IdExer': exercise['IdExer'],
            'itemType': exercise['itemType'],
            'pesoList': pesos,
            'repsList': reps,
            'Exerorder': exercise['Exerorder'],
          });
          seenExercises.add(exercise['IdExer']); // Mark exercise as added
        }
      }

      // Process macros (exercises inside macros)
      Map<int, Map<String, dynamic>> macroMap = {};
      for (var macro in macrosResult) {
        int macroId = macro['IdMacro'];

        // Only add the macro if it hasn't been added yet
        if (!macroMap.containsKey(macroId)) {
          macroMap[macroId] = {
            'IdMacro': macroId,
            'Qtt': macro['Qtt'],
            'RExer': macro['RExer'],
            'RSerie': macro['RSerie'],
            'itemType': 'macro',
            'Exerorder': macro['Exerorder'],
            'exercises': {},
          };
        }

        String exerciseName = macro['exerciseName'];
        if (!macroMap[macroId]?['exercises'].containsKey(exerciseName)) {
          macroMap[macroId]?['exercises'][exerciseName] = {
            'Peso': [],
            'Rep': [],
          };
        }

        List<String> pesos = macro['Peso']?.split(',') ?? [];
        List<String> reps = macro['Rep']?.split(',') ?? [];

        macroMap[macroId]?['exercises'][exerciseName]['Peso']?.addAll(pesos);
        macroMap[macroId]?['exercises'][exerciseName]['Rep']?.addAll(reps);

        // Mark exercises inside macros as seen so they are not duplicated in the standalone list
        seenExercises.add(macro['exerciseId']);
      }

      // Add exercises from macros to combinedItems
      for (var macro in macroMap.values) {
        combinedItems.add(macro);
      }

      // Add standalone exercises (outside macros) that are not already inside macros
      for (var exercise in exercises) {
        combinedItems.add(exercise);
      }

      // Sort by Exerorder to maintain the correct order
      combinedItems.sort((a, b) => (a['Exerorder'] as int).compareTo(b['Exerorder'] as int));

      // Updating state with processed data
      setState(() {
        trainingName = trainingResult.isNotEmpty ? trainingResult[0]['Name'] : 'Unnamed Training';
        trainingType = trainingResult.isNotEmpty ? trainingResult[0]['Type'] ?? 'No type specified' : 'No type specified';
        trainingDays = daysResult.map((day) => day['Day'].toString()).toList();
        items = combinedItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        trainingName = 'Error fetching data';
        trainingType = 'Error';
        trainingDays = [];
        items = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTrainingDetails();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          widget.onSave(); // Call the onSave function
          return true; // Allow the page to be popped
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70.0),
            child: AppBar(
              backgroundColor: primaryColor,
              iconTheme: const IconThemeData(color: secondaryColor),
              title: const Text(
                'Training Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                  color: secondaryColor,
                ),
              ),
              centerTitle: true,
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainingName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Type: $trainingType',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Training Days:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: trainingDays.isNotEmpty
                              ? trainingDays
                                  .map((day) => Chip(
                                        label: Text(
                                          day,
                                          style: const TextStyle(color: secondaryColor),
                                        ),
                                        backgroundColor: primaryColor,
                                        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                                      ))
                                  .toList()
                              : [
                                  const Text(
                                    'No days selected',
                                    style: TextStyle(color: primaryColor),
                                  )
                                ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Exercises & Circuits:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        items.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  var item = items[index];
                                  bool isMacro = item['itemType'] == 'macro';

                                  // Card for each item
                                  return Card(
                                    margin: const EdgeInsets.all(3.0),
                                    color: accentColor1,
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: isMacro
                                          ? ExpansionTile(
                                              iconColor: secondaryColor,
                                              collapsedIconColor: secondaryColor,
                                              title: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Column containing two text widgets for exercises and details
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Text showing the exercises (Circuits)
                                                      Text(
                                                        'Circuits: ${item['exercises'] != null ? item['exercises'].keys.map((key) => key.toString()).join(', ') : 'No Exercises'}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          color: secondaryColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5), // Add spacing between Circuits and Series text
                                                      // Text showing series and other details
                                                      Text(
                                                        'Series: ${item['Qtt']}, RSerie: ${item['RSerie']}, RExer: ${item['RExer']}',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 10), // Add spacing between the Column and IconButton
                                                  // Edit button
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: secondaryColor),
                                                    onPressed: () {
                                                      // Add your edit logic here
                                                      print('Edit button pressed');
                                                    },
                                                  ),
                                                  // Expanded button (this takes remaining space)
                                                ],
                                              ),
                                              children: item['exercises'] != null
                                                  ? item['exercises'].entries.map<Widget>((entry) {
                                                      String exerciseName = entry.key;
                                                      List<dynamic> pesoList = entry.value['Peso'];
                                                      List<dynamic> repList = entry.value['Rep'];

                                                      return ExpansionTile(
                                                        iconColor: secondaryColor,
                                                        collapsedIconColor: secondaryColor,
                                                        title: Text(
                                                          exerciseName,
                                                          style: const TextStyle(fontSize: 16, color: secondaryColor),
                                                        ),
                                                        children: List.generate(pesoList.length, (setIndex) {
                                                          String peso = pesoList[setIndex].toString();
                                                          String rep = repList[setIndex].toString();

                                                          return Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: Text(
                                                              'Set ${setIndex + 1}: Peso: $peso kg, Reps: $rep',
                                                              style: const TextStyle(fontSize: 14, color: secondaryColor),
                                                            ),
                                                          );
                                                        }),
                                                      );
                                                    }).toList()
                                                  : [
                                                      const Text(
                                                        'No exercises for this macro',
                                                        style: TextStyle(color: Colors.black54),
                                                      ),
                                                    ],
                                            )
                                          // Exercise logic: Display sets with `peso` and `reps`
                                          : ExpansionTile(
                                              iconColor: secondaryColor,
                                              collapsedIconColor: secondaryColor,
                                              title: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    item['itemName'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: secondaryColor,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: secondaryColor),
                                                    onPressed: () {},
                                                  ),
                                                ],
                                              ),
                                              children: item['pesoList'].isNotEmpty && item['repsList'].isNotEmpty
                                                  ? List.generate(item['pesoList'].length, (setIndex) {
                                                      String peso = item['pesoList'][setIndex];
                                                      String rep = item['repsList'][setIndex];

                                                      return Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Set ${setIndex + 1}: Peso: $peso kg, Reps: $rep',
                                                          style: const TextStyle(fontSize: 14, color: secondaryColor),
                                                        ),
                                                      );
                                                    })
                                                  : [
                                                      const Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'No sets available for this exercise',
                                                          style: TextStyle(color: Colors.black54),
                                                        ),
                                                      ),
                                                    ],
                                            ),
                                    ),
                                  );
                                },
                              )
                            : const Text(
                                'No exercises or circuits associated with this training.',
                                style: TextStyle(color: Colors.black54),
                              ),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: primaryColor,
            foregroundColor: secondaryColor,
            overlayOpacity: 0.3,
            spacing: 12,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'Add Exercises',
                foregroundColor: secondaryColor,
                backgroundColor: accentColor2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseListPage(
                        onSave: fetchTrainingDetails,
                        trainingId: widget.trainingId,
                      ),
                    ),
                  );
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.edit),
                label: 'Edit Training',
                foregroundColor: secondaryColor,
                backgroundColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTrainingPage(
                        trainingId: widget.trainingId,
                        onSave: fetchTrainingDetails,
                      ),
                    ),
                  );
                  // Implement Edit Training logic here
                },
              ),
            ],
          ),
        ));
  }
}
