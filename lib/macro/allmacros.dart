import 'package:flutter/material.dart';
import 'package:gymdo/macro/createmacro.dart';
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
        backgroundColor: Colors.black,
        title: const Text(
          'All Macros',
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
                  margin: const EdgeInsets.all(5.0),
                  color: Colors.grey[200],
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      title: Text(
                        'Macro ${macro['IdMacro']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Qtt: ${macro['Qtt']}, RSerie: ${macro['RSerie']}, RExer: ${macro['RExer']}',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      iconColor: Colors.black,
                      collapsedIconColor: Colors.black,
                      onExpansionChanged: (expanded) {
                        toggleExpanded(index);
                      },
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
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              );
                            }).toList(),
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
