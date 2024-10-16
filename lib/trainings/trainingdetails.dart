import 'package:flutter/material.dart';
import 'package:gymdo/trainings/selectexec.dart';
import '/../sql.dart';
// Make sure to import the ExerciseListPage

class TrainingDetailsPage extends StatefulWidget {
  final int trainingId;

  TrainingDetailsPage({required this.trainingId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String trainingName = '';
  List<String> trainingDays = [];
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  Future<void> fetchTrainingDetails() async {
    // Fetch training name, days, and exercises
    List<Map<String, dynamic>> trainingResult = await dbHelper
        .customQuery("SELECT Name FROM Tr WHERE IdTr = ${widget.trainingId}");

    List<Map<String, dynamic>> daysResult = await dbHelper.customQuery(
        "SELECT Day FROM Tr_Day WHERE CodTr = ${widget.trainingId}");

    List<Map<String, dynamic>> exercisesResult = await dbHelper.customQuery(
        "SELECT Exer.Name FROM Exer INNER JOIN Tr_Exer ON Exer.IdExer = Tr_Exer.CodExer WHERE Tr_Exer.CodTr = ${widget.trainingId}");

    setState(() {
      trainingName = trainingResult.isNotEmpty
          ? trainingResult[0]['Name']
          : 'Unnamed Training';
      trainingDays = daysResult.map((day) => day['Day'].toString()).toList();
      exercises = exercisesResult;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTrainingDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Training Details',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training Name: $trainingName',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  const Text('Training Days:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(trainingDays.isNotEmpty
                      ? trainingDays.join(", ")
                      : 'No days selected'),
                  const SizedBox(height: 20),
                  const Text('Exercises:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: exercises.isNotEmpty
                        ? ListView.builder(
                            itemCount: exercises.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  title: Text(exercises[index]['Name']),
                                ),
                              );
                            },
                          )
                        : const Text(
                            'No exercises associated with this training.'),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseListPage(
                  trainingId: widget.trainingId), // Pass trainingId here
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
