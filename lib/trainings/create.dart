import 'package:flutter/material.dart';
import 'package:gymdo/exercises/selectexec.dart';
import 'package:intl/intl.dart';
import '/../sql.dart';

class CPage extends StatefulWidget {
  const CPage({super.key});

  @override
  _CPageState createState() => _CPageState();
}

class _CPageState extends State<CPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String data = '';
  DateTime now = DateTime.now();

  // List of weekdays and their selection state
  List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  List<bool> selectedDays = List.generate(7, (index) => false); // 7 days initialized to false

  bool isLoading = false;

  // TextControllers for training name and type input
  TextEditingController trainingNameController = TextEditingController();
  TextEditingController trainingTypeController = TextEditingController();

  // Initialize the state
  @override
  void initState() {
    super.initState();
    data = DateFormat('d', 'en_US').format(now).toString(); // Initial date
  }

  // Submit selected days, training name, and type
  Future<int?> submitTraining() async {
    String trainingName = trainingNameController.text;
    String trainingType = trainingTypeController.text;

    if (trainingName.isEmpty || trainingType.isEmpty) return null;

    // Process selected days
    List<int> selectedWeekDays = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        // Convert weekday names to corresponding IDs (1-7 for Mon-Sun)
        selectedWeekDays.add(i + 1); // Assuming 1 = Segunda-feira, ..., 7 = Domingo
      }
    }

    if (selectedWeekDays.isNotEmpty) {
      // Insert the new training into the 'Tr' table with Name and Type
      int trainingId = await dbHelper.database.then((db) {
        return db.insert('Tr', {
          'Name': trainingName,
          'Type': trainingType, // Insert the training type
        });
      });

      // Insert selected days into the 'Tr_Day' table using the new training ID
      for (int day in selectedWeekDays) {
        await dbHelper.database.then((db) {
          db.insert('Tr_Day', {
            'CodDay': day, // Reference to the day ID
            'CodTr': trainingId, // Use the retrieved trainingId here
          });
        });
      }

      // Reset inputs after submission
      trainingNameController.clear();
      trainingTypeController.clear();
      setState(() {
        selectedDays.fillRange(0, selectedDays.length, false); // Reset selection
      });

      return trainingId; // Return the newly created training ID
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Adjust the height of the AppBar
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
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: submitTraining,
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Training Name Input
            TextField(
              controller: trainingNameController,
              decoration: InputDecoration(
                labelText: "Training Name",
                labelStyle: const TextStyle(color: Colors.black),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Training Type Input
            TextField(
              controller: trainingTypeController,
              decoration: InputDecoration(
                labelText: "Training Type",
                labelStyle: const TextStyle(color: Colors.black),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Day Selection Buttons
            const Text(
              "Select Training Days:",
              style: TextStyle(color: Colors.black),
            ),
            Wrap(
              spacing: 10,
              children: List.generate(weekDays.length, (index) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedDays[index] ? Colors.black : Colors.white,
                    // Setting the text color based on the button's selected state
                    foregroundColor: selectedDays[index] ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedDays[index] = !selectedDays[index]; // Toggle selection
                    });
                  },
                  child: Text(weekDays[index]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
