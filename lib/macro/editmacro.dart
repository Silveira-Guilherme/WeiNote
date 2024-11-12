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

  // Fetch macro quantity and exercises from the database
  Future<void> fetchMacroDetails() async {
    // Fetch quantity for the macro
    var result = await dbHelper.customQuery("""
      SELECT Qtt FROM Macro WHERE IdMacro = ${widget.macroId}
    """);
    if (result.isNotEmpty) {
      quantity = result.first['Qtt'] ?? 1;
    }

    // Fetch exercises associated with this macro
    List<Map<String, dynamic>> allExercises = await dbHelper.customQuery("""
      SELECT IdExer AS id, Name FROM Exer
    """);

    List<Map<String, dynamic>> currentExercises = await dbHelper.customQuery("""
      SELECT CodExer AS id FROM Exer_Macro WHERE CodMacro = ${widget.macroId}
    """);

    setState(() {
      exercises = allExercises;
      macroExercises = {...currentExercises.map((e) => e['id'])};
    });
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
