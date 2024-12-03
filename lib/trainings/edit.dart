import 'package:flutter/material.dart';
import '../sql.dart';

class EditTrainingPage extends StatefulWidget {
  final int trainingId;
  final VoidCallback onSave;

  const EditTrainingPage({required this.trainingId, Key? key, required this.onSave}) : super(key: key);

  @override
  State<EditTrainingPage> createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;

  final List<String> _weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  List<bool> _selectedDays = List.generate(7, (_) => false);
  List<Map<String, dynamic>> _exercisesAndMacros = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _typeController = TextEditingController();
    _fetchTrainingData();
  }

  Future<void> _fetchTrainingData() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    try {
      // Fetch training details (name and type)
      List<Map<String, dynamic>> trainingResult = await dbHelper.customQuery("""
        SELECT Name, Type 
        FROM Tr 
        WHERE IdTr = ${widget.trainingId}
      """);

      // Fetch associated days for the training
      List<Map<String, dynamic>> daysResult = await dbHelper.customQuery("""
        SELECT d.Name AS Day 
        FROM Day d 
        INNER JOIN Tr_Day td ON d.IdDay = td.CodDay 
        WHERE td.CodTr = ${widget.trainingId}
      """);

      // Fetch exercises for the training
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

      // Fetch macros for the training
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

      // Initialize combined items list for exercises and macros
      List<Map<String, dynamic>> combinedItems = [];

      // Process exercises and add to combined items list
      for (var exercise in exercisesResult) {
        List<String> pesos = exercise['pesos']?.split(',') ?? [];
        List<String> reps = exercise['reps']?.split(',') ?? [];

        combinedItems.add({
          'itemName': exercise['itemName'],
          'IdExer': exercise['IdExer'],
          'itemType': exercise['itemType'],
          'pesoList': pesos,
          'repsList': reps,
          'Exerorder': exercise['Exerorder'],
        });
      }

      // Process macros and group exercises under macros
      Map<int, Map<String, dynamic>> macroMap = {};
      for (var macro in macrosResult) {
        int macroId = macro['IdMacro'];

        // Initialize macro if not already present
        if (!macroMap.containsKey(macroId)) {
          macroMap[macroId] = {
            'IdMacro': macroId,
            'quantity': macro['quantity'],
            'itemType': 'macro',
            'Exerorder': macro['Exerorder'],
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
      print(combinedItems);

      // Update state with fetched data
      setState(() {
        _nameController.text = trainingResult.isNotEmpty ? trainingResult[0]['Name'] : 'Unnamed Training';
        _typeController.text = trainingResult.isNotEmpty ? trainingResult[0]['Type'] ?? 'No type specified' : 'No type specified';

        // Setting selected days based on fetched data
        _selectedDays = List.generate(7, (index) {
          return daysResult.any((day) => day['Day'] == _weekDays[index]);
        });

        _exercisesAndMacros = combinedItems; // This will hold both exercises and macros
      });
    } catch (e) {
      // Handle errors here
      print('Error fetching training details: $e');
      setState(() {
        _exercisesAndMacros = [];
      });
    }
  }

  Future<void> _saveTraining() async {
    final dbHelper = DatabaseHelper();

    // Update training name and type
    await dbHelper.customQuery("""
      UPDATE Tr SET Name = '${_nameController.text}', Type = '${_typeController.text}'
      WHERE IdTr = ${widget.trainingId}
    """);

    // Update training days
    await dbHelper.customQuery("DELETE FROM Tr_Day WHERE CodTr = ${widget.trainingId}");
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        await dbHelper.customQuery("""
          INSERT INTO Tr_Day (CodDay, CodTr) VALUES (${i + 1}, ${widget.trainingId})
        """);
      }
    }

    // Additional logic to update exercises and macros can be added here

    widget.onSave(); // Callback to notify the parent widget
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTraining,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Training Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Training Name'),
            ),
            const SizedBox(height: 16),

            // Training Type
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Training Type'),
            ),
            const SizedBox(height: 16),

            // Days Selector
            const Text('Training Days', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: List.generate(_weekDays.length, (index) {
                return ChoiceChip(
                  label: Text(_weekDays[index]),
                  selected: _selectedDays[index],
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedDays[index] = selected;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Exercises and Macros
            Expanded(
              child: ListView.builder(
                itemCount: _exercisesAndMacros.length,
                itemBuilder: (context, index) {
                  var item = _exercisesAndMacros[index];

                  // Check if the item is a macro
                  if (item['itemType'] == 'macro') {
                    return Card(
                      child: ListTile(
                        title: Text('Macro: ${item['IdMacro']} | Quantity: ${item['quantity']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display all exercises under this macro
                            for (var exerciseName in item['exercises'].keys)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Exercise: $exerciseName'),
                                  Text('Peso: ${item['exercises'][exerciseName]['Peso'].join(', ')}'),
                                  Text('Rep: ${item['exercises'][exerciseName]['Rep'].join(', ')}'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Check if the item is an exercise
                  else if (item['itemType'] == 'exercise') {
                    return Card(
                      child: ListTile(
                        title: Text('Exercise: ${item['itemName']}'),
                        subtitle: Column(
                          children: [
                            Text('Peso: ${item['pesoList'].join(', ')}'),
                            Text('Rep: ${item['repsList'].join(', ')}'),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(); // Fallback
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
