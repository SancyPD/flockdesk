import 'dart:convert';

TicketRepliesResponse ticketRepliesResponseFromJson(String str) => TicketRepliesResponse.fromJson(json.decode(str));

String ticketRepliesResponseToJson(TicketRepliesResponse data) => json.encode(data.toJson());

class TicketRepliesResponse {
  Result result;

  TicketRepliesResponse({
    required this.result,
  });

  factory TicketRepliesResponse.fromJson(Map<String, dynamic> json) => TicketRepliesResponse(
    result: Result.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "result": result.toJson(),
  };
}

class Result {
  List<RepliesDatum> repliesData;
  int totalItems;
  int perPage;
  int currentPage;
  int totalPages;

  Result({
    required this.repliesData,
    required this.totalItems,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    repliesData: List<RepliesDatum>.from(json["replies_data"].map((x) => RepliesDatum.fromJson(x))),
    totalItems: json["total_items"],
    perPage: json["per_page"],
    currentPage: json["current_page"],
    totalPages: json["total_pages"],
  );

  Map<String, dynamic> toJson() => {
    "replies_data": List<dynamic>.from(repliesData.map((x) => x.toJson())),
    "total_items": totalItems,
    "per_page": perPage,
    "current_page": currentPage,
    "total_pages": totalPages,
  };
}

class RepliesDatum {
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
  int itemNumber;
  List<Recipient> recipients;
  String messageSentBy;
  List<Attachment> attachments;

  RepliesDatum({
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
    required this.itemNumber,
    required this.recipients,
    required this.messageSentBy,
    required this.attachments,
  });

  factory RepliesDatum.fromJson(Map<String, dynamic> json) => RepliesDatum(
    replyId: json["reply_id"],
    messageId: json["message_id"]??"",
    referenceId: json["reference_id"]??"",
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
    itemNumber: json["item_number"],
    recipients: List<Recipient>.from(json["recipients"].map((x) => Recipient.fromJson(x))),
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
    "item_number": itemNumber,
    "recipients": List<dynamic>.from(recipients.map((x) => x.toJson())),
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

class Recipient {
  int ccEmailId;
  int ticketId;
  int replyId;
  String emailId;
  String mailType;
  String emailSentStatus;
  DateTime lastUpdated;
  String timeago;

  Recipient({
    required this.ccEmailId,
    required this.ticketId,
    required this.replyId,
    required this.emailId,
    required this.mailType,
    required this.emailSentStatus,
    required this.lastUpdated,
    required this.timeago,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) => Recipient(
    ccEmailId: json["cc_email_id"],
    ticketId: json["ticket_id"],
    replyId: json["reply_id"],
    emailId: json["email_id"],
    mailType: json["mail_type"],
    emailSentStatus: json["email_sent_status"],
    lastUpdated: DateTime.parse(json["last_updated"]),
    timeago: json["timeago"],
  );

  Map<String, dynamic> toJson() => {
    "cc_email_id": ccEmailId,
    "ticket_id": ticketId,
    "reply_id": replyId,
    "email_id": emailId,
    "mail_type": mailType,
    "email_sent_status": emailSentStatus,
    "last_updated": lastUpdated.toIso8601String(),
    "timeago": timeago,
  };
}