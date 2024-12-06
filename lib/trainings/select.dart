import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/main.dart';
import 'package:gymdo/trainings/create.dart';
import 'package:gymdo/trainings/trainingdetails.dart';
import '/../sql.dart'; // Import your database helper

class TrainingListPage extends StatefulWidget {
  const TrainingListPage({super.key});

  @override
  _TrainingListPageState createState() => _TrainingListPageState();
}

class _TrainingListPageState extends State<TrainingListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;
  bool isDeleteMode = false; // Toggle for delete mode

  // Fetch all trainings from the database
  Future<void> fetchTrainings() async {
    List<Map<String, dynamic>> queryResult = await dbHelper.customQuery("SELECT * FROM Tr");
    setState(() {
      trainings = queryResult;
      isLoading = false;
    });
  }

  // Delete a training from the database
  Future<void> deleteTraining(int trainingId) async {
    await dbHelper.customQuery("DELETE FROM Tr WHERE IdTr = $trainingId");
    fetchTrainings(); // Refresh the list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Training with ID $trainingId deleted.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTrainings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: secondaryColor),
          title: Text(
            isDeleteMode ? 'Delete Mode' : 'All Trainings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
              color: secondaryColor,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trainings.isEmpty
              ? const Center(child: Text('No trainings available.'))
              : ListView.builder(
                  itemCount: trainings.length,
                  itemBuilder: (context, index) {
                    var training = trainings[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      color: accentColor1,
                      elevation: 5,
                      child: InkWell(
                        onTap: () {
                          if (!isDeleteMode) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrainingDetailsPage(
                                  trainingId: training['IdTr'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                training['Name'] ?? 'Unnamed Training',
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isDeleteMode)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Show confirmation SnackBar
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Text('Confirm delete?'),
                                                const Spacer(),
                                                TextButton(
                                                  child: const Text(
                                                    'DELETE',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                  onPressed: () {
                                                    deleteTraining(training['IdTr']);
                                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                  },
                                                ),
                                              ],
                                            ),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: secondaryColor),
                                    onPressed: () {
                                      if (!isDeleteMode) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TrainingDetailsPage(
                                              trainingId: training['IdTr'],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        overlayOpacity: 0.5,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Add Training',
            foregroundColor: secondaryColor,
            backgroundColor: accentColor2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: isDeleteMode ? 'Disable Delete Mode' : 'Enable Delete Mode',
            foregroundColor: secondaryColor,
            backgroundColor: primaryColor,
            onTap: () {
              setState(() {
                isDeleteMode = !isDeleteMode;
              });
            },
          ),
        ],
      ),
    );
  }
}
