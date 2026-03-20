class LoginResponse {
  User user;
  String token;

  LoginResponse({required this.user, required this.token});
}

class User {
  int id;
  int orgId;
  String roleType;
  int roleId;
  String name;
  String email;
  dynamic profileImage;
  dynamic emailVerifiedAt;
  String otp;
  DateTime expiresAt;
  dynamic emailSignature;
  int userStatus;
  dynamic createdAt;
  DateTime updatedAt;

  User({
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
}
