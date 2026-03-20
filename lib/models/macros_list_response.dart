import 'dart:convert';

MacrosListResponse macrosListResponseFromJson(String str) => MacrosListResponse.fromJson(json.decode(str));

String macrosListResponseToJson(MacrosListResponse data) => json.encode(data.toJson());

class MacrosListResponse {
  List<Result> result;

  MacrosListResponse({
    required this.result,
  });

  factory MacrosListResponse.fromJson(Map<String, dynamic> json) => MacrosListResponse(
    result: List<Result>.from(json["result"].map((x) => Result.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class Result {
  int macroId;
  String macroTitle;
  String macroBody;
  int orgId;
  int status;

  Result({
    required this.macroId,
    required this.macroTitle,
    required this.macroBody,
    required this.orgId,
    required this.status,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    macroId: json["macro_id"],
    macroTitle: json["macro_title"],
    macroBody: json["macro_body"],
    orgId: json["org_id"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "macro_id": macroId,
    "macro_title": macroTitle,
    "macro_body": macroBody,
    "org_id": orgId,
    "status": status,
  };
}