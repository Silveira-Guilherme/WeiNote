import 'package:flutter/material.dart';
import 'package:gymdo/trainings/selectexec.dart';
import 'package:intl/intl.dart';
import '/../sql.dart';

class CPage extends StatefulWidget {
  @override
  _CPageState createState() => _CPageState();
}

class _CPageState extends State<CPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String data = '';
  DateTime now = DateTime.now();

  // List of weekdays and their selection state
  List<String> weekDays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];
  List<bool> selectedDays =
      List.generate(7, (index) => false); // 7 days initialized to false

  bool isLoading = false;

  // TextController for training name input
  TextEditingController trainingNameController = TextEditingController();

  // Initialize the state
  @override
  void initState() {
    super.initState();
    data = DateFormat('d', 'pt_BR').format(now).toString(); // Initial date
  }

  // Submit selected days and training name
  Future<int?> submitTraining() async {
    String trainingName = trainingNameController.text;
    if (trainingName.isEmpty) return null;

    // Process selected days
    List<String> selectedWeekDays = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        selectedWeekDays.add(weekDays[i]);
      }
    }

    if (selectedWeekDays.isNotEmpty) {
      // Insert the new training into the 'Tr' table and get the inserted IdTr
      int trainingId = await dbHelper.database.then((db) {
        return db.insert('Tr', {'Name': trainingName});
      });

      // Insert selected days into the 'Tr_Day' table using the new training ID
      for (String day in selectedWeekDays) {
        await dbHelper.database.then((db) {
          db.insert('Tr_Day', {
            'Day': day,
            'CodTr': trainingId, // Use the retrieved trainingId here
          });
        });
      }

      trainingNameController.clear();
      setState(() {
        selectedDays.fillRange(
            0, selectedDays.length, false); // Reset selection
      });

      return trainingId; // Return the newly created training ID
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(70.0), // Adjust the height of the AppBar
        child: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the back button color to white
          ),
          title: const Text(
            'Add Training Session',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0, // Adjust the font size
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Training Name Input
            TextField(
              controller: trainingNameController,
              decoration: const InputDecoration(
                labelText: "Training Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Day Selection Buttons
            const Text("Select Training Days:"),
            Wrap(
              spacing: 10,
              children: List.generate(weekDays.length, (index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedDays[index] ? Colors.black : Colors.white,
                    // Setting the text color based on the button's selected state
                    foregroundColor:
                        selectedDays[index] ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDays[index] =
                          !selectedDays[index]; // Toggle selection
                    });
                  },
                  child: Text(weekDays[index]),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Call submitTraining() and get the generated training ID
          int? trainingId = await submitTraining();

          if (trainingId != null) {
            // Navigate to the ExerciseListPage and pass the trainingId
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
