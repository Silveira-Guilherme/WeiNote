import 'package:flutter/material.dart';
import 'package:gymdo/main.dart'; // Ensure this is correctly importing your colors
import 'package:gymdo/trainings/trainingdetails.dart';
import '/../sql.dart'; // Import your database helper

class TrainingListPage extends StatefulWidget {
  @override
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
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the back button color to white
          ),
          title: const Text(
            'All Trainings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24.0, // Adjust the font size
              color: Colors.white,
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
                              ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8), // Spacing between items
                              Text(
                                training['Name'] ?? 'Unnamed Training',
                                style: TextStyle(
                                  color:
                                      secondaryColor, // Ensure this color is defined in your main.dart
                                  fontSize:
                                      20, // Increase font size for better visibility
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
