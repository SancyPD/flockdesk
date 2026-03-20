import 'dart:convert';

TrashTicketsResponse trashTicketsResponseFromJson(String str) => TrashTicketsResponse.fromJson(json.decode(str));

String trashTicketsResponseToJson(TrashTicketsResponse data) => json.encode(data.toJson());

class TrashTicketsResponse {
  List<TrashTicket> result;
  int total;
  int totalPages;
  List<int> pages;
  int currentPage;

  TrashTicketsResponse({
    required this.result,
    required this.total,
    required this.totalPages,
    required this.pages,
    required this.currentPage,
  });

  factory TrashTicketsResponse.fromJson(Map<String, dynamic> json) => TrashTicketsResponse(
    result: List<TrashTicket>.from(json["result"].map((x) => TrashTicket.fromJson(x))),
    total: json["total"],
    totalPages: json["total_pages"],
    pages: List<int>.from(json["pages"].map((x) => x)),
    currentPage: json["currentPage"],
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
    "total": total,
    "total_pages": totalPages,
    "pages": List<dynamic>.from(pages.map((x) => x)),
    "currentPage": currentPage,
  };
}

class TrashTicket {
  int ticketId;
  int orgId;
  int contactId;
  String createdBy;
  int creatorId;
  int statusId;
  int clientStatus;
  String ticketTitle;
  String description;
  int assignedTeam;
  int assignedUser;
  DateTime createdAt;
  DateTime updatedAt;
  int updatedBy;
  int isDeleted;
  DateTime latestReplyAt;
  String img;
  String resultClass;
  String contactName;
  String contactNameF;
  String contactEmail;
  String assignee;
  String sentBy;
  DateTime lastUpdatedDatetime;
  String agoTime;
  String lastReplyBody;
  String lastSentStatus;
  String lastSentByName;
  int totalReplyCount;

  TrashTicket({
    required this.ticketId,
    required this.orgId,
    required this.contactId,
    required this.createdBy,
    required this.creatorId,
    required this.statusId,
    required this.clientStatus,
    required this.ticketTitle,
    required this.description,
    required this.assignedTeam,
    required this.assignedUser,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    required this.isDeleted,
    required this.latestReplyAt,
    required this.img,
    required this.resultClass,
    required this.contactName,
    required this.contactNameF,
    required this.contactEmail,
    required this.assignee,
    required this.sentBy,
    required this.lastUpdatedDatetime,
    required this.agoTime,
    required this.lastReplyBody,
    required this.lastSentStatus,
    required this.lastSentByName,
    required this.totalReplyCount,
  });

  factory TrashTicket.fromJson(Map<String, dynamic> json) => TrashTicket(
    ticketId: json["ticket_id"],
    orgId: json["org_id"],
    contactId: json["contact_id"],
    createdBy: json["created_by"],
    creatorId: json["creator_id"],
    statusId: json["status_id"],
    clientStatus: json["client_status"]??0,
    ticketTitle: json["ticket_title"],
    description: json["description"],
    assignedTeam: json["assigned_team"],
    assignedUser: json["assigned_user"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    updatedBy: json["updated_by"],
    isDeleted: json["is_deleted"],
    latestReplyAt: DateTime.parse(json["latest_reply_at"]),
    img: json["img"],
    resultClass: json["class"],
    contactName: json["contact_name"],
    contactNameF: json["contact_name_f"],
    contactEmail: json["contact_email"],
    assignee: json["assignee"],
    sentBy: json["sent_by"],
    lastUpdatedDatetime: DateTime.parse(json["last_updated_datetime"]),
    agoTime: json["ago_time"],
    lastReplyBody: json["last_reply_body"],
    lastSentStatus: json["last_sent_status"],
    lastSentByName: json["last_sent_by_name"],
    totalReplyCount: json["total_reply_count"],
  );

  Map<String, dynamic> toJson() => {
    "ticket_id": ticketId,
    "org_id": orgId,
    "contact_id": contactId,
    "created_by": createdBy,
    "creator_id": creatorId,
    "status_id": statusId,
    "client_status": clientStatus,
    "ticket_title": ticketTitle,
    "description": description,
    "assigned_team": assignedTeam,
    "assigned_user": assignedUser,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "updated_by": updatedBy,
    "is_deleted": isDeleted,
    "latest_reply_at": latestReplyAt.toIso8601String(),
    "img": img,
    "class": resultClass,
    "contact_name": contactName,
    "contact_name_f": contactNameF,
    "contact_email": contactEmail,
    "assignee": assignee,
    "sent_by": sentBy,
    "last_updated_datetime": lastUpdatedDatetime.toIso8601String(),
    "ago_time": agoTime,
    "last_reply_body": lastReplyBody,
    "last_sent_status": lastSentStatus,
    "last_sent_by_name": lastSentByName,
    "total_reply_count": totalReplyCount,
  };
}
