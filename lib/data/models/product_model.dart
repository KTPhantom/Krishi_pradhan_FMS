import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final double rating;
  final String? imageUrl;
  final String? description;
  final int? stock;
  final String? brand;
  final DateTime? createdAt;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.rating,
    this.imageUrl,
    this.description,
    this.stock,
    this.brand,
    this.createdAt,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) => 
      _$ProductModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
  
  ProductModel copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    String? unit,
    double? rating,
    String? imageUrl,
    String? description,
    int? stock,
    String? brand,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

