import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/exercises/selectexec.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class TrainingDetailsPage extends StatefulWidget {
  final int trainingId;

  const TrainingDetailsPage({super.key, required this.trainingId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String trainingName = '';
  String trainingType = '';
  List<String> trainingDays = [];
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  Future<void> fetchTrainingDetails() async {
    try {
      // Fetch training details
      List<Map<String, dynamic>> trainingResult = await dbHelper.customQuery("SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");

      // Fetch training days
      List<Map<String, dynamic>> daysResult = await dbHelper.customQuery("""
        SELECT d.Name AS Day 
        FROM Day d 
        INNER JOIN Tr_Day td ON d.IdDay = td.CodDay 
        WHERE td.CodTr = ${widget.trainingId}
      """);

      // Fetch exercises with individual peso and rep data
      List<Map<String, dynamic>> exercisesResult = await dbHelper.customQuery("""
        SELECT e.Name AS itemName, e.IdExer, 'exercise' AS itemType, 
               GROUP_CONCAT(s.Peso) AS pesos, GROUP_CONCAT(s.Rep) AS reps
        FROM Exer e
        INNER JOIN Tr_Exer te ON e.IdExer = te.CodExer
        LEFT JOIN Serie s ON s.CodExer = e.IdExer
        WHERE te.CodTr = ${widget.trainingId}
        GROUP BY e.IdExer
      """);

      // Fetch macros with quantity and associated exercises, along with their peso and rep values
      List<Map<String, dynamic>> macrosResult = await dbHelper.customQuery("""
   SELECT 
  m.IdMacro, 
  m.Qtt AS quantity, 
  e.Name AS exerciseName, 
  e.IdExer AS exerciseId, 
  s.Peso, 
  s.Rep, 
  'macro' AS itemType
FROM 
  Macro m
JOIN 
  Exer_Macro em ON m.IdMacro = em.CodMacro
JOIN 
  Exer e ON em.CodExer = e.IdExer
INNER JOIN 
  Tr_Macro tm ON tm.CodMacro = m.IdMacro
LEFT JOIN 
  Serie s ON s.CodExer = e.IdExer
WHERE 
  tm.CodTr = ${widget.trainingId}
ORDER BY 
  m.IdMacro, e.Name, s.Peso;
      """);
      print(macrosResult);

      // Combine exercises and macros into a single list
      List<Map<String, dynamic>> combinedItems = [];
      Map<int, Map<String, dynamic>> macroMap = {};

      // Process and combine exercises
      for (var exercise in exercisesResult) {
        combinedItems.add(exercise);
      }

      // Process and combine macros (avoid duplicates)
      for (var macro in macrosResult) {
        int macroId = macro['IdMacro'];
        if (!macroMap.containsKey(macroId)) {
          macroMap[macroId] = macro;
        }
      }

      // Add macros to the combined list without duplicates
      combinedItems.addAll(macroMap.values);

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
      print('Error fetching training details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTrainingDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: $trainingType',
                      style: TextStyle(
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
                                      style: TextStyle(color: secondaryColor),
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

                              return Card(
                                margin: const EdgeInsets.all(3.0),
                                color: accentColor1,
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ExpansionTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isMacro ? 'Macro: ${item['quantity']}x - Exercises' : item['itemName'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: secondaryColor,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: secondaryColor),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                    children: isMacro
                                        ? item['exerciseName'] != null && item['exerciseName'] is String
                                            ? item['exerciseName']!.split(',').asMap().entries.map<Widget>((entry) {
                                                int exerciseIndex = entry.key;
                                                String exerciseName = entry.value.trim();

                                                // Now let's fetch the corresponding Peso and Rep for each exercise.
                                                List<String> pesoList = item['Peso']?.toString().split(',') ?? [];
                                                List<String> repList = item['Rep']?.toString().split(',') ?? [];

                                                // Check if there are enough `peso` and `rep` values to match exercises
                                                // If there's a mismatch, we can either handle the error or show a fallback message.
                                                if (pesoList.length != repList.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Mismatch in sets data for $exerciseName!',
                                                      style: const TextStyle(fontSize: 14, color: Colors.red),
                                                    ),
                                                  );
                                                }

                                                // Displaying each set for the exercise
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                                  child: ExpansionTile(
                                                    title: Text(
                                                      exerciseName,
                                                      style: const TextStyle(fontSize: 16, color: secondaryColor),
                                                    ),
                                                    children: List.generate(pesoList.length, (setIndex) {
                                                      String peso = pesoList[setIndex];
                                                      String rep = repList[setIndex];

                                                      return Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Set ${setIndex + 1}: Peso: $peso kg, Reps: $rep',
                                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                );
                                              }).toList()
                                            : [
                                                const Text('No exercises for this macro', style: TextStyle(color: Colors.black54)),
                                              ]
                                        : [
                                            const Text('No exercises available for this item'),
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
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseListPage(
                    trainingId: widget.trainingId,
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Edit Training',
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            onTap: () {
              // Implement Edit Training logic here
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.visibility),
            label: 'All Trainings',
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            onTap: () {
              // Implement view all trainings logic here
            },
          ),
        ],
      ),
    );
  }
}
