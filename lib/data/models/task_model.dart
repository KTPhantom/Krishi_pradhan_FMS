import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final String id;
  final String crop;
  final DateTime date;
  final String time; // HH:mm format
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  TaskModel({
    required this.id,
    required this.crop,
    required this.date,
    required this.time,
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory TaskModel.fromJson(Map<String, dynamic> json) => 
      _$TaskModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);
  
  TaskModel copyWith({
    String? id,
    String? crop,
    DateTime? date,
    String? time,
    String? title,
    String? subtitle,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      date: date ?? this.date,
      time: time ?? this.time,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

