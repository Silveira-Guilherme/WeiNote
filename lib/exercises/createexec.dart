// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart'; // Ensure this points to your database helper

class CreateExercisePage extends StatefulWidget {
  final VoidCallback onSave; // Callback to notify parent widget about changes

  const CreateExercisePage({super.key, required this.onSave});

  @override
  CreateExercisePageState createState() => CreateExercisePageState();
}

class CreateExercisePageState extends State<CreateExercisePage> {
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
      await dbHelper.customQuery("INSERT INTO Exer (Name) VALUES ('$exerciseName')");

      // Retrieve the last inserted exercise ID
      List<Map<String, dynamic>> exerciseIdResult = await dbHelper.customQuery("SELECT last_insert_rowid() AS id");
      int id = exerciseIdResult.isNotEmpty ? exerciseIdResult[0]['id'] : 0; // Get the ID from the result

      // Insert each series into the database
      for (int i = 0; i < pesoControllers.length; i++) {
        String peso = pesoControllers[i].text;
        String rep = repControllers[i].text;

        if (peso.isNotEmpty && rep.isNotEmpty) {
          await dbHelper.customQuery("INSERT INTO Serie (Peso, Rep, CodExer) VALUES ($peso, $rep, $id)");
        }
      }

      // Notify parent widget that the exercise has been saved
      widget.onSave();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise created successfully.')),
      );

      // Navigate back to the previous page
      Navigator.pop(context);
    } catch (error) {
      // Handle any error that may occur during database operations
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      //print(error);
    } finally {
      setState(() {
        isLoading = false;
      });
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(
            color: secondaryColor, // Change the back button color to white
          ),
          title: const Text(
            'Create Exercise',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0, // Adjust the font size
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: createExercise,
              color: Colors.white,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: exerciseNameController,
              cursorColor: Colors.black, // Set the cursor color to black
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                labelStyle: TextStyle(color: Colors.black), // Label color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Black border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Black border on focus
                ),
              ),
              style: const TextStyle(color: Colors.black), // Text color
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
                        cursorColor: Colors.black, // Set the cursor color to black
                        decoration: const InputDecoration(
                          labelText: 'Peso',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: repControllers[index],
                        cursorColor: Colors.black, // Set the cursor color to black
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: accentColor2,
                      ),
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
            ElevatedButton.icon(
              onPressed: addSeries,
              icon: const Icon(Icons.add, color: Colors.white), // Add icon
              label: const Text(
                'Add Series',
                style: TextStyle(color: Colors.white), // Button text color
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
