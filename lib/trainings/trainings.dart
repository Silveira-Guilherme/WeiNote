// Model classes
class Exercise {
  String name;
  bool completed;
  bool isExpanded;
  List<Map<String, dynamic>> weights; // List of weights and reps

  Exercise(
      {required this.name,
      required this.completed,
      required this.isExpanded,
      List<Map<String, dynamic>>? weights})
      : weights = weights ?? [];
}

class Training {
  String name;
  List<Exercise> exercises;

  Training({required this.name, List<Exercise>? exercises})
      : exercises = exercises ?? [];
}
