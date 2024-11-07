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
  List<Map<String, dynamic>> exercisesAndMacros = [];
  List<TextEditingController> exerciseControllers = [];
  List<List<Map<String, dynamic>>> seriesData = [];
  List<Map<String, dynamic>> macros = [];
  List<Map<String, dynamic>> exercises = [];
  List<String> weekDays = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
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

    // Clear any existing data before fetching new data
    exercisesAndMacros.clear();
    exerciseControllers.clear();
    seriesData.clear();
    selectedDays = List.generate(7, (index) => false);

    // Fetch training details (Name and Type) for the specific training ID
    var trainingDetails = await dbHelper.customQuery("SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");

    if (trainingDetails.isNotEmpty) {
      trainingNameController.text = trainingDetails[0]['Name'] ?? '';
      trainingTypeController.text = trainingDetails[0]['Type'] ?? '';
    }

    // Fetch macros data
    await fetchMacros(dbHelper);

    // Fetch exercises data
    await fetchExercises(dbHelper);

    for (int i = 0; i < (macros.length + exercises.length); i++) {
      for (int j = 0; j < exercises.length; j++) {
        if (exercises[j]['order'] == i) {
          exercisesAndMacros.add(exercises[j]);
          break;
        }
      }
      for (int j = 0; j < macros.length; j++) {
        if (macros[j]['order'] == i) {
          exercisesAndMacros.add(macros[j]);
          break;
        }
      }
    }

    // Fetch and map training days to the weekDays list
    var daysResult = await dbHelper.customQuery("SELECT CodDay FROM Tr_Day WHERE CodTr = ${widget.trainingId}");

    for (var day in daysResult) {
      int idDay = day['CodDay'];
      if (idDay > 0 && idDay <= weekDays.length) {
        selectedDays[idDay - 1] = true;
      }
    }

    // Update the UI after data retrieval
    setState(() {});
  }

  Future<void> fetchMacros(DatabaseHelper dbHelper) async {
    macros.clear(); // Clear previous macros

    // Fetch macros for the current training
    var macrosResult = await dbHelper.customQuery("SELECT DISTINCT Macro.IdMacro, Macro.Qtt, Macro.RSerie, Macro.RExer, m.ExerOrder "
        "FROM Macro "
        "JOIN Tr_Macro m ON m.CodMacro = Macro.IdMacro "
        "WHERE m.CodTr = ${widget.trainingId}");

    for (var row in macrosResult) {
      List<Map<String, dynamic>> associatedExercises = [];

      // Fetch exercises for the current macro
      var exercisesResult = await dbHelper.customQuery("SELECT Exer.Name FROM Exer "
          "JOIN Exer_Macro ON Exer_Macro.CodExer = Exer.IdExer "
          "WHERE Exer_Macro.CodMacro = ${row['IdMacro']} ORDER BY Exer_Macro.MacroOrder");

      // Store associated exercises
      List<String> exerciseNames = [];
      for (var exercise in exercisesResult) {
        associatedExercises.add({'name': exercise['Name']});
        exerciseNames.add(exercise['Name']);
      }

      // Create a dynamic macro title
      String macroTitle = "Macro: ${exerciseNames.join(' - ')}";

      // Add macro to the exercisesAndMacros list
      macros.add({
        'type': 'macro',
        'id': row['IdMacro'],
        'title': macroTitle,
        'qtt': row['Qtt'],
        'rSerie': row['RSerie'],
        'rExer': row['RExer'],
        'exercises': associatedExercises,
        'order': row['ExerOrder'],
      });
    }
  }

  Future<void> fetchExercises(DatabaseHelper dbHelper) async {
    // Fetch exercises for the training
    var exercisesResult = await dbHelper.customQuery("SELECT Exer.IdExer, Exer.Name AS ExerName, Tr_Exer.ExerOrder FROM Exer "
        "LEFT JOIN Tr_Exer ON Exer.IdExer = Tr_Exer.CodExer "
        "WHERE Tr_Exer.CodTr = ${widget.trainingId} ORDER BY Tr_Exer.ExerOrder");

    int? currentExerciseId;
    List<Map<String, dynamic>> tempSeries = [];

    for (var row in exercisesResult) {
      int exerciseId = row['IdExer'];

      if (currentExerciseId == null || exerciseId != currentExerciseId) {
        if (tempSeries.isNotEmpty) {
          seriesData.add(tempSeries);
          tempSeries = [];
        }

        exercises.add({
          'type': 'exercise',
          'id': exerciseId,
          'name': row['ExerName'],
          'order': row['ExerOrder'],
        });
        exerciseControllers.add(TextEditingController(text: row['ExerName']));
        currentExerciseId = exerciseId;
      }

      // Add series data for the current exercise
      tempSeries.add({
        'weight': row['Peso'],
        'repetitions': row['Rep'],
      });
    }

    // Add the last exercise's series data if available
    if (tempSeries.isNotEmpty) {
      seriesData.add(tempSeries);
    }
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
      _showErrorDialog('Please provide both a name and a type for the training.');
      return;
    }

    final dbHelper = DatabaseHelper();

    // Update training name and type
    await dbHelper.updateTraining(widget.trainingId, trainingName, trainingType);

    for (int i = 0; i < exerciseControllers.length; i++) {
      String exerciseName = exerciseControllers[i].text;
      int exerciseId = exercisesAndMacros[i]['id'];

      if (exerciseName.isEmpty) {
        _showErrorDialog('Exercise name cannot be empty');
        return;
      }

      await dbHelper.updateExercise(exerciseId, exerciseName);
    }

    // Update training days by clearing and reinserting CodDay values
    await dbHelper.clearTrainingDays(widget.trainingId);
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        int idDay = i + 1;
        await dbHelper.insertTrainingDay(widget.trainingId, idDay);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Training',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.white),
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
                        color: primaryColor,
                        width: 2,
                      ),
                      label: Text(
                        weekDays[index],
                        style: TextStyle(
                          color: selectedDays[index] ? secondaryColor : primaryColor,
                        ),
                      ),
                      backgroundColor: selectedDays[index] ? primaryColor : secondaryColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                'Exercises & Macros:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercisesAndMacros.length,
                itemBuilder: (context, index) {
                  var item = exercisesAndMacros[index];

                  // Check if the item is a macro
                  if (item['type'] == 'macro') {
                    return Card(
                      margin: const EdgeInsets.all(5.0),
                      color: accentColor1,
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ExpansionTile(
                          title: Text(
                            item['title'], // This is the macro title
                            style: const TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: secondaryColor,
                          collapsedIconColor: secondaryColor,
                          children: [
                            ...item['exercises'].map((exercise) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  exercise['name'],
                                  style: TextStyle(color: secondaryColor),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  }

                  // Check if the item is an exercise
                  else if (item['type'] == 'exercise') {
                    return Card(
                      margin: const EdgeInsets.all(5.0),
                      color: accentColor1,
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ExpansionTile(
                          title: Text(
                            item['name'], // This is the exercise name
                            style: const TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: secondaryColor,
                          collapsedIconColor: secondaryColor,
                          children: [
                            // Ensure we're only accessing series data if it's valid
                            if (index < seriesData.length)
                              ...seriesData[index].map((series) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                    );
                  }

                  return Container(); // Fallback in case there's an unexpected item type
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to add macros inputs can be implemented here if needed
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
