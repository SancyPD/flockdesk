
import 'dart:convert';

ProfileResponse profileResponseFromJson(String str) => ProfileResponse.fromJson(json.decode(str));

String profileResponseToJson(ProfileResponse data) => json.encode(data.toJson());

class ProfileResponse {
  Result result;

  ProfileResponse({
    required this.result,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
    result: Result.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "result": result.toJson(),
  };
}

class Result {
  int id;
  int orgId;
  String roleType;
  int roleId;
  String name;
  String email;
  dynamic profileImage;
  dynamic emailVerifiedAt;
  dynamic otp;
  dynamic expiresAt;
  String emailSignature;
  int userStatus;
  String createdAt;
  String updatedAt;

  Result({
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

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"]??0,
    orgId: json["org_id"]??0,
    roleType: json["role_type"]??"",
    roleId: json["role_id"]??0,
    name: json["name"]??"",
    email: json["email"]??"",
    profileImage: json["profile_image"]??"",
    emailVerifiedAt: json["email_verified_at"]??"",
    otp: json["otp"]??"",
    expiresAt: json["expires_at"]??"",
    emailSignature: json["email_signature"]??"",
    userStatus: json["user_status"]??"",
    createdAt: json["created_at"]??"",
    updatedAt: json["updated_at"]??"",
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
