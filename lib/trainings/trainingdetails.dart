import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/exercises/selectexec.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class TrainingDetailsPage extends StatefulWidget {
  final int trainingId;

  const TrainingDetailsPage({super.key, required this.trainingId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  String trainingName = '';
  String trainingType = ''; // Store training type
  List<String> trainingDays = [];
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  Future<void> fetchTrainingDetails() async {
    // Fetch training details and update the state
    List<Map<String, dynamic>> trainingResult = await dbHelper.customQuery(
        "SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");
    List<Map<String, dynamic>> daysResult = await dbHelper.customQuery(
        "SELECT Day FROM Tr_Day WHERE CodTr = ${widget.trainingId}");
    List<Map<String, dynamic>> exercisesResult = await dbHelper.customQuery(
        "SELECT Exer.Name FROM Exer INNER JOIN Tr_Exer ON Exer.IdExer = Tr_Exer.CodExer WHERE Tr_Exer.CodTr = ${widget.trainingId}");

    setState(() {
      trainingName = trainingResult.isNotEmpty
          ? trainingResult[0]['Name']
          : 'Unnamed Training';
      trainingType = trainingResult.isNotEmpty
          ? trainingResult[0]['Type'] ?? 'No type specified'
          : 'No type specified';
      trainingDays = daysResult.map((day) => day['Day'].toString()).toList();
      exercises = exercisesResult;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTrainingDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(70.0), // Adjust the height of the AppBar
        child: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(
            color: secondaryColor, // Change the back button color to white
          ),
          title: const Text(
            'Training Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0, // Adjust the font size
              color: secondaryColor,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Training name section
                    Text(
                      trainingName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: $trainingType',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Training days section with Chips
                    const Text(
                      'Training Days:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: trainingDays.isNotEmpty
                          ? trainingDays
                              .map((day) => Chip(
                                    label: Text(
                                      day,
                                      style: TextStyle(color: secondaryColor),
                                    ),
                                    backgroundColor: primaryColor,
                                    labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ))
                              .toList()
                          : [
                              const Text(
                                'No days selected',
                                style: TextStyle(color: primaryColor),
                              )
                            ],
                    ),
                    const SizedBox(height: 20),

                    // Exercises section
                    const Text(
                      'Exercises:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    exercises.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exercises.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6.0, horizontal: 0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black87,
                                    child: Text(
                                      '${index + 1}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    exercises[index]['Name'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Text(
                            'No exercises associated with this training.',
                            style: TextStyle(color: Colors.black54),
                          ),
                  ],
                ),
              ),
            ),

      // Floating Action Button with Speed Dial
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        overlayOpacity: 0.3,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Add Exercises',
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseListPage(
                    trainingId: widget.trainingId,
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Edit Training',
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            onTap: () {
              // Implement Edit Training logic here
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.visibility),
            label: 'All Trainings',
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            onTap: () {
              // Implement view all trainings logic here
            },
          ),
        ],
      ),
    );
  }
}
