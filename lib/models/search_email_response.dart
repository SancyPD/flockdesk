import 'dart:convert';

SearchEmailResponse searchEmailResponseFromJson(String str) => SearchEmailResponse.fromJson(json.decode(str));

String searchEmailResponseToJson(SearchEmailResponse data) => json.encode(data.toJson());

class SearchEmailResponse {
  List<SearchResult> result;

  SearchEmailResponse({
    required this.result,
  });

  factory SearchEmailResponse.fromJson(Map<String, dynamic> json) => SearchEmailResponse(
    result: List<SearchResult>.from(json["result"].map((x) => SearchResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class SearchResult {
  int contactId;
  int orgId;
  String contactName;
  String emailId;
  DateTime createdAt;
  DateTime updatedAt;

  SearchResult({
    required this.contactId,
    required this.orgId,
    required this.contactName,
    required this.emailId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    contactId: json["contact_id"],
    orgId: json["org_id"],
    contactName: json["contact_name"],
    emailId: json["email_id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "contact_id": contactId,
    "org_id": orgId,
    "contact_name": contactName,
    "email_id": emailId,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}