import 'package:flutter/material.dart';
import 'package:gymdo/macro/createmacro.dart';
import 'package:gymdo/macro/editmacro.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class AllMacrosPage extends StatefulWidget {
  const AllMacrosPage({Key? key}) : super(key: key);

  @override
  _AllMacrosPageState createState() => _AllMacrosPageState();
}

class _AllMacrosPageState extends State<AllMacrosPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> macros = [];
  List<bool> expandedList = [];

  @override
  void initState() {
    super.initState();
    fetchMacros();
  }

  // Fetch macros and their exercises
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

    // Group exercises by macro
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

    // Format the final list of macros
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
      expandedList = List.generate(macros.length, (index) => false); // Initialize expandedList
    });
  }

  // Toggle expanded state for macro details
  void toggleExpanded(int index) {
    setState(() {
      expandedList[index] = !expandedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: secondaryColor), // Change the back button color to white
        backgroundColor: Colors.black,
        title: const Text(
          'All Circuits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        // This is the top ExpansionTile for each macro
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
                              Spacer(), // This pushes the edit icon to the far right
                              IconButton(
                                icon: const Icon(Icons.edit, color: secondaryColor),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditMacroPage(macroId: macro['IdMacro'].toString())),
                                  );
                                },
                              ),
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
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ),
                                ]
                              : exercises.map((exercise) {
                                  List<Map<String, dynamic>> sets = exercise['Sets'];

                                  return ExpansionTile(
                                    title: Text(
                                      exercise['ExerciseName'],
                                      style: TextStyle(
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
                                                style: TextStyle(fontSize: 14, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMacroPage(),
            ),
          ).then((_) {
            fetchMacros(); // Refresh the list after adding a new macro
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
