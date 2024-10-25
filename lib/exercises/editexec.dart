import 'package:flutter/material.dart';
import '/../sql.dart'; // Ensure you have the correct path to your SQL helper

class EditExercisePage extends StatefulWidget {
  final int exerciseId; // Existing exercise ID to edit
  final VoidCallback onSave; // Callback to trigger on save

  EditExercisePage({
    required this.exerciseId,
    required this.onSave,
  });

  @override
  _EditExercisePageState createState() => _EditExercisePageState();
}

class _EditExercisePageState extends State<EditExercisePage> {
  late TextEditingController nameController;
  List<Map<String, TextEditingController>> seriesControllers = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    _fetchExerciseDetails(); // Fetch exercise details from database
  }

  @override
  void dispose() {
    nameController.dispose();
    seriesControllers.forEach((controller) {
      controller['weight']?.dispose();
      controller['reps']?.dispose();
    });
    super.dispose();
  }

  // Fetch the exercise details from the database
  Future<void> _fetchExerciseDetails() async {
    final dbHelper = DatabaseHelper();

    // Fetch exercise details using the exercise ID
    final exerciseData = await dbHelper.getExerciseDetails(widget.exerciseId);

    if (exerciseData.isNotEmpty) {
      var exercise = exerciseData[0];
      setState(() {
        nameController.text = exercise['Name'];
        _fetchSeriesData(); // Fetch associated series data
      });
    }
  }

  // Fetch series data associated with the exercise
  Future<void> _fetchSeriesData() async {
    final dbHelper = DatabaseHelper();

    // Get the series data for the specific exercise ID
    final seriesData = await dbHelper.getSeriesByExerciseId(widget.exerciseId);

    setState(() {
      seriesControllers = seriesData.map((series) {
        return {
          'weight': TextEditingController(text: series['Peso'].toString()),
          'reps': TextEditingController(text: series['Rep'].toString()),
        };
      }).toList();
    });
  }

  // Add a new set of weight and reps
  void _addSet() {
    setState(() {
      seriesControllers.add({
        'weight': TextEditingController(),
        'reps': TextEditingController(),
      });
    });
  }

  // Remove a set of weight and reps
  void _removeSet(int index) {
    setState(() {
      seriesControllers.removeAt(index);
    });
  }

  Future<void> saveExercise() async {
    String exerciseName = nameController.text;

    // Validate inputs
    if (exerciseName.isEmpty || seriesControllers.isEmpty) {
      _showErrorDialog(
          'Please fill in the exercise name and at least one set.');
      return;
    }

    final dbHelper = DatabaseHelper();

    // Update exercise name
    await dbHelper.updateExercise(widget.exerciseId, exerciseName);

    // Update the series information
    for (var controller in seriesControllers) {
      String weightText = controller['weight']!.text;
      String repsText = controller['reps']!.text;

      // Validate individual weight and reps
      if (weightText.isEmpty || repsText.isEmpty) {
        _showErrorDialog('Please fill in all fields for each set.');
        return;
      }

      // Assume you have an update method to handle series data
      double weight = double.parse(weightText);
      int reps = int.parse(repsText);

      // Here we assume you have a method to update or insert the series,
      // otherwise you would need the series ID to update existing series.
      await dbHelper.updateSeries(widget.exerciseId, weight, reps);
    }

    widget.onSave(); // Trigger the save callback
    Navigator.pop(context); // Close the edit page
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Exercise',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveExercise,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Exercise Name'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: seriesControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: seriesControllers[index]['weight'],
                              decoration: const InputDecoration(
                                  labelText: 'Weight (kg)'),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: seriesControllers[index]['reps'],
                              decoration: const InputDecoration(
                                  labelText: 'Repetitions'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeSet(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addSet,
              child: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}
