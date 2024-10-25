import 'package:flutter/material.dart';
import 'package:gymdo/exercises/editexec.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class EditTrainingPage extends StatefulWidget {
  final int trainingId; // Existing training ID to edit
  final VoidCallback onSave; // Callback to trigger on save

  EditTrainingPage({required this.trainingId, required this.onSave});

  @override
  _EditTrainingPageState createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  late TextEditingController trainingNameController;
  late TextEditingController trainingTypeController;
  List<Map<String, dynamic>> exercises = []; // Store exercises with their IDs
  List<TextEditingController> exerciseControllers = [];
  List<List<Map<String, dynamic>>> seriesData = []; // Store series and weights
  List<String> weekDays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];
  List<bool> selectedDays = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    trainingNameController = TextEditingController();
    trainingTypeController = TextEditingController();
    fetchTrainingData();
  }

  Future<void> fetchTrainingData() async {
    final dbHelper = DatabaseHelper();

    // Fetch training details
    var trainingDetails = await dbHelper.customQuery(
        "SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");

    if (trainingDetails.isNotEmpty) {
      trainingNameController.text = trainingDetails[0]['Name'] ?? '';
      trainingTypeController.text = trainingDetails[0]['Type'] ?? '';
    }

    // Fetch exercises for the training
    var exercisesResult = await dbHelper.customQuery(
        "SELECT Exer.IdExer, Exer.Name FROM Exer INNER JOIN Tr_Exer ON Exer.IdExer = Tr_Exer.CodExer WHERE Tr_Exer.CodTr = ${widget.trainingId}");

    // Initialize controllers for exercises and weights
    for (var exercise in exercisesResult) {
      exercises.add({'id': exercise['IdExer'], 'name': exercise['Name']});
      exerciseControllers.add(TextEditingController(text: exercise['Name']));
      List<Map<String, dynamic>> tempSeries = [];

      // Fetch weights and series information for each exercise
      var seriesResult = await dbHelper.customQuery(
          "SELECT s.Peso, s.Rep as Repetitions FROM Serie s, Tr_Exer e WHERE s.CodExer=e.CodExer and e.CodExer = ${exercise['IdExer']} AND e.CodTr = ${widget.trainingId}");

      for (var series in seriesResult) {
        tempSeries.add(
            {'weight': series['Peso'], 'repetitions': series['Repetitions']});
      }
      seriesData.add(tempSeries);
    }

    // Fetch training days
    var daysResult = await dbHelper.customQuery(
        "SELECT Day FROM Tr_Day WHERE CodTr = ${widget.trainingId}");

    // Mark selected days
    for (int i = 0; i < weekDays.length; i++) {
      if (daysResult
          .map((day) => day['Day'].toLowerCase())
          .contains(weekDays[i].toLowerCase())) {
        selectedDays[i] = true;
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    trainingNameController.dispose();
    trainingTypeController.dispose();
    for (var controller in exerciseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveTraining() async {
    String trainingName = trainingNameController.text;
    String trainingType = trainingTypeController.text;

    if (trainingName.isEmpty || trainingType.isEmpty) {
      _showErrorDialog(
          'Please provide both a name and a type for the training.');
      return;
    }

    final dbHelper = DatabaseHelper();

    // Update training name and type
    await dbHelper.updateTraining(
        widget.trainingId, trainingName, trainingType);

    // Update exercises with IDs
    for (int i = 0; i < exerciseControllers.length; i++) {
      String exerciseName = exerciseControllers[i].text;
      int exerciseId = exercises[i]['id']; // Retrieve the exercise ID

      if (exerciseName.isEmpty) {
        _showErrorDialog('Exercise name cannot be empty');
        return;
      }

      await dbHelper.customQuery("UPDATE Exer SET Name = ? WHERE IdExer = ?",
          [exerciseName, exerciseId] as String?);
    }

    // Clear and reinsert training days
    await dbHelper.clearTrainingDays(widget.trainingId);
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        String day = weekDays[i];
        await dbHelper.insertTrainingDay(widget.trainingId, day);
      }
    }

    widget.onSave();
    Navigator.pop(context);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Function to show edit exercise dialog
  void _showEditExerciseDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exerciseControllers[index],
                decoration: const InputDecoration(labelText: 'Exercise Name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                setState(() {}); // Refresh the UI
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Training',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveTraining,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: trainingNameController,
                decoration: const InputDecoration(labelText: 'Training Name'),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: trainingTypeController,
                decoration: const InputDecoration(labelText: 'Training Type'),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text(
                'Training Days:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                children: List.generate(weekDays.length, (index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      setState(() {
                        selectedDays[index] = !selectedDays[index];
                      });
                    },
                    child: Chip(
                      side: BorderSide(
                        color: primaryColor, // Set your color here
                        width: 2, // Set the border width here
                      ),
                      label: Text(
                        weekDays[index],
                        style: TextStyle(
                          color: selectedDays[index]
                              ? secondaryColor
                              : primaryColor,
                        ),
                      ),
                      backgroundColor:
                          selectedDays[index] ? primaryColor : secondaryColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                'Exercises:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.all(5.0),
                    color:
                        accentColor1, // Ensure this color is defined in your main.dart
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exercises[index]['name'],
                              style: const TextStyle(
                                color:
                                    secondaryColor, // Ensure this color is defined
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: secondaryColor),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditExercisePage(
                                      exerciseId: exercises[index][
                                          'id'], // The ID of the exercise to edit
                                      onSave: () {
                                        // Refresh the exercise list or update UI after saving
                                      },
                                    ),
                                  ),
                                );
                                print("hahahahah");
                              },
                            ),
                          ],
                        ),
                        iconColor: secondaryColor, // Adjust icon color
                        collapsedIconColor: secondaryColor,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...seriesData[index].map((series) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      '${series['weight']} kg x${series['repetitions']} Reps',
                                      style: TextStyle(color: secondaryColor),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to add exercise inputs can be implemented here if needed
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
