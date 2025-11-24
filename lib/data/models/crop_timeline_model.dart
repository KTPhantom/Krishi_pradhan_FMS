class CropTimelineModel {
  final String cropName;
  final int totalDays;
  final List<CropStageTask> stages;

  CropTimelineModel({
    required this.cropName,
    required this.totalDays,
    required this.stages,
  });
}

class CropStageTask {
  final int dayOffset; // Days after planting
  final String stageName; // e.g., "Vegetative", "Flowering"
  final String taskTitle; // e.g., "Apply Nitrogen"
  final String taskDescription;
  final String type; // "Irrigation", "Fertilizer", "Pesticide", "General"

  CropStageTask({
    required this.dayOffset,
    required this.stageName,
    required this.taskTitle,
    required this.taskDescription,
    required this.type,
  });
}
