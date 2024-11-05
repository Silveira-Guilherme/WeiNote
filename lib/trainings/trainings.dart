class Exercise {
  final int id; // Unique identifier for the exercise
  String name;
  bool completed;
  bool isExpanded;
  int order; // Order of the exercise within the training/macro
  List<Map<String, dynamic>> weights; // List of weights and reps

  Exercise({
    required this.id,
    required this.name,
    this.completed = false,
    this.isExpanded = false,
    this.order = 0, // Default to 0, but should be assigned based on the DB order
    List<Map<String, dynamic>>? weights,
  }) : weights = weights ?? []; // Ensure weights are initialized to a list
}

class Training {
  final int id; // Unique identifier for the training
  String name;
  String? type;
  List<Exercise> exercises;
  List<String> days; // List of days associated with the training
  List<Macro> macros; // List of macros associated with the training

  Training({
    required this.id,
    required this.name,
    this.type,
    List<Exercise>? exercises,
    List<String>? days,
    List<Macro>? macros,
  })  : exercises = exercises ?? [],
        days = days ?? [], // Initialize to an empty list if null
        macros = macros ?? []; // Initialize macros to an empty list if null

  String getTraining() {
    return name;
  }
}

// New Macro class to handle macro-level ordering and information
class Macro {
  int id;
  final int order; // Order of the macro within the training
  String name;
  List<Exercise> exercises; // Exercises under this macro
  bool completed;
  bool isExpanded;
  Macro({
    required this.id,
    required this.order,
    required this.name,
    this.completed = false,
    this.isExpanded = false,
    List<Exercise>? exercises,
  }) : exercises = exercises ?? []; // Initialize exercises to an empty list if null
}
