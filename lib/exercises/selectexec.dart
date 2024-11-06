import 'package:flutter/material.dart';
import 'package:gymdo/exercises/createexec.dart';
import '/../sql.dart';

class ExerciseListPage extends StatefulWidget {
  final int trainingId;

  const ExerciseListPage({Key? key, required this.trainingId}) : super(key: key);

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> items = [];
  List<bool> expandedList = [];
  List<bool> completed = [];
  bool isLoading = false;
  Set<int> alreadyAddedItems = {}; // To store already added exercise or macro ids

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  // Fetch exercises, macros, and already added items from the database
  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    // Fetch exercises
    List<Map<String, dynamic>> exercises = await dbHelper.customQuery("""
      SELECT IdExer AS id, Name, 'exercise' AS type FROM Exer
    """);

    // Fetch macros with quantity and associated exercise names
    List<Map<String, dynamic>> macros = await dbHelper.customQuery("""
      SELECT Macro.IdMacro AS id, Macro.Qtt AS quantity, 'macro' AS type, GROUP_CONCAT(Exer.Name, ', ') AS exerciseNames
      FROM Macro
      JOIN Exer_Macro ON Macro.IdMacro = Exer_Macro.CodMacro
      JOIN Exer ON Exer_Macro.CodExer = Exer.IdExer
      GROUP BY Macro.IdMacro
    """);

    // Fetch exercises and macros already linked to this training
    List<Map<String, dynamic>> alreadyAddedExercises = await dbHelper.customQuery("""
      SELECT CodExer AS id FROM Tr_Exer WHERE CodTr = ${widget.trainingId}
    """);

    List<Map<String, dynamic>> alreadyAddedMacros = await dbHelper.customQuery("""
      SELECT CodMacro AS id FROM Tr_Macro WHERE CodTr = ${widget.trainingId}
    """);

    // Combine exercises and macros into one list
    List<Map<String, dynamic>> queryResult = [...exercises, ...macros];

    // Add already added items (both exercises and macros) to a set for quick lookup
    alreadyAddedItems = {
      ...alreadyAddedExercises.map((e) => e['id']),
      ...alreadyAddedMacros.map((e) => e['id']),
    };

    setState(() {
      items = queryResult;
      expandedList = List.generate(items.length, (index) => false);
      completed = List.generate(items.length, (index) => false); // Initially, no item is completed
      isLoading = false;
    });
  }

  // Toggle expanded state for item details
  void changeExpanded(bool isExpanded, int index) {
    setState(() {
      expandedList[index] = isExpanded;
    });
  }

  // Toggle completed state
  void changeValue(bool isCompleted, int index) {
    setState(() {
      completed[index] = isCompleted;
    });
  }

  // Save selected exercises and macros to the training
  void submitExercises() async {
    // Get the current maximum order (order starts from 1)
    var lastOrderQuery = await dbHelper.customQuery("""
    SELECT MAX(ExerOrder) as lastOrder FROM (
      SELECT ExerOrder FROM Tr_Exer WHERE CodTr = ${widget.trainingId}
      UNION
      SELECT ExerOrder FROM Tr_Macro WHERE CodTr = ${widget.trainingId}
    )
  """);
    int lastOrder = lastOrderQuery[0]['lastOrder'] ?? 0;

    // Save each selected exercise and macro
    for (int i = 0; i < items.length; i++) {
      if (completed[i]) {
        final item = items[i];
        final itemId = item['id'];
        final itemType = item['type'];

        // Increment the order for each item
        lastOrder += 1;

        if (itemType == 'exercise') {
          // Save the exercise with its order
          await dbHelper.customQuery(
            "INSERT INTO Tr_Exer (CodExer, CodTr, ExerOrder) VALUES ($itemId, ${widget.trainingId}, $lastOrder)",
          );
        } else if (itemType == 'macro') {
          // Save the macro with its order
          await dbHelper.customQuery(
            "INSERT INTO Tr_Macro (CodMacro, CodTr, ExerOrder) VALUES ($itemId, ${widget.trainingId}, $lastOrder)",
          );
        }
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Select Exercises & Macros',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: submitExercises,
            color: Colors.white,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      bool isMacro = item['type'] == 'macro';
                      bool isAlreadyAdded = alreadyAddedItems.contains(item['id']); // Check if the item is already added

                      return GestureDetector(
                        onTap: isAlreadyAdded
                            ? null // Disable tap if item is already added
                            : () {
                                changeValue(!completed[index], index);
                              },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: isAlreadyAdded
                              ? Colors.grey.shade300 // Color for already added items
                              : completed[index]
                                  ? const Color.fromARGB(255, 220, 237, 200)
                                  : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.black,
                                    child: Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    isMacro ? 'Macro: ${item['quantity']}x - ${item['exerciseNames']}' : item['Name'] ?? 'Exercise',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: isMacro ? Colors.blueAccent : Colors.black,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isAlreadyAdded ? true : completed[index], // Automatically checked if already added
                                    onChanged: isAlreadyAdded
                                        ? null // Disable the checkbox if already added
                                        : (value) {
                                            changeValue(value!, index);
                                          },
                                  ),
                                  onTap: isAlreadyAdded
                                      ? null // Disable expansion if already added
                                      : () {
                                          changeExpanded(!expandedList[index], index);
                                        },
                                ),
                                if (expandedList[index] && !isMacro)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: const Text(
                                      'Additional details about the exercise',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateExercisePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
