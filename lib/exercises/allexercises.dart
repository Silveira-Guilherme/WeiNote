import 'package:flutter/material.dart';
import 'package:gymdo/exercises/createexec.dart';
import 'package:gymdo/exercises/editexec.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class AllExercisesPage extends StatefulWidget {
  const AllExercisesPage({Key? key}) : super(key: key);

  @override
  _AllExercisesPageState createState() => _AllExercisesPageState();
}

class _AllExercisesPageState extends State<AllExercisesPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> exercises = [];
  List<bool> expandedList = [];

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  // Fetch exercises with their respective weights and repetitions from the database
  Future<void> fetchExercises() async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery("""
      SELECT e.IdExer, e.Name, GROUP_CONCAT(s.Peso) AS Pesos, GROUP_CONCAT(s.Rep) AS Reps
      FROM Exer e 
      LEFT JOIN Serie s ON e.IdExer = s.CodExer
      GROUP BY e.IdExer
      """);

    setState(() {
      exercises = queryResult;
      print(exercises);
      expandedList = List.generate(exercises.length, (index) => false);
    });
  }

  // Toggle expanded state for exercise details
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'All Exercises',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: exercises.isEmpty
          ? const Center(child: Text("No Exercises Found"))
          : ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                var exercise = exercises[index];

                // Split the Pesos and Reps strings into lists
                List<String> pesos = (exercise['Pesos'] ?? '').split(',');
                List<String> reps = (exercise['Reps'] ?? '').split(',');

                return Card(
                  margin: const EdgeInsets.all(10.0),
                  color: accentColor1,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: ExpansionTile(
                      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(
                          exercise['Name'] ?? 'Exercise',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: secondaryColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditExercisePage(
                                  exerciseId: exercise['IdExer'],
                                  onSave: () {
                                    fetchExercises();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ]),
                      iconColor: secondaryColor,
                      collapsedIconColor: secondaryColor,
                      onExpansionChanged: (expanded) {
                        toggleExpanded(index);
                      },
                      children: pesos.isEmpty || pesos[0].isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'No weights or reps recorded',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ),
                            ]
                          : List.generate(pesos.length, (i) {
                              String peso = pesos[i];
                              String rep = reps[i];
                              //print(rep);
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  'Weight: $peso kg, Reps: $rep',
                                  style: const TextStyle(fontSize: 14, color: secondaryColor),
                                ),
                              );
                            }),
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
              builder: (context) => CreateExercisePage(),
            ),
          ).then((_) {
            fetchExercises(); // Refresh the list after adding a new exercise
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
