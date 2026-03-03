import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final Map<String, dynamic>? farmDetails;
  final bool isKycVerified;
  final String role; // 'admin' or 'worker'
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  UserModel({
    required this.id,
    required this.name,
    this.email = '',
    this.phone,
    this.profileImageUrl,
    this.farmDetails,
    this.isKycVerified = false,
    this.role = 'worker',
    required this.createdAt,
    this.updatedAt,
  });
  
  bool get isAdmin => role == 'admin';
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    Map<String, dynamic>? farmDetails,
    bool? isKycVerified,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      farmDetails: farmDetails ?? this.farmDetails,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
