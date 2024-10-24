import 'package:flutter/material.dart';
import 'trainings.dart';
import '/../sql.dart';
import '/../mpage.dart';
// Adjust import according to your structure

class EditTrainingPage extends StatefulWidget {
  final Training training; // Existing training to edit
  final VoidCallback onSave; // Callback to trigger on save

  EditTrainingPage({required this.training, required this.onSave});

  @override
  _EditTrainingPageState createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  late TextEditingController trainingNameController;
  List<TextEditingController> exerciseControllers = [];
  List<List<TextEditingController>> weightControllers = [];

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
    trainingNameController = TextEditingController(text: widget.training.name);

    for (var exercise in widget.training.exercises) {
      exerciseControllers.add(TextEditingController(text: exercise.name));
      List<TextEditingController> tempWeights = [];
      for (var weight in exercise.weights) {
        tempWeights.add(TextEditingController(text: weight['Peso'].toString()));
      }
      weightControllers.add(tempWeights);
    }

    for (int i = 0; i < weekDays.length; i++) {
      if (widget.training.days
          .map((day) => day.toLowerCase())
          .contains(weekDays[i].toLowerCase())) {
        selectedDays[i] = true;
      }
    }
  }

  @override
  void dispose() {
    trainingNameController.dispose();
    for (var controller in exerciseControllers) {
      controller.dispose();
    }
    for (var list in weightControllers) {
      for (var controller in list) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> saveTraining() async {
    String trainingName = trainingNameController.text;
    if (trainingName.isEmpty) {
      _showErrorDialog('Training name cannot be empty');
      return;
    }

    // Update training name
    await DatabaseHelper().updateTraining(widget.training.id, trainingName);

    // Update exercises
    for (int i = 0; i < exerciseControllers.length; i++) {
      String exerciseName = exerciseControllers[i].text;
      if (exerciseName.isEmpty) {
        _showErrorDialog('Exercise name cannot be empty');
        return;
      }

      // Update exercise by id
      await DatabaseHelper()
          .updateExercise(widget.training.exercises[i].id, exerciseName);

      // Optionally handle weights update if necessary
      // Update weights logic goes here if needed
    }

    // Clear existing training days
    await DatabaseHelper().clearTrainingDays(widget.training.id);

    // Insert selected training days
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        String day = weekDays[i];
        await DatabaseHelper().insertTrainingDay(widget.training.id, day);
      }
    }
//widget.onSave();

    widget.onSave(); // Call the callback to refresh data on MPage
    Navigator.pop(context); // Go back after updating
    // Go back after updating
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
              Wrap(
                spacing: 10,
                children: List.generate(weekDays.length, (index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedDays[index] ? Colors.black : Colors.white,
                      foregroundColor:
                          selectedDays[index] ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedDays[index] = !selectedDays[index];
                      });
                    },
                    child: Text(weekDays[index]),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to add exercise inputs
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
