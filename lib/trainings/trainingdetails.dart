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
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  Future<void> fetchTrainingDetails() async {
    try {
      // Fetch training details
      List<Map<String, dynamic>> trainingResult = await dbHelper.customQuery("SELECT Name, Type FROM Tr WHERE IdTr = ${widget.trainingId}");

      // Fetching training days
      List<Map<String, dynamic>> daysResult = await dbHelper.customQuery("""
        SELECT d.Name AS Day FROM Day d 
        INNER JOIN Tr_Day td ON d.IdDay = td.CodDay 
        WHERE td.CodTr = ${widget.trainingId}
      """);

      // Fetching exercises
      List<Map<String, dynamic>> exercisesResult = await dbHelper.customQuery("""
        SELECT e.Name AS itemName, 'exercise' AS itemType
        FROM Exer e
        INNER JOIN Tr_Exer te ON e.IdExer = te.CodExer
        WHERE te.CodTr = ${widget.trainingId}
      """);

      // Fetching macros with quantity and associated exercise names
      List<Map<String, dynamic>> macrosResult = await dbHelper.customQuery("""
        SELECT m.Qtt AS quantity, GROUP_CONCAT(e.Name, ', ') AS exerciseNames, 'macro' AS itemType
        FROM Macro m
        JOIN Exer_Macro em ON m.IdMacro = em.CodMacro
        JOIN Exer e ON em.CodExer = e.IdExer
        INNER JOIN Tr_Macro tm ON tm.CodMacro = m.IdMacro
        WHERE tm.CodTr = ${widget.trainingId}
        GROUP BY m.IdMacro
      """);

      // Combine exercises and macros into a single list
      List<Map<String, dynamic>> combinedItems = [...exercisesResult, ...macrosResult];

      setState(() {
        trainingName = trainingResult.isNotEmpty ? trainingResult[0]['Name'] : 'Unnamed Training';
        trainingType = trainingResult.isNotEmpty ? trainingResult[0]['Type'] ?? 'No type specified' : 'No type specified';
        trainingDays = daysResult.map((day) => day['Day'].toString()).toList();
        items = combinedItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        trainingName = 'Error fetching data';
        trainingType = 'Error';
        trainingDays = [];
        items = [];
      });
      print('Error fetching training details: $e');
    }
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
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: secondaryColor),
          title: const Text(
            'Training Details',
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
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
                    const Text(
                      'Exercises & Macros:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    items.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              var item = items[index];
                              bool isMacro = item['itemType'] == 'macro';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black87,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    isMacro ? '${item['quantity']}x - ${item['exerciseNames']}' : item['itemName'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Text(
                            'No exercises or macros associated with this training.',
                            style: TextStyle(color: Colors.black54),
                          ),
                  ],
                ),
              ),
            ),
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
