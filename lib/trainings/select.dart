import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gymdo/main.dart'; // Ensure this is correctly importing your colors
import 'package:gymdo/trainings/create.dart';
import 'package:gymdo/trainings/trainingdetails.dart';
import '/../sql.dart'; // Import your database helper

class TrainingListPage extends StatefulWidget {
  const TrainingListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TrainingListPageState createState() => _TrainingListPageState();
}

class _TrainingListPageState extends State<TrainingListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;

  // Fetch all trainings from the database
  Future<void> fetchTrainings() async {
    List<Map<String, dynamic>> queryResult =
        await dbHelper.customQuery("SELECT * FROM Tr");
    setState(() {
      trainings = queryResult;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTrainings(); // Load trainings when the page is initialized
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
            'All Trainings',
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
          : trainings.isEmpty
              ? const Center(child: Text('No trainings available.'))
              : ListView.builder(
                  itemCount: trainings.length,
                  itemBuilder: (context, index) {
                    var training = trainings[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      color:
                          accentColor1, // Ensure this color is defined in your main.dart
                      elevation: 5,
                      child: InkWell(
                        // Use InkWell for touch feedback
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainingDetailsPage(
                                trainingId: training[
                                    'IdTr'], // Use training['IdTr'] here
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Space between text and icon
                            children: [
                              // Training name text
                              Text(
                                training['Name'] ?? 'Unnamed Training',
                                style: const TextStyle(
                                  color:
                                      secondaryColor, // Ensure this color is defined in your main.dart
                                  fontSize:
                                      20, // Increase font size for better visibility
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Eye icon
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye,
                                    color: secondaryColor),
                                onPressed: () {
                                  // Navigate to TrainingDetailsPage when the icon is pressed
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrainingDetailsPage(
                                        trainingId: training['IdTr'],
                                      ),
                                    ),
                                  );
                                },
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
            child: const Icon(
              Icons.add,
            ),
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
            child: const Icon(Icons.edit),
            label: 'Edit',
            foregroundColor: secondaryColor,
            backgroundColor: primaryColor,
            onTap: () {},
          ),
          SpeedDialChild(
            child: const Icon(Icons.visibility),
            label: 'See All Trainings',
            foregroundColor: secondaryColor,
            backgroundColor: primaryColor,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
