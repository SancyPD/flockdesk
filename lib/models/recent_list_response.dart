import 'dart:convert';

RecentListResponse recentListResponseFromJson(String str) => RecentListResponse.fromJson(json.decode(str));

String recentListResponseToJson(RecentListResponse data) => json.encode(data.toJson());

class RecentListResponse {
  final bool success;
  final String message;
  final List<RecentTicket> result;
  final int totalPages;
  final List<int> pages;
  final int currentPage;

  RecentListResponse({
    required this.success,
    required this.message,
    required this.result,
    required this.totalPages,
    required this.pages,
    required this.currentPage,
  });

  factory RecentListResponse.fromJson(Map<String, dynamic> json) {
    return RecentListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => RecentTicket.fromJson(item))
              .toList() ??
          [],
      totalPages: json['total_pages'] ?? 0,
      pages: (json['pages'] as List<dynamic>?)
          ?.map((item) => int.tryParse(item.toString()) ?? 0)
          .toList()
          ?? [],
      currentPage: json['currentPage'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
    "total_pages": totalPages,
    "pages": pages,
    "currentPage": currentPage,
  };
}

class RecentTicket {
  final int ticketId;
  final String contactName;
  final String contactNameF;
  final String contactEmail;
  final String assignee;
  final String img;
  final int statusId;
  final String agoTime;
  final int totalReplyCount;
  final String lastActivity;
  final String lastSentByName;

  RecentTicket({
    required this.ticketId,
    required this.contactName,
    required this.contactNameF,
    required this.contactEmail,
    required this.assignee,
    required this.img,
    required this.statusId,
    required this.agoTime,
    required this.totalReplyCount,
    required this.lastActivity,
    required this.lastSentByName,
  });

  factory RecentTicket.fromJson(Map<String, dynamic> json) {
    return RecentTicket(
      ticketId: json['ticket_id'] ?? 0,
      contactName: json['contact_name'] ?? '',
      contactNameF: json['contact_name_f'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      assignee: json['assignee'] ?? '',
      img: json['img'] ?? '',
      statusId: json['status_id'] ?? 0,
      agoTime: json['ago_time'] ?? '',
      totalReplyCount: json['total_reply_count'] ?? 0,
      lastActivity: json['last_activity'] ?? '',
      lastSentByName: json['last_sent_by_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "ticket_id": ticketId,
    "contact_name": contactName,
    "contact_name_f": contactNameF,
    "contact_email": contactEmail,
    "assignee": assignee,
    "img": img,
    "status_id": statusId,
    "ago_time": agoTime,
    "total_reply_count": totalReplyCount,
    "last_activity": lastActivity,
  };
}