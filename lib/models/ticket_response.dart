import 'dart:convert';

TicketResponse ticketResponseFromJson(String str) => TicketResponse.fromJson(json.decode(str));

String ticketResponseToJson(TicketResponse data) => json.encode(data.toJson());

class TicketResponse {
  List<TicketResult> result;

  TicketResponse({
    required this.result,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) => TicketResponse(
    result: List<TicketResult>.from(json["result"].map((x) => TicketResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class TicketResult {
  int ticketId;
  int orgId;
  int contactId;
  String createdBy;
  int creatorId;
  int statusId;
  String ticketTitle;
  String description;
  int assignedTeam;
  int assignedUser;
  DateTime createdAt;
  DateTime updatedAt;
  String img;
  String resultClass;
  String contactName;
  String contactNameF;
  String contactEmail;
  String assignee;
  DateTime lastUpdatedDatetime;
  String agoTime;
  String lastReplyBody;
  int totalReplyCount;
  String lastSentByName;

  TicketResult({
    required this.ticketId,
    required this.orgId,
    required this.contactId,
    required this.createdBy,
    required this.creatorId,
    required this.statusId,
    required this.ticketTitle,
    required this.description,
    required this.assignedTeam,
    required this.assignedUser,
    required this.createdAt,
    required this.updatedAt,
    required this.img,
    required this.resultClass,
    required this.contactName,
    required this.contactNameF,
    required this.contactEmail,
    required this.assignee,
    required this.lastUpdatedDatetime,
    required this.agoTime,
    required this.lastReplyBody,
    required this.totalReplyCount,
    required this.lastSentByName,
  });

  factory TicketResult.fromJson(Map<String, dynamic> json) => TicketResult(
    ticketId: json["ticket_id"],
    orgId: json["org_id"],
    contactId: json["contact_id"],
    createdBy: json["created_by"],
    creatorId: json["creator_id"],
    statusId: json["status_id"],
    ticketTitle: json["ticket_title"],
    description: json["description"],
    assignedTeam: json["assigned_team"],
    assignedUser: json["assigned_user"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    img: json["img"],
    resultClass: json["class"],
    contactName: json["contact_name"],
    contactNameF: json["contact_name_f"],
    contactEmail: json["contact_email"],
    assignee: json["assignee"],
    lastUpdatedDatetime: DateTime.parse(json["last_updated_datetime"]),
    agoTime: json["ago_time"],
    lastReplyBody: json["last_reply_body"],
    totalReplyCount: json["total_reply_count"],
    lastSentByName: json["last_sent_by_name"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "ticket_id": ticketId,
    "org_id": orgId,
    "contact_id": contactId,
    "created_by": createdBy,
    "creator_id": creatorId,
    "status_id": statusId,
    "ticket_title": ticketTitle,
    "description": description,
    "assigned_team": assignedTeam,
    "assigned_user": assignedUser,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "img": img,
    "class": resultClass,
    "contact_name": contactName,
    "contact_name_f": contactNameF,
    "contact_email": contactEmail,
    "assignee": assignee,
    "last_updated_datetime": lastUpdatedDatetime.toIso8601String(),
    "ago_time": agoTime,
    "last_reply_body": lastReplyBody,
    "total_reply_count": totalReplyCount,
    "last_sent_by_name": lastSentByName,
  };
}