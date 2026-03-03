// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
      id: json['id'] as String,
      crop: json['crop'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
      'id': instance.id,
      'crop': instance.crop,
      'date': instance.date.toIso8601String(),
      'time': instance.time,
      'title': instance.title,
      if (instance.subtitle case final value?) 'subtitle': value,
      'isCompleted': instance.isCompleted,
      if (instance.completedAt?.toIso8601String() case final value?)
        'completedAt': value,
      'createdAt': instance.createdAt.toIso8601String(),
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updatedAt': value,
    };
