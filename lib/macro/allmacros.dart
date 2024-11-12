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
      SELECT m.IdMacro, m.Qtt, m.RSerie, m.RExer, GROUP_CONCAT(e.Name) AS Exercises
      FROM Macro m
      LEFT JOIN Exer_Macro em ON m.IdMacro = em.CodMacro
      LEFT JOIN Exer e ON em.CodExer = e.IdExer
      GROUP BY m.IdMacro
    """);

    setState(() {
      macros = queryResult;
      expandedList = List.generate(macros.length, (index) => false);
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
        iconTheme: const IconThemeData(
          color: secondaryColor, // Change the back button color to white
        ),
        backgroundColor: Colors.black,
        title: const Text(
          'All Circuits',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
                List<String> exercises = (macro['Exercises'] ?? '').split(',');

                return Card(
                  margin: const EdgeInsets.all(10),
                  color: accentColor1,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ExpansionTile(
                          // Title text with alignment
                          title: Column(
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
                              const SizedBox(height: 4), // Spacing between title and subtitle
                              Text(
                                'Qtt: ${macro['Qtt']}, RSerie: ${macro['RSerie']}, RExer: ${macro['RExer']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          // Row for the edit icon next to the expansion icon
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: secondaryColor),
                                onPressed: () {
                                  // Navigate to EditMacroPage when the icon is pressed
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditMacroPage(
                                        macroId: macro['IdMacro'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              // Expanded icon will appear automatically
                              const Icon(Icons.expand_more, color: secondaryColor),
                            ],
                          ),

                          iconColor: secondaryColor,
                          collapsedIconColor: secondaryColor,
                          onExpansionChanged: (expanded) {
                            toggleExpanded(index);
                          },
                          // Display exercises or show a message if none exist
                          children: exercises.isEmpty || exercises[0].isEmpty
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
                                  return Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      'Exercise: $exercise',
                                      style: const TextStyle(color: secondaryColor),
                                    ),
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
