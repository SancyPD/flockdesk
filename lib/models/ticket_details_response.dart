import 'dart:convert';

import 'package:flockdesk/models/tags_response.dart';

TicketDetailResponse ticketDetailResponseFromJson(String str) => TicketDetailResponse.fromJson(json.decode(str));

String ticketDetailResponseToJson(TicketDetailResponse data) => json.encode(data.toJson());

class TicketDetailResponse {
  TicketDetailResult result;

  TicketDetailResponse({
    required this.result,
  });

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) => TicketDetailResponse(
    result: TicketDetailResult.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "result": result.toJson(),
  };
}

class TicketDetailResult {
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
  int isDeleted;
  List<TagDetails> tags;
  List<dynamic> lastReplyCcMails;
  List<String> mustCcMails;
  ContactDetails contactDetails;
  String suggestedFromEmail;

  TicketDetailResult({
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
    required this.isDeleted,
    required this.tags,
    required this.lastReplyCcMails,
    required this.mustCcMails,
    required this.contactDetails,
    required this.suggestedFromEmail,
  });

  factory TicketDetailResult.fromJson(Map<String, dynamic> json) => TicketDetailResult(
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
    isDeleted: json["is_deleted"],
    tags: List<TagDetails>.from(json["tags"].map((x) => TagDetails.fromJson(x))),
    lastReplyCcMails: List<dynamic>.from(json["last_reply_cc_mails"].map((x) => x)),
    mustCcMails: List<String>.from(json["must_cc_mails"].map((x) => x)),
    contactDetails: ContactDetails.fromJson(json["contact_details"]),
    suggestedFromEmail: json["suggested_from_email"],
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
    "is_deleted": isDeleted,
    "tags": List<dynamic>.from(tags.map((x) => x.toJson())),
    "last_reply_cc_mails": List<dynamic>.from(lastReplyCcMails.map((x) => x)),
    "must_cc_mails": List<dynamic>.from(mustCcMails.map((x) => x)),
    "contact_details": contactDetails.toJson(),
    "suggested_from_email": suggestedFromEmail,
  };
}

class ContactDetails {
  int contactId;
  int orgId;
  String contactName;
  String emailId;
  DateTime createdAt;
  DateTime updatedAt;

  ContactDetails({
    required this.contactId,
    required this.orgId,
    required this.contactName,
    required this.emailId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) => ContactDetails(
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

class Reply {
  int replyId;
  String messageId;
  String referenceId;
  int ticketId;
  String sentBy;
  int senderId;
  String messageText;
  dynamic textContent;
  String messageHtml;
  String sendFrom;
  String sendTo;
  DateTime createdAt;
  DateTime updatedAt;
  dynamic ccMails;
  String sentStatus;
  String messageSentBy;
  List<Attachment> attachments;

  Reply({
    required this.replyId,
    required this.messageId,
    required this.referenceId,
    required this.ticketId,
    required this.sentBy,
    required this.senderId,
    required this.messageText,
    required this.textContent,
    required this.messageHtml,
    required this.sendFrom,
    required this.sendTo,
    required this.createdAt,
    required this.updatedAt,
    required this.ccMails,
    required this.sentStatus,
    required this.messageSentBy,
    required this.attachments,
  });

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
    replyId: json["reply_id"],
    messageId: json["message_id"],
    referenceId: json["reference_id"] ?? "" ,
    ticketId: json["ticket_id"],
    sentBy: json["sent_by"],
    senderId: json["sender_id"],
    messageText: json["message_text"],
    textContent: json["text_content"],
    messageHtml: json["message_html"],
    sendFrom: json["send_from"],
    sendTo: json["send_to"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    ccMails: json["cc_mails"],
    sentStatus: json["sent_status"],
    messageSentBy: json["message_sent_by"],
    attachments: List<Attachment>.from(json["attachments"].map((x) => Attachment.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "reply_id": replyId,
    "message_id": messageId,
    "reference_id": referenceId,
    "ticket_id": ticketId,
    "sent_by": sentBy,
    "sender_id": senderId,
    "message_text": messageText,
    "text_content": textContent,
    "message_html": messageHtml,
    "send_from": sendFrom,
    "send_to": sendTo,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "cc_mails": ccMails,
    "sent_status": sentStatus,
    "message_sent_by": messageSentBy,
    "attachments": List<dynamic>.from(attachments.map((x) => x.toJson())),
  };
}

class Attachment {
  int attachmentId;
  int replyId;
  String attachmentName;
  String attachmentFile;
  String fullPath;

  Attachment({
    required this.attachmentId,
    required this.replyId,
    required this.attachmentName,
    required this.attachmentFile,
    required this.fullPath,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    attachmentId: json["attachment_id"],
    replyId: json["reply_id"],
    attachmentName: json["attachment_name"],
    attachmentFile: json["attachment_file"],
    fullPath: json["full_path"],
  );

  Map<String, dynamic> toJson() => {
    "attachment_id": attachmentId,
    "reply_id": replyId,
    "attachment_name": attachmentName,
    "attachment_file": attachmentFile,
    "full_path": fullPath,
  };
}