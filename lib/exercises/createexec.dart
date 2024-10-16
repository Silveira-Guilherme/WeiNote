import 'package:flutter/material.dart';
import '/../sql.dart'; // Ensure this points to your database helper

class CreateExercisePage extends StatefulWidget {
  @override
  _CreateExercisePageState createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController exerciseNameController = TextEditingController();
  final List<TextEditingController> pesoControllers = [];
  final List<TextEditingController> repControllers = [];
  bool isLoading = false;

  // Function to create a new exercise
  void createExercise() async {
    String exerciseName = exerciseNameController.text;

    if (exerciseName.isEmpty) {
      // Show a message if the exercise name is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Insert the new exercise into the database
      await dbHelper
          .customQuery("INSERT INTO Exer (Name) VALUES ('$exerciseName')");

      // Retrieve the last inserted exercise ID
      List<Map<String, dynamic>> exerciseIdResult =
          await dbHelper.customQuery("SELECT last_insert_rowid() AS id");
      int id = exerciseIdResult.isNotEmpty
          ? exerciseIdResult[0]['id']
          : 0; // Get the ID from the result

      // Insert each series into the database
      for (int i = 0; i < pesoControllers.length; i++) {
        String peso = pesoControllers[i].text;
        String rep = repControllers[i].text;

        if (peso.isNotEmpty && rep.isNotEmpty) {
          await dbHelper.customQuery(
              "INSERT INTO Serie (Peso, Rep, CodExer) VALUES ($peso, $rep, $id)");
        }
      }

      // Clear the input fields after submission
      exerciseNameController.clear();
      for (var controller in pesoControllers) {
        controller.clear();
      }
      for (var controller in repControllers) {
        controller.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise created successfully.')),
      );
    } catch (error) {
      // Handle any error that may occur during database operations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      print(error);
    } finally {
      setState(() {
        isLoading = false;
      });

      // Navigate back to the previous page
      Navigator.pop(context);
    }
  }

  // Add new series inputs
  void addSeries() {
    pesoControllers.add(TextEditingController());
    repControllers.add(TextEditingController());
    setState(() {}); // Refresh the UI to show new fields
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Exercise'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: exerciseNameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Series Inputs
            const Text('Series:'),
            const SizedBox(height: 8),
            Column(
              children: List.generate(pesoControllers.length, (index) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pesoControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'Peso',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: repControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Remove the corresponding series input
                        pesoControllers.removeAt(index);
                        repControllers.removeAt(index);
                        setState(() {}); // Refresh the UI
                      },
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: addSeries,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text('Add Series'),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : createExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}
