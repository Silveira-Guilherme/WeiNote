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

  /// Load all exercises and group their sets
  Future<void> loadExercises() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch all exercises and their sets
      final allData = await dbHelper.database.then((db) => db.rawQuery("""
        SELECT e.IdExer, e.Name, s.Peso, s.Rep
        FROM Exer e
        LEFT JOIN Serie s ON e.IdExer = s.CodExer
      """));

      // Fetch exercises already linked to the macro
      final macroExercises = await dbHelper.database.then((db) => db.query(
            'Exer_Macro',
            where: 'CodMacro = ?',
            whereArgs: [widget.macroId],
          ));

      // Extract IDs of exercises already linked to the macro
      final macroExerciseIds = macroExercises.map((exercise) => exercise['CodExer']).toSet();

      // Group sets by exercise ID
      Map<int, Map<String, dynamic>> groupedExercises = {};
      for (var row in allData) {
        final id = row['IdExer'] as int?;
        if (id != null) {
          if (!groupedExercises.containsKey(id)) {
            groupedExercises[id] = {
              'IdExer': id,
              'Name': row['Name'],
              'Sets': [],
            };
          }
          groupedExercises[id]!['Sets'].add({
            'Peso': row['Peso'],
            'Rep': row['Rep'],
          });
        }
      }

      // Prepare exercise list and pre-selection state
      setState(() {
        exercises = groupedExercises.values.toList();
        selectedExercises = exercises.map((exercise) => macroExerciseIds.contains(exercise['IdExer'])).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load exercises. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Save the selected exercises to the macro
  Future<void> saveExercises() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get selected exercise IDs
      final selectedIds = [
        for (int i = 0; i < selectedExercises.length; i++)
          if (selectedExercises[i]) exercises[i]['IdExer']
      ];

      final db = await dbHelper.database;

      // Clear existing exercises for the macro
      await db.delete('Exer_Macro', where: 'CodMacro = ?', whereArgs: [widget.macroId]);

      // Add selected exercises to the macro
      for (int exerciseId in selectedIds) {
        await db.insert('Exer_Macro', {'CodMacro': widget.macroId, 'CodExer': exerciseId});
      }

      // Notify the user and trigger the callback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercises updated successfully!')),
      );
      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save exercises. Please try again.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add Exercises',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: secondaryColor),
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
                return Card(
                  color: accentColor1,
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    collapsedIconColor: secondaryColor,
                    iconColor: secondaryColor,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align items to the left
                      children: [
                        Expanded(
                          child: Text(
                            exercise['Name'],
                            style: const TextStyle(fontSize: 16, color: secondaryColor),
                            textAlign: TextAlign.left, // Ensure text aligns to the left
                          ),
                        ),
                        // Optional Checkbox aligned to the right
                        Checkbox(
                          value: selectedExercises[index],
                          activeColor: accentColor2, // Color when checked
                          checkColor: Colors.white, // Color of the checkmark
                          onChanged: (value) {
                            setState(() {
                              selectedExercises[index] = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8), // Optional spacing between checkbox and icon
                      ],
                    ),
                    children: [
                      ...exercise['Sets'].map<Widget>((set) {
                        bool isLastSet = exercise['Sets'].last == set; // Check if it's the last set

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLastSet ? 16.0 : 8.0, // Small padding for all except last
                            left: 16.0,
                            right: 16.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft, // Align text to the left inside the ExpansionTile
                            child: Text(
                              'Weight: ${set['Peso'] ?? 'N/A'} kg, Reps: ${set['Rep'] ?? 'N/A'}',
                              style: const TextStyle(color: secondaryColor, fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
