import 'dart:convert';

AgentsListResponse agentsListResponseFromJson(String str) => AgentsListResponse.fromJson(json.decode(str));

String agentsListResponseToJson(AgentsListResponse data) => json.encode(data.toJson());

class AgentsListResponse {
  List<Agents> result;

  AgentsListResponse({
    required this.result,
  });

  factory AgentsListResponse.fromJson(Map<String, dynamic> json) => AgentsListResponse(
    result: List<Agents>.from(json["result"].map((x) => Agents.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class Agents {
  int id;
  int orgId;
  String roleType;
  int roleId;
  String name;
  String email;
  String profileImage;
  dynamic emailVerifiedAt;
  dynamic otp;
  dynamic expiresAt;
  String emailSignature;
  int userStatus;
  String createdAt;
  String updatedAt;

  Agents({
    required this.id,
    required this.orgId,
    required this.roleType,
    required this.roleId,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.emailVerifiedAt,
    required this.otp,
    required this.expiresAt,
    required this.emailSignature,
    required this.userStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agents.fromJson(Map<String, dynamic> json) => Agents(
    id: json["id"],
    orgId: json["org_id"],
    roleType: json["role_type"],
    roleId: json["role_id"],
    name: json["name"],
    email: json["email"],
    profileImage: json["profile_image"]??"",
    emailVerifiedAt: json["email_verified_at"]??"",
    otp: json["otp"]??"",
    expiresAt: json["expires_at"]??"",
    emailSignature: json["email_signature"]??"",
    userStatus: json["user_status"]??"",
    createdAt: json["created_at"]??"",
    updatedAt:json["updated_at"]??"",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "org_id": orgId,
    "role_type": roleType,
    "role_id": roleId,
    "name": name,
    "email": email,
    "profile_image": profileImage,
    "email_verified_at": emailVerifiedAt,
    "otp": otp,
    "expires_at": expiresAt,
    "email_signature": emailSignature,
    "user_status": userStatus,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}