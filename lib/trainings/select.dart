import 'package:flutter/material.dart';
import 'package:gymdo/trainings/trainingdetails.dart';
import '/../sql.dart';

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
    fetchTrainings(); // Load trainings when page is initialized
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
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(training['Name'] ?? 'Unnamed Training'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrainingDetailsPage(
                                  trainingId: training['IdTr']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
