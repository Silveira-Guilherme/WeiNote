import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class EditMacroPage extends StatefulWidget {
  final String macroId;

  const EditMacroPage({Key? key, required this.macroId}) : super(key: key);

  @override
  _EditMacroPageState createState() => _EditMacroPageState();
}

class _EditMacroPageState extends State<EditMacroPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> exercises = [];
  Set<int> macroExercises = {};
  int quantity = 1; // Default quantity
  int rSerie = 0; // Default reps per series
  int rExer = 0; // Default reps per exercise
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchMacroDetails();
    });
  }

  Future<void> fetchMacroDetails() async {
    if (!mounted) return; // Prevent running if widget is no longer in context
    setState(() {
      isLoading = true;
    });

    try {
      // Fetching macro details, including RSerie and RExer
      final result = await dbHelper.customQuery("""
    SELECT 
      m.Qtt AS quantity, 
      m.RSerie, 
      m.RExer,
      e.IdExer AS id, 
      e.Name AS exerciseName,
      em.CodMacro AS macroId,
      s.Peso, 
      s.Rep,
      s.IdSerie AS serieId,
      em.MacroOrder
    FROM 
      Macro m
    LEFT JOIN 
      Exer_Macro em ON m.IdMacro = em.CodMacro
    LEFT JOIN 
      Exer e ON em.CodExer = e.IdExer
    LEFT JOIN 
      Serie s ON e.IdExer = s.CodExer
    WHERE 
      m.IdMacro = ${widget.macroId}
    """);

      print("fetchMacroDetails called");
      print(result);

      // Extract macro-level details: RSerie, RExer, and quantity
      final macroQuantity = result.isNotEmpty ? result.first['quantity'] as int? : 1;
      final rSerie = result.isNotEmpty && result.first['RSerie'] != null ? result.first['RSerie'] as int : 0;
      final rExer = result.isNotEmpty && result.first['RExer'] != null ? result.first['RExer'] as int : 0;

      // Group exercises by exercise ID
      Map<int, List<Map<String, dynamic>>> groupedExercises = {};
      for (var row in result) {
        final exerciseId = row['id'];
        final exerciseDetails = {
          'Peso': row['Peso'] ?? 0,
          'Rep': row['Rep'] ?? 0,
          'serieId': row['serieId'] ?? 0,
          'exerciseName': row['exerciseName'] ?? '',
        };

        // Grouping the exercises by their id
        if (groupedExercises.containsKey(exerciseId)) {
          groupedExercises[exerciseId]?.add(exerciseDetails);
        } else {
          groupedExercises[exerciseId] = [exerciseDetails];
        }
      }

      // Prepare a list for UI display, with grouped exercises and their respective details
      List<Map<String, dynamic>> allExercises = [];
      groupedExercises.forEach((id, details) {
        allExercises.add({
          'id': id,
          'exerciseName': details.first['exerciseName'],
          'sets': details, // Multiple Peso/Rep values for each exercise
        });
      });

      setState(() {
        quantity = macroQuantity ?? 1; // Default to 1 if null
        this.rSerie = rSerie; // Set RSerie at the macro level
        this.rExer = rExer; // Set RExer at the macro level
        exercises = allExercises;
        isLoading = false; // Done loading
      });
    } catch (error) {
      print('Error fetching macro details: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data. Please try again later.')),
      );
      setState(() {
        isLoading = false; // Stop loading even on error
      });
    }
  }

  // Toggle exercise selection
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
    try {
      // Update macro quantity, reps per series, and reps per exercise
      await dbHelper.customQuery("""
        UPDATE Macro 
        SET Qtt = $quantity, RSerie = $rSerie, RExer = $rExer 
        WHERE IdMacro = ${widget.macroId}
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
    } catch (error) {
      print('Error saving macro changes: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: secondaryColor),
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Macro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveMacroChanges,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : Column(
              children: [
                // Display Macro-Level Details: Quantity, RSerie, RExer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: $quantity', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('RSerie: $rSerie', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('RExer: $rExer', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      var exercise = exercises[index];
                      return Card(
                          color: accentColor1,
                          margin: EdgeInsets.all(5),
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Text(
                                    exercise['exerciseName'],
                                    style: TextStyle(color: secondaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    onPressed: null,
                                    icon: const Icon(Icons.edit, color: secondaryColor),
                                  )
                                ],
                              ),
                              iconColor: secondaryColor,
                              collapsedIconColor: secondaryColor,
                              children: [
                                ...exercise['sets'].map<Widget>((set) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Weight: ${set['Peso']}kg,   Reps: ${set['Rep']}',
                                          style: TextStyle(color: secondaryColor, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ));
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
