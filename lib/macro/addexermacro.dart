// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class AddExercisesToMacroPage extends StatefulWidget {
  final int macroId; // Macro ID to identify the current macro
  final VoidCallback onSave;

  const AddExercisesToMacroPage({super.key, required this.macroId, required this.onSave});

  @override
  AddExercisesToMacroPageState createState() => AddExercisesToMacroPageState();
}

class AddExercisesToMacroPageState extends State<AddExercisesToMacroPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> exercises = [];
  List<bool> selectedExercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  // Load all exercises and preselect those already in the macro
  Future<void> loadExercises() async {
    setState(() {
      isLoading = true;
    });

    // Fetch all exercises from the database
    final allExercises = await dbHelper.database.then((db) {
      return db.query('Exer'); // Updated table name
    });

    // Fetch exercises already in the macro
    final macroExercises = await dbHelper.database.then((db) {
      return db.query('Exer_Macro', // Updated table name
          where: 'CodMacro = ?',
          whereArgs: [widget.macroId]);
    });

    // Extract the IDs of exercises already in the macro
    final macroExerciseIds = macroExercises.map((exercise) => exercise['CodExer']).toSet();

    // Initialize the exercise list and selection state
    setState(() {
      exercises = allExercises;
      selectedExercises = exercises
          .map((exercise) => macroExerciseIds.contains(exercise['IdExer'])) // Updated column name
          .toList();
      isLoading = false;
    });
  }

  // Save the selected exercises to the macro
  Future<void> saveExercises() async {
    setState(() {
      isLoading = true;
    });

    // Get selected exercises' IDs
    final selectedIds = [
      for (int i = 0; i < selectedExercises.length; i++)
        if (selectedExercises[i]) exercises[i]['IdExer'] // Updated column name
    ];

    final db = await dbHelper.database;

    // Clear existing exercises for the macro
    await db.delete('Exer_Macro', // Updated table name
        where: 'CodMacro = ?',
        whereArgs: [widget.macroId]);

    // Add selected exercises to the macro
    for (int exerciseId in selectedIds) {
      await db.insert('Exer_Macro', {
        'CodMacro': widget.macroId,
        'CodExer': exerciseId, // Updated column name
      });
    }

    setState(() {
      isLoading = false;
    });

    // Notify the user and close the page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercises updated successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the back button color to white
        ),
        title: const Text(
          'Create Circuit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
              color: secondaryColor,
            ),
            onPressed: saveExercises,
          )
        ],
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  title: Text(exercise['Name']), // Column name matches your schema
                  trailing: Checkbox(
                    value: selectedExercises[index],
                    activeColor: accentColor2,
                    onChanged: (value) {
                      setState(() {
                        selectedExercises[index] = value ?? false;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      // Toggle checkbox value on tap
                      selectedExercises[index] = !selectedExercises[index];
                    });
                  },
                );
              },
            ),
    );
  }
}
