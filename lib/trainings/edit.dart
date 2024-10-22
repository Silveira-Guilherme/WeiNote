import 'package:flutter/material.dart';
import 'trainings.dart';

class EditTrainingPage extends StatefulWidget {
  final Training training; // Pass the existing training data to edit

  EditTrainingPage({required this.training});

  @override
  _EditTrainingPageState createState() => _EditTrainingPageState();
}

class _EditTrainingPageState extends State<EditTrainingPage> {
  late TextEditingController trainingNameController;
  List<TextEditingController> exerciseControllers = [];
  List<List<TextEditingController>> weightControllers = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    trainingNameController = TextEditingController(text: widget.training.name);

    for (var exercise in widget.training.exercises) {
      exerciseControllers.add(TextEditingController(text: exercise.name));
      List<TextEditingController> tempWeights = [];

      // Initialize weight controllers with existing weights
      for (var weight in exercise.weights) {
        tempWeights.add(TextEditingController(text: weight['Peso'].toString()));
      }
      weightControllers.add(tempWeights);
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

  // Function to add a new exercise
  void addExercise() {
    setState(() {
      exerciseControllers.add(TextEditingController());
      weightControllers
          .add([TextEditingController()]); // Start with one weight field
    });
  }

  // Function to remove an exercise
  void removeExercise(int index) {
    setState(() {
      exerciseControllers[index].dispose();
      exerciseControllers.removeAt(index);
      weightControllers[index].forEach((controller) => controller.dispose());
      weightControllers.removeAt(index);
    });
  }

  // Function to save the updated training
  void saveTraining() {
    // Collect updated data
    String updatedTrainingName = trainingNameController.text;
    List<Exercise> updatedExercises = [];

    for (int i = 0; i < exerciseControllers.length; i++) {
      List<Map<String, dynamic>> weights = [];
      for (var weightController in weightControllers[i]) {
        // Update reps accordingly (assuming default to "X" if not provided)
        weights.add({
          'Peso': weightController.text,
          'Rep': 'X' // Replace with actual rep input if you have it
        });
      }
      updatedExercises.add(
        Exercise(
          name: exerciseControllers[i].text,
          completed: false,
          isExpanded: false,
          weights: weights,
        ),
      );
    }

    // Return or update the training object with the new data
    Training updatedTraining =
        Training(name: updatedTrainingName, exercises: updatedExercises);

    // Navigate back with updated training
    Navigator.pop(context, updatedTraining);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveTraining,
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exerciseControllers.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: exerciseControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Exercise Name',
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeExercise(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: List.generate(
                          weightControllers[index].length,
                          (weightIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: TextFormField(
                                controller: weightControllers[index]
                                    [weightIndex],
                                decoration: InputDecoration(
                                  labelText: 'Weight ${weightIndex + 1}',
                                  labelStyle:
                                      const TextStyle(color: Colors.black),
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: addExercise,
                child: const Text('Add Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
