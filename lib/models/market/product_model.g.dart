// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      brand: json['brand'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'price': instance.price,
      'unit': instance.unit,
      'rating': instance.rating,
      if (instance.imageUrl case final value?) 'imageUrl': value,
      if (instance.description case final value?) 'description': value,
      if (instance.stock case final value?) 'stock': value,
      if (instance.brand case final value?) 'brand': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'createdAt': value,
    };
