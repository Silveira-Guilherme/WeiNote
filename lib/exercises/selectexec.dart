// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gymdo/exercises/createexec.dart';
import 'package:gymdo/main.dart';
import '/../sql.dart';

class ExerciseListPage extends StatefulWidget {
  final int trainingId;
  final VoidCallback onSave; // Callback to trigger on save

  const ExerciseListPage({super.key, required this.trainingId, required this.onSave});

  @override
  ExerciseListPageState createState() => ExerciseListPageState();
}

class ExerciseListPageState extends State<ExerciseListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> items = [];
  List<bool> expandedList = [];
  List<bool> completed = [];
  bool isLoading = false;
  Set<int> alreadyAddedExercises = {}; // Separate set for exercises
  Set<int> alreadyAddedMacros = {}; // Separate set for macros

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

    // Fetch exercises and macros as you have it
    List<Map<String, dynamic>> exercises = await dbHelper.customQuery("""
    SELECT IdExer AS id, Name, 'exercise' AS type FROM Exer
  """);

    List<Map<String, dynamic>> macros = await dbHelper.customQuery("""
    SELECT Macro.IdMacro AS id, Macro.Qtt AS quantity, 'macro' AS type, GROUP_CONCAT(Exer.Name, ', ') AS exerciseNames
    FROM Macro
    JOIN Exer_Macro ON Macro.IdMacro = Exer_Macro.CodMacro
    JOIN Exer ON Exer_Macro.CodExer = Exer.IdExer
    GROUP BY Macro.IdMacro
  """);

    // Fetch already linked exercises and macros
    List<Map<String, dynamic>> alreadyAddedExerciseList = await dbHelper.customQuery("""
    SELECT CodExer AS id FROM Tr_Exer WHERE CodTr = ${widget.trainingId}
  """);

    List<Map<String, dynamic>> alreadyAddedMacroList = await dbHelper.customQuery("""
    SELECT CodMacro AS id FROM Tr_Macro WHERE CodTr = ${widget.trainingId}
  """);

    // Store already added items in sets
    alreadyAddedExercises = {...alreadyAddedExerciseList.map((e) => e['id'])};
    alreadyAddedMacros = {...alreadyAddedMacroList.map((e) => e['id'])};

    // Combine exercises and macros
    List<Map<String, dynamic>> queryResult = [...exercises, ...macros];

    // Set initial completed state based on whether the item is already added
    setState(() {
      items = queryResult;
      expandedList = List.generate(items.length, (index) => false);
      completed = List.generate(items.length, (index) => isItemAlreadyAdded(items[index])); // Set initial selected state
      isLoading = false;
    });
  }

  // Check if an item is already added based on its type
  bool isItemAlreadyAdded(Map<String, dynamic> item) {
    final itemId = item['id'];
    final itemType = item['type'];

    if (itemType == 'exercise') {
      return alreadyAddedExercises.contains(itemId);
    } else if (itemType == 'macro') {
      return alreadyAddedMacros.contains(itemId);
    }
    return false;
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

  void submitExercises() async {
    // Fetch all existing items (both exercises and macros) linked to this training
    List<Map<String, dynamic>> existingExercises = await dbHelper.customQuery("""
    SELECT CodExer AS id, ExerOrder AS orderNum, 'exercise' AS type FROM Tr_Exer WHERE CodTr = ${widget.trainingId}
  """);

    List<Map<String, dynamic>> existingMacros = await dbHelper.customQuery("""
    SELECT CodMacro AS id, ExerOrder AS orderNum, 'macro' AS type FROM Tr_Macro WHERE CodTr = ${widget.trainingId}
  """);

    // Combine existing exercises and macros into one list for comparison
    List<Map<String, dynamic>> existingItems = [...existingExercises, ...existingMacros];

    // Separate items into lists for new additions and items to be deleted
    List<Map<String, dynamic>> itemsToAdd = [];
    List<Map<String, dynamic>> itemsToDelete = [];

    for (int i = 0; i < items.length; i++) {
      bool isSelected = completed[i];
      Map<String, dynamic> item = items[i];

      // Check if this item is already in the training
      bool isAlreadyInTraining = existingItems.any((existingItem) => existingItem['id'] == item['id'] && existingItem['type'] == item['type']);

      if (isSelected && !isAlreadyInTraining) {
        // If selected but not yet added, add to itemsToAdd
        itemsToAdd.add(item);
      } else if (!isSelected && isAlreadyInTraining) {
        // If not selected but currently added, add to itemsToDelete
        itemsToDelete.add(item);
      }
    }

    // Delete deselected items from the database
    for (var item in itemsToDelete) {
      final itemId = item['id'];
      final itemType = item['type'];

      if (itemType == 'exercise') {
        await dbHelper.customQuery("DELETE FROM Tr_Exer WHERE CodExer = $itemId AND CodTr = ${widget.trainingId}");
      } else if (itemType == 'macro') {
        await dbHelper.customQuery("DELETE FROM Tr_Macro WHERE CodMacro = $itemId AND CodTr = ${widget.trainingId}");
      }
    }

    // Refresh the list of current items in the training after deletions
    List<Map<String, dynamic>> currentItems = await dbHelper.customQuery("""
    SELECT CodExer AS id, ExerOrder AS orderNum, 'exercise' AS type FROM Tr_Exer WHERE CodTr = ${widget.trainingId}
    UNION
    SELECT CodMacro AS id, ExerOrder AS orderNum, 'macro' AS type FROM Tr_Macro WHERE CodTr = ${widget.trainingId}
    ORDER BY orderNum
  """);

    // Create a mutable list of all items in order, combining `currentItems` and `itemsToAdd`
    List<Map<String, dynamic>> allItems = List<Map<String, dynamic>>.from(currentItems)..addAll(itemsToAdd);

    // Recalculate order for all items and update the database
    for (int order = 1; order <= allItems.length; order++) {
      var item = allItems[order - 1];
      final itemId = item['id'];
      final itemType = item['type'];

      if (itemType == 'exercise') {
        // Update or insert with new order
        await dbHelper.customQuery("""
        INSERT OR REPLACE INTO Tr_Exer (CodExer, CodTr, ExerOrder)
        VALUES ($itemId, ${widget.trainingId}, $order)
      """);
      } else if (itemType == 'macro') {
        await dbHelper.customQuery("""
        INSERT OR REPLACE INTO Tr_Macro (CodMacro, CodTr, ExerOrder)
        VALUES ($itemId, ${widget.trainingId}, $order)
      """);
      }
    }

    Navigator.pop(context); // Return to the previous screen after saving changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: secondaryColor // Change the back button color to white
              ),
          title: const Text(
            'Select Exercises & Macros',
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
              onPressed: submitExercises,
              color: Colors.white,
            ),
          ],
        ),
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
                      bool isAlreadyAdded = isItemAlreadyAdded(item); // Check if the item is already added

                      return GestureDetector(
                        onTap: () {
                          if (!isAlreadyAdded) {
                            changeValue(!completed[index], index);
                          }
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: isAlreadyAdded
                              ? completed[index]
                                  ? accentColor1
                                  : secondaryColor
                              : completed[index]
                                  ? accentColor2
                                  : secondaryColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    isMacro ? 'Macro: ${item['quantity']}x - ${item['exerciseNames']}' : item['Name'] ?? 'Exercise',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: completed[index] ? secondaryColor : primaryColor,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: completed[index],
                                    onChanged: (value) {
                                      changeValue(value!, index);
                                    },
                                    activeColor: primaryColor,
                                    checkColor: secondaryColor, // Color of the check inside the box
                                  ),
                                  onTap: isAlreadyAdded
                                      ? null
                                      : () {
                                          changeExpanded(!expandedList[index], index);
                                        },
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
        backgroundColor: accentColor2,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateExercisePage(
                onSave: fetchItems,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
