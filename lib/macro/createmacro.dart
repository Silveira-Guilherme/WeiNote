import 'package:flutter/material.dart';
import '/../sql.dart';

class CreateMacroPage extends StatefulWidget {
  const CreateMacroPage({Key? key}) : super(key: key);

  @override
  _CreateMacroPageState createState() => _CreateMacroPageState();
}

class _CreateMacroPageState extends State<CreateMacroPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  int? quantity;
  int? restSeries;
  int? restExercise;
  List<Map<String, dynamic>> exercises = [];
  List<int> selectedExerciseIds = [];

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  // Fetch exercises to display in the selection list
  Future<void> fetchExercises() async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery("SELECT * FROM Exer");
    setState(() {
      exercises = queryResult;
    });
  }

  // Save the macro and associated exercises
  Future<void> saveMacro() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Insert the new macro into the Macro table
      int newMacroId = await dbHelper.addMacro(
        quantity!,
        restSeries!,
        restExercise!,
      );

      // Insert selected exercises into Exer_Macro table
      for (int exerId in selectedExerciseIds) {
        await dbHelper.addExerMacro(
          newMacroId,
          exerId,
          selectedExerciseIds.indexOf(exerId) + 1,
        );
      }

      // Navigate back after saving
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Create Circuit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Quantity Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantity (Qtt)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a quantity' : null,
                onSaved: (value) => quantity = int.tryParse(value!),
              ),
              // Rest Between Series Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Rest Between Series (seconds)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter rest time between series' : null,
                onSaved: (value) => restSeries = int.tryParse(value!),
              ),
              // Rest Between Exercises Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Rest Between Exercises (seconds)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter rest time between exercises' : null,
                onSaved: (value) => restExercise = int.tryParse(value!),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Exercises for the Circuit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Display exercises with checkboxes
              exercises.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        var exercise = exercises[index];
                        return CheckboxListTile(
                          title: Text(exercise['Name'] ?? 'Unnamed Exercise'),
                          value: selectedExerciseIds.contains(exercise['IdExer']),
                          onChanged: (isChecked) {
                            setState(() {
                              if (isChecked ?? false) {
                                selectedExerciseIds.add(exercise['IdExer']);
                              } else {
                                selectedExerciseIds.remove(exercise['IdExer']);
                              }
                            });
                          },
                        );
                      },
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveMacro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save Circuit',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
