class Exercise {
  final int id; // Unique identifier for the exercise
  String name;
  bool completed;
  bool isExpanded;
  List<Map<String, dynamic>> weights; // List of weights and reps

  Exercise({
    required this.id,
    required this.name,
    required this.completed,
    required this.isExpanded,
    List<Map<String, dynamic>>? weights,
  }) : weights = weights ?? [];
}

class Training {
  final int id; // Unique identifier for the training
  String name;
  List<Exercise> exercises;
  List<String> days; // Now it's non-nullable, initialized to an empty list

  Training({
    required this.id,
    required this.name,
    List<Exercise>? exercises,
    List<String>? days,
  })  : exercises = exercises ?? [],
        days = days ?? []; // Ensure non-null initialization
}
