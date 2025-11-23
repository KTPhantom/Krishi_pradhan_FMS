import 'package:json_annotation/json_annotation.dart';

part 'field_model.g.dart';

@JsonSerializable()
class FieldModel {
  final String id;
  final String crop;
  final double area; // in acres
  final String waterSource;
  final String? location;
  final Map<String, double>? coordinates; // lat, lng
  final DateTime? plantingDate;
  final DateTime? harvestDate;
  final String? status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  FieldModel({
    required this.id,
    required this.crop,
    required this.area,
    required this.waterSource,
    this.location,
    this.coordinates,
    this.plantingDate,
    this.harvestDate,
    this.status,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory FieldModel.fromJson(Map<String, dynamic> json) => 
      _$FieldModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$FieldModelToJson(this);
  
  FieldModel copyWith({
    String? id,
    String? crop,
    double? area,
    String? waterSource,
    String? location,
    Map<String, double>? coordinates,
    DateTime? plantingDate,
    DateTime? harvestDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldModel(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      area: area ?? this.area,
      waterSource: waterSource ?? this.waterSource,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

