import 'package:flutter/material.dart';
import 'package:gymdo/exercises/createexec.dart';
import '/../sql.dart'; // Adjust your import
import 'package:gymdo/trainings/trainings.dart'; // Import the Training class

class ExerciseListPage extends StatefulWidget {
  final Training
      training; // Accept the whole Training object instead of just the ID

  const ExerciseListPage({Key? key, required this.training}) : super(key: key);

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> exercises = [];
  List<bool> expandedList = [];
  List<bool> completed = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  // Fetch exercises from the database
  Future<void> fetchExercises() async {
    setState(() {
      isLoading = true;
    });
    List<Map<String, dynamic>> queryResult =
        await dbHelper.customQuery("SELECT * FROM Exer");
    setState(() {
      exercises = queryResult;
      expandedList = List.generate(exercises.length, (index) => false);
      completed = List.generate(exercises.length, (index) => false);
      isLoading = false;
    });
  }

  // Change expanded state for exercise details
  void changeExpanded(bool isExpanded, int index) {
    setState(() {
      expandedList[index] = isExpanded;
    });
  }

  // Change the completed state of the exercise
  void changeValue(bool isCompleted, int index) {
    setState(() {
      completed[index] = isCompleted;
    });
  }

  // Submit selected exercises to the Tr_Exer table
  void submitExercises() async {
    for (int i = 0; i < exercises.length; i++) {
      if (completed[i]) {
        int exerciseId = exercises[i]['IdExer'];
        await dbHelper.customQuery(
            "INSERT INTO Tr_Exer (CodExer, CodTr) VALUES ($exerciseId, ${widget.training.id})"); // Use the training ID from the Training object
      }
    }

    // Go back after saving exercises
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
            'Select Exercises for ${widget.training.name}'), // Display the training name in the title
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      var exercise = exercises[index];
                      return Column(
                        children: [
                          Card(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 5),
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.black,
                                      child: Text(
                                        (index + 1).toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    Text(
                                      exercise['Name'] ?? 'Exercise',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Checkbox(
                                      value: completed[index],
                                      onChanged: (value) {
                                        changeValue(value!, index);
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: Icon(expandedList[index]
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                      onPressed: () {
                                        changeExpanded(
                                            !expandedList[index], index);
                                      },
                                    ),
                                  ],
                                ),
                                if (expandedList[index])
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Column(
                                      children: [
                                        Text(
                                            'Additional details about the exercise'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: submitExercises,
                  child: const Text('Submit Selected Exercises'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 76, 35, 35),
                    padding: const EdgeInsets.all(
                        16.0), // Increase padding for better appearance
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateExercisePage(), // Navigate to CreateExercisePage
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
