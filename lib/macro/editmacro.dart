// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class EditMacroPage extends StatefulWidget {
  final VoidCallback onSave;
  final String macroId;

  const EditMacroPage({super.key, required this.macroId, required this.onSave});

  @override
  EditMacroPageState createState() => EditMacroPageState();
}

class EditMacroPageState extends State<EditMacroPage> {
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
      // Fetching macro details
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

      // Parse results and update state
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

        if (groupedExercises.containsKey(exerciseId)) {
          groupedExercises[exerciseId]?.add(exerciseDetails);
        } else {
          groupedExercises[exerciseId] = [exerciseDetails];
        }
      }

      // Prepare exercises for UI display
      List<Map<String, dynamic>> allExercises = [];
      groupedExercises.forEach((id, details) {
        allExercises.add({
          'id': id,
          'exerciseName': details.first['exerciseName'],
          'sets': details,
        });
      });

      setState(() {
        quantity = macroQuantity ?? 1;
        this.rSerie = rSerie;
        this.rExer = rExer;
        exercises = allExercises;
        isLoading = false;
      });
    } catch (error) {
      //print('Error fetching macro details: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load data. Please try again later.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save changes to macro
  Future<void> saveMacroChanges() async {
    try {
      await dbHelper.customQuery("""
        UPDATE Macro 
        SET Qtt = $quantity, RSerie = $rSerie, RExer = $rExer 
        WHERE IdMacro = ${widget.macroId}
      """);

      Navigator.pop(context);
    } catch (error) {
      //print('Error saving macro changes: $error');
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Editable Quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity: ', style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                              ),
                              Text('$quantity', style: const TextStyle(fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Editable RSerie
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reps per Series (RSerie): ', style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: rSerie > 0 ? () => setState(() => rSerie--) : null,
                              ),
                              Text('$rSerie', style: const TextStyle(fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => rSerie++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Editable RExer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reps per Exercise (RExer): ', style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: rExer > 0 ? () => setState(() => rExer--) : null,
                              ),
                              Text('$rExer', style: const TextStyle(fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => rExer++),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Text(
                            exercise['exerciseName'],
                            style: const TextStyle(
                              color: secondaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: secondaryColor,
                          collapsedIconColor: secondaryColor,
                          children: [
                            ...exercise['sets'].map<Widget>((set) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      // Ensures the text spans the available space
                                      child: Text(
                                        'Weight: ${set['Peso']}kg,   Reps: ${set['Rep']}',
                                        style: const TextStyle(color: secondaryColor, fontSize: 14),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
