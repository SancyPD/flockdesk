import 'dart:convert';

NotificationsResponse notificationsResponseFromJson(String str) => NotificationsResponse.fromJson(json.decode(str));

String notificationsResponseToJson(NotificationsResponse data) => json.encode(data.toJson());

class NotificationsResponse {
  List<NotificationResult> result;

  NotificationsResponse({
    required this.result,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) => NotificationsResponse(
    result: List<NotificationResult>.from(json["result"].map((x) => NotificationResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class NotificationResult {
  String? ticketTitle;
  String? notificationText;
  String? ago;
  int ticketId;

  NotificationResult({
    required this.ticketTitle,
    required this.notificationText,
    required this.ago,
    required this.ticketId,
  });

  factory NotificationResult.fromJson(Map<String, dynamic> json) => NotificationResult(
    ticketTitle: json["ticket_title"],
    notificationText: json["notification_text"],
    ago: json["ago"],
    ticketId: json["ticket_id"],
  );

  Map<String, dynamic> toJson() => {
    "ticket_title": ticketTitle,
    "notification_text": notificationText,
    "ago": ago,
    "ticket_id": ticketId,
  };
}
