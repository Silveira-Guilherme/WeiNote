import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/macro/createmacro.dart';
import 'package:gymdo/macro/editmacro.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class AllMacrosPage extends StatefulWidget {
  final VoidCallback onSave;
  const AllMacrosPage({super.key, required this.onSave});

  @override
  AllMacrosPageState createState() => AllMacrosPageState();
}

class AllMacrosPageState extends State<AllMacrosPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> macros = [];
  List<bool> expandedList = [];
  bool isDeleteMode = false; // Toggle for delete mode
  Set<int> selectedMacros = {}; // Track selected macro IDs

  @override
  void initState() {
    super.initState();
    fetchMacros();
  }

  Future<void> fetchMacros() async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery("""
    SELECT 
      m.IdMacro, 
      m.Qtt, 
      m.RSerie, 
      m.RExer, 
      e.Name AS ExerciseName, 
      em.MacroOrder,
      s.Peso, 
      s.Rep
    FROM 
      Macro m
    LEFT JOIN 
      Exer_Macro em ON m.IdMacro = em.CodMacro
    LEFT JOIN 
      Exer e ON em.CodExer = e.IdExer
    LEFT JOIN 
      Serie s ON e.IdExer = s.CodExer
    ORDER BY 
      m.IdMacro, em.MacroOrder, s.IdSerie;
  """);

    Map<int, List<Map<String, dynamic>>> groupedMacros = {};

    for (var row in queryResult) {
      int macroId = row['IdMacro'];

      if (!groupedMacros.containsKey(macroId)) {
        groupedMacros[macroId] = [];
      }

      var existingExercise = groupedMacros[macroId]!.firstWhere(
        (exercise) => exercise['ExerciseName'] == row['ExerciseName'],
        orElse: () => {},
      );

      if (existingExercise.isEmpty) {
        groupedMacros[macroId]!.add({
          'ExerciseName': row['ExerciseName'],
          'MacroOrder': row['MacroOrder'],
          'Sets': [
            {
              'Peso': row['Peso'],
              'Rep': row['Rep'],
            }
          ],
        });
      } else {
        existingExercise['Sets'].add({
          'Peso': row['Peso'],
          'Rep': row['Rep'],
        });
      }
    }

    List<Map<String, dynamic>> formattedMacros = [];
    for (var macroId in groupedMacros.keys) {
      var firstRow = queryResult.firstWhere((row) => row['IdMacro'] == macroId);
      formattedMacros.add({
        'IdMacro': macroId,
        'Qtt': firstRow['Qtt'],
        'RSerie': firstRow['RSerie'],
        'RExer': firstRow['RExer'],
        'Exercises': groupedMacros[macroId],
      });
    }

    setState(() {
      macros = formattedMacros;
      expandedList = List.generate(macros.length, (index) => false);
    });
  }

  void toggleExpanded(int index) {
    setState(() {
      expandedList[index] = !expandedList[index];
    });
  }

  void toggleSelection(int macroId) {
    setState(() {
      if (selectedMacros.contains(macroId)) {
        selectedMacros.remove(macroId);
      } else {
        selectedMacros.add(macroId);
      }
    });
  }

  Future<void> deleteSelectedMacros(int macroId) async {
    for (int macroId in selectedMacros) {
      await dbHelper.customQuery("DELETE FROM Tr_Macro WHERE CodMacro = $macroId");
      await dbHelper.customQuery("DELETE FROM Exer_Macro WHERE CodMacro = $macroId");
      await dbHelper.customQuery("DELETE FROM Macro WHERE IdMacro = $macroId");
    }
    setState(() {
      isDeleteMode = false;
      selectedMacros.clear();
    });
    fetchMacros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: secondaryColor),
        title: Text(
          isDeleteMode ? 'Delete Mode' : 'All Circuits',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
            color: secondaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: macros.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: macros.length,
              itemBuilder: (context, index) {
                var macro = macros[index];
                List<Map<String, dynamic>> exercises = macro['Exercises'];

                return Card(
                  margin: const EdgeInsets.all(10),
                  color: accentColor1,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ExpansionTile(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Circuit ${macro['IdMacro']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qtt: ${macro['Qtt']}, RSerie: ${macro['RSerie']}, RExer: ${macro['RExer']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Edit Icon
                              if (isDeleteMode)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteSelectedMacros(macro['IdMacro']),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: secondaryColor),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditMacroPage(
                                        macroId: macro['IdMacro'].toString(),
                                        onSave: fetchMacros,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Conditionally show Delete Icon based on delete mode
                            ],
                          ),
                          iconColor: secondaryColor,
                          collapsedIconColor: secondaryColor,
                          children: exercises.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'No exercises in this macro',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ]
                              : exercises.map((exercise) {
                                  List<Map<String, dynamic>> sets = exercise['Sets'];

                                  return ExpansionTile(
                                    title: Text(
                                      exercise['ExerciseName'],
                                      style: const TextStyle(
                                        color: secondaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    iconColor: secondaryColor,
                                    collapsedIconColor: secondaryColor,
                                    children: sets.isEmpty
                                        ? [
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                'No sets available',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : sets.map((set) {
                                            return Padding(
                                              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Peso: ${set['Peso']}, Reps: ${set['Rep']}',
                                                    style: const TextStyle(
                                                      color: secondaryColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                  );
                                }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        overlayOpacity: 0.5,
        spacing: 12,
        children: [
          SpeedDialChild(
            backgroundColor: accentColor2,
            foregroundColor: Colors.white,
            label: 'Create Circuit',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateMacroPage(
                    onSave: fetchMacros,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: isDeleteMode ? 'Disable Delete Mode' : 'Enable Delete Mode',
            foregroundColor: secondaryColor,
            backgroundColor: primaryColor,
            onTap: () {
              setState(() {
                isDeleteMode = !isDeleteMode;
              });
            },
          ),
        ],
      ),
    );
  }
}
