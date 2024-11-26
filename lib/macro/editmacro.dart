import 'package:flutter/material.dart';
import '/../sql.dart';

class EditMacroPage extends StatefulWidget {
  final int macroId;

  const EditMacroPage({Key? key, required this.macroId}) : super(key: key);

  @override
  _EditMacroPageState createState() => _EditMacroPageState();
}

class _EditMacroPageState extends State<EditMacroPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> exercises = [];
  Set<int> macroExercises = {};
  int quantity = 1; // Default quantity

  @override
  void initState() {
    super.initState();
    fetchMacroDetails();
  }

  Future<void> fetchMacroDetails() async {
    try {
      // Fetch macro details and exercises in one query
      List<Map<String, dynamic>> result = await dbHelper.customQuery("""
      SELECT 
        m.Qtt, 
        e.IdExer AS id, 
        e.Name AS Name,
        em.CodMacro AS CodMacro
      FROM 
        Macro m
      LEFT JOIN 
        Exer_Macro em ON m.IdMacro = em.CodMacro
      LEFT JOIN 
        Exer e ON em.CodExer = e.IdExer
      WHERE 
        m.IdMacro = ${widget.macroId}
    """);

      // Parse the result
      int? macroQuantity = result.isNotEmpty ? result.first['Qtt'] : null;

      // Extract all exercises
      List<Map<String, dynamic>> allExercises = result
          .where((row) => row['id'] != null)
          .map((row) => {
                'id': row['id'],
                'Name': row['Name'] ?? 'Unnamed Exercise', // Default name if null
              })
          .toList();

      // Extract current exercises associated with the macro
      Set<int> selectedExercises = {
        ...result.where((row) => row['CodMacro'] != null).map((row) => row['id']),
      };

      // Update the state
      setState(() {
        quantity = macroQuantity ?? 1; // Default quantity to 1 if null
        exercises = allExercises;
        macroExercises = selectedExercises;
      });
    } catch (error) {
      print('Error fetching macro details: $error');
      // Handle errors, like showing a message to the user
    }
  }

  // Toggle exercise selection for this macro
  void toggleExerciseSelection(int exerciseId) {
    setState(() {
      if (macroExercises.contains(exerciseId)) {
        macroExercises.remove(exerciseId);
      } else {
        macroExercises.add(exerciseId);
      }
    });
  }

  // Save changes to macro's quantity and exercises
  Future<void> saveMacroChanges() async {
    // Update macro quantity
    await dbHelper.customQuery("""
      UPDATE Macro SET Qtt = $quantity WHERE IdMacro = ${widget.macroId}
    """);

    // Delete existing exercise links for the macro
    await dbHelper.customQuery("""
      DELETE FROM Exer_Macro WHERE CodMacro = ${widget.macroId}
    """);

    // Insert updated exercises for this macro
    for (var exerciseId in macroExercises) {
      await dbHelper.customQuery("""
        INSERT INTO Exer_Macro (CodMacro, CodExer) VALUES (${widget.macroId}, $exerciseId)
      """);
    }

    Navigator.pop(context); // Return to previous screen after saving changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Macro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveMacroChanges,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quantity input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity: ', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),
          const Divider(),

          // Exercise selection
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                var exercise = exercises[index];
                bool isSelected = macroExercises.contains(exercise['id']);
                return CheckboxListTile(
                  title: Text(exercise['Name']),
                  value: isSelected,
                  onChanged: (value) => toggleExerciseSelection(exercise['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
