// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldModel _$FieldModelFromJson(Map<String, dynamic> json) => FieldModel(
      id: json['id'] as String,
      crop: json['crop'] as String,
      area: (json['area'] as num).toDouble(),
      waterSource: json['waterSource'] as String,
      location: json['location'] as String?,
      coordinates: (json['coordinates'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      plantingDate: json['plantingDate'] == null
          ? null
          : DateTime.parse(json['plantingDate'] as String),
      harvestDate: json['harvestDate'] == null
          ? null
          : DateTime.parse(json['harvestDate'] as String),
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FieldModelToJson(FieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'crop': instance.crop,
      'area': instance.area,
      'waterSource': instance.waterSource,
      if (instance.location case final value?) 'location': value,
      if (instance.coordinates case final value?) 'coordinates': value,
      if (instance.plantingDate?.toIso8601String() case final value?)
        'plantingDate': value,
      if (instance.harvestDate?.toIso8601String() case final value?)
        'harvestDate': value,
      if (instance.status case final value?) 'status': value,
      'createdAt': instance.createdAt.toIso8601String(),
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updatedAt': value,
    };
