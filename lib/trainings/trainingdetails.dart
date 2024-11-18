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
      SELECT e.Name AS itemName, 
      e.IdExer, 
      'exercise' AS itemType, 
      te.Exerorder AS Exerorder,
      GROUP_CONCAT(s.Peso) AS pesos, 
      GROUP_CONCAT(s.Rep) AS reps
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
        tm.Exerorder AS Exerorder,
        GROUP_CONCAT(DISTINCT s.Peso) AS Peso, 
        GROUP_CONCAT(DISTINCT s.Rep) AS Rep, 
        'macro' AS itemType
      FROM 
        Macro m
      JOIN 
        Exer_Macro em ON m.IdMacro = em.CodMacro
      JOIN 
        Exer e ON em.CodExer = e.IdExer
      LEFT JOIN 
        Serie s ON s.CodExer = e.IdExer
      JOIN 
        Tr_Macro tm ON tm.CodMacro = m.IdMacro
      WHERE 
        tm.CodTr = ${widget.trainingId}
      GROUP BY 
        m.IdMacro, m.Qtt, e.Name, e.IdExer, tm.Exerorder
      ORDER BY 
        tm.Exerorder;
    """);

      // Initialize combined items list
      List<Map<String, dynamic>> combinedItems = [];

      // Process exercises
      for (var exercise in exercisesResult) {
        List<String> pesos = exercise['pesos']?.split(',') ?? [];
        List<String> reps = exercise['reps']?.split(',') ?? [];

        combinedItems.add({
          'itemName': exercise['itemName'],
          'IdExer': exercise['IdExer'],
          'itemType': exercise['itemType'],
          'pesoList': pesos,
          'repsList': reps,
          'Exerorder': exercise['Exerorder'], // Exerorder determines sorting
        });
      }

      // Process macros
      Map<int, Map<String, dynamic>> macroMap = {};
      for (var macro in macrosResult) {
        int macroId = macro['IdMacro'];

        // Initialize macro if not already present
        if (!macroMap.containsKey(macroId)) {
          macroMap[macroId] = {
            'IdMacro': macroId,
            'quantity': macro['quantity'],
            'itemType': 'macro',
            'Exerorder': macro['Exerorder'], // Exerorder determines sorting
            'exercises': {}, // Grouping exercises within this macro
          };
        }

        // Group exercises within this macro
        String exerciseName = macro['exerciseName'];
        if (!macroMap[macroId]?['exercises'].containsKey(exerciseName)) {
          macroMap[macroId]?['exercises'][exerciseName] = {
            'Peso': [],
            'Rep': [],
          };
        }

        // Add Peso and Rep
        List<String> pesos = macro['Peso']?.split(',') ?? [];
        List<String> reps = macro['Rep']?.split(',') ?? [];

        if (pesos.length == reps.length) {
          macroMap[macroId]?['exercises'][exerciseName]['Peso'].addAll(pesos);
          macroMap[macroId]?['exercises'][exerciseName]['Rep'].addAll(reps);
        }
      }

      // Add macros to the combined list
      for (var macro in macroMap.values) {
        combinedItems.add(macro);
      }

      // Sort the combined list by Exerorder
      combinedItems.sort((a, b) => (a['Exerorder'] as int).compareTo(b['Exerorder'] as int));

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
                        color: primaryColor,
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

                              // Card for each item
                              return Card(
                                margin: const EdgeInsets.all(3.0),
                                color: accentColor1,
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: isMacro
                                      // Macro logic: Display exercises within the macro
                                      ? ExpansionTile(
                                          iconColor: secondaryColor,
                                          collapsedIconColor: secondaryColor,
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Macro: ${item['quantity']}x - Exercises',
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
                                          children: item['exercises'] != null
                                              ? item['exercises'].entries.map<Widget>((entry) {
                                                  String exerciseName = entry.key;
                                                  List<dynamic> pesoList = entry.value['Peso'];
                                                  List<dynamic> repList = entry.value['Rep'];

                                                  return ExpansionTile(
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
/* fetch results with macroorder working

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
      SELECT e.Name AS itemName, 
      e.IdExer, 
      'exercise' AS itemType, 
      te.Exerorder AS Exerorder,
      GROUP_CONCAT(s.Peso) AS pesos, 
      GROUP_CONCAT(s.Rep) AS reps
      FROM Exer e
      INNER JOIN Tr_Exer te ON e.IdExer = te.CodExer
      LEFT JOIN Serie s ON s.CodExer = e.IdExer
      WHERE te.CodTr = ${widget.trainingId}
      GROUP BY e.IdExer
    """);

      // Fetch macros with quantity and associated exercises, ordered by macro_order
      List<Map<String, dynamic>> macrosResult = await dbHelper.customQuery("""
      SELECT 
        m.IdMacro, 
        m.Qtt AS quantity, 
        e.Name AS exerciseName, 
        e.IdExer AS exerciseId, 
        tm.Exerorder AS Exerorder,
        em.macroorder AS MacroOrder, 
        GROUP_CONCAT(DISTINCT s.Peso) AS Peso, 
        GROUP_CONCAT(DISTINCT s.Rep) AS Rep, 
        'macro' AS itemType
      FROM 
        Macro m
      JOIN 
        Exer_Macro em ON m.IdMacro = em.CodMacro
      JOIN 
        Exer e ON em.CodExer = e.IdExer
      LEFT JOIN 
        Serie s ON s.CodExer = e.IdExer
      JOIN 
        Tr_Macro tm ON tm.CodMacro = m.IdMacro
      WHERE 
        tm.CodTr = ${widget.trainingId}
      GROUP BY 
        m.IdMacro, m.Qtt, e.Name, e.IdExer, tm.Exerorder, em.macroorder
      ORDER BY 
        tm.Exerorder, em.macroorder;
    """);
      print(macrosResult);
      // Initialize combined items list
      List<Map<String, dynamic>> combinedItems = [];

      // Process exercises
      for (var exercise in exercisesResult) {
        List<String> pesos = exercise['pesos']?.split(',') ?? [];
        List<String> reps = exercise['reps']?.split(',') ?? [];

        combinedItems.add({
          'itemName': exercise['itemName'],
          'IdExer': exercise['IdExer'],
          'itemType': exercise['itemType'],
          'pesoList': pesos,
          'repsList': reps,
          'Exerorder': exercise['Exerorder'], // Exerorder determines sorting
        });
      }

      // Process macros
      Map<int, Map<String, dynamic>> macroMap = {};
      for (var macro in macrosResult) {
        int macroId = macro['IdMacro'];

        // Initialize macro if not already present
        if (!macroMap.containsKey(macroId)) {
          macroMap[macroId] = {
            'IdMacro': macroId,
            'quantity': macro['quantity'],
            'itemType': 'macro',
            'Exerorder': macro['Exerorder'], // Exerorder determines sorting
            'exercises': [], // Exercises grouped and ordered within this macro
          };
        }

        // Process exercises within the macro by macro_order
        List<String> pesos = macro['Peso']?.split(',') ?? [];
        List<String> reps = macro['Rep']?.split(',') ?? [];

        macroMap[macroId]?['exercises'].add({
          'exerciseName': macro['exerciseName'],
          'exerciseId': macro['exerciseId'],
          'MacroOrder': macro['MacroOrder'], // MacroOrder determines exercise order inside macro
          'pesoList': pesos,
          'repsList': reps,
        });

        // Sort exercises by MacroOrder within the macro
        macroMap[macroId]?['exercises'].sort((a, b) {
          return (a['MacroOrder'] as int).compareTo(b['MacroOrder'] as int);
        });
      }

      // Add macros to the combined list
      combinedItems.addAll(macroMap.values);

      // Sort the combined list by Exerorder
      combinedItems.sort((a, b) => (a['Exerorder'] as int).compareTo(b['Exerorder'] as int));

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



*/