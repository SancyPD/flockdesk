import 'dart:convert';
import 'package:flutter/material.dart';

TicketStatusResponse ticketStatusResponseFromJson(String str) => TicketStatusResponse.fromJson(json.decode(str));

String ticketStatusResponseToJson(TicketStatusResponse data) => json.encode(data.toJson());

class TicketStatusResponse {
  List<TicketStatus> result;

  TicketStatusResponse({
    required this.result,
  });

  factory TicketStatusResponse.fromJson(Map<String, dynamic> json) => TicketStatusResponse(
    result: List<TicketStatus>.from(json["result"].map((x) => TicketStatus.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class TicketStatus {
  int statusId;
  String statusName;
  String color;

  TicketStatus({
    required this.statusId,
    required this.statusName,
    required this.color,
  });

  factory TicketStatus.fromJson(Map<String, dynamic> json) => TicketStatus(
    statusId: json["status_id"],
    statusName: json["status_name"],
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "status_id": statusId,
    "status_name": statusName,
    "color": color,
  };
}