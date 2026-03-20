import 'dart:convert';

TagsResponse tagsResponseFromJson(String str) => TagsResponse.fromJson(json.decode(str));

String tagsResponseToJson(TagsResponse data) => json.encode(data.toJson());

class TagsResponse {
  List<TagDetails> result;

  TagsResponse({
    required this.result,
  });

  factory TagsResponse.fromJson(Map<String, dynamic> json) => TagsResponse(
    result: List<TagDetails>.from(json["result"].map((x) => TagDetails.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class TagDetails {
  int ticketTagId;
  int ticketId;
  int tagId;
  int orgId;
  String tagName;
  String tagStatus;

  TagDetails({
    required this.ticketTagId,
    required this.ticketId,
    required this.tagId,
    required this.orgId,
    required this.tagName,
    required this.tagStatus,

  });

  factory TagDetails.fromJson(Map<String, dynamic> json) => TagDetails(
    ticketTagId: json["ticket_tag_id"]??0,
    ticketId: json["ticket_id"]??0,
    tagId: json["tag_id"],
    orgId: json["org_id"],
    tagName: json["tag_name"],
    tagStatus: json["tag_status"],
  );

  Map<String, dynamic> toJson() => {
    "ticket_tag_id": ticketTagId,
    "ticket_id": ticketId,
    "tag_id": tagId,
    "org_id": orgId,
    "tag_name": tagName,
    "tag_status": tagStatus,
  };
}
