import 'package:flutter/material.dart';
import 'package:gymdo/exercises/createexec.dart';
import '/../sql.dart';

class ExerciseListPage extends StatefulWidget {
  final int trainingId;

  const ExerciseListPage({Key? key, required this.trainingId})
      : super(key: key);

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

  void submitExercises() async {
    // Fetch the maximum order value for the current training's exercises
    var lastOrderQuery = await dbHelper.customQuery(
      "SELECT MAX(ExerOrder) as lastOrder FROM Tr_Exer WHERE CodTr = ${widget.trainingId}",
    );
    int lastOrder = lastOrderQuery[0]['lastOrder'] ?? 0;

    // Iterate through each exercise and add those marked as completed
    for (int i = 0; i < exercises.length; i++) {
      if (completed[i]) {
        int exerciseId = exercises[i]['IdExer'];
        lastOrder += 1; // Increment order for each new exercise

        await dbHelper.customQuery(
          "INSERT INTO Tr_Exer (CodExer, CodTr, ExerOrder) VALUES ($exerciseId, ${widget.trainingId}, $lastOrder)",
        );
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Select Exercises',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: submitExercises,
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      var exercise = exercises[index];
                      return GestureDetector(
                        onTap: () {
                          changeValue(!completed[index], index);
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: completed[index]
                              ? const Color.fromARGB(255, 220, 237, 200)
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black,
                                    child: Text(
                                      (index + 1).toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    exercise['Name'] ?? 'Exercise',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Checkbox(
                                    value: completed[index],
                                    onChanged: (value) {
                                      changeValue(value!, index);
                                    },
                                  ),
                                  onTap: () {
                                    changeExpanded(!expandedList[index], index);
                                  },
                                ),
                                if (expandedList[index])
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'Additional details about the exercise',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
              builder: (context) => CreateExercisePage(),
            ),
          );
        },
        child: const Icon(Icons.add), // Adding the plus icon
      ),
    );
  }
}
