import 'dart:convert';

SearchResult searchResultFromJson(String str) => SearchResult.fromJson(json.decode(str));

String searchResultToJson(SearchResult data) => json.encode(data.toJson());

class SearchResult {
  List<TicketSearchResult> result;
  int total;
  int totalPages;
  List<int> pages;
  int currentPage;

  SearchResult({
    required this.result,
    required this.total,
    required this.totalPages,
    required this.pages,
    required this.currentPage,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    result: List<TicketSearchResult>.from(json["result"].map((x) => TicketSearchResult.fromJson(x))),
    total: json["total"],
    totalPages: json["total_pages"],
    pages: (json["pages"] as List<dynamic>?)
        ?.map((x) => int.tryParse(x.toString()) ?? 0)
        .toList()
        ?? [],
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

class TicketSearchResult {
  int ticketId;
  String ticketTitle;
  int orgId;
  DateTime createdAt;
  DateTime updatedAt;
  int statusId;

  TicketSearchResult({
    required this.ticketId,
    required this.ticketTitle,
    required this.orgId,
    required this.createdAt,
    required this.updatedAt,
    required this.statusId,
  });

  factory TicketSearchResult.fromJson(Map<String, dynamic> json) => TicketSearchResult(
    ticketId: json["ticket_id"],
    ticketTitle: json["ticket_title"],
    orgId: json["org_id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    statusId: json["status_id"],
  );

  Map<String, dynamic> toJson() => {
    "ticket_id": ticketId,
    "ticket_title": ticketTitle,
    "org_id": orgId,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "status_id": statusId,
  };
}


/*
SearchResult searchResultFromJson(String str) => SearchResult.fromJson(json.decode(str));

String searchResultToJson(SearchResult data) => json.encode(data.toJson());

class SearchResult {
  List<TicketSearchResult> result;
  int total;
  int totalPages;
  List<int> pages;
  int currentPage;

  SearchResult({
    required this.result,
    required this.total,
    required this.totalPages,
    required this.pages,
    required this.currentPage,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    result: List<TicketSearchResult>.from(json["result"].map((x) => TicketSearchResult.fromJson(x))),
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

class TicketSearchResult {
  int ticketId;
  String ticketTitle;
  int orgId;
  DateTime createdAt;
  DateTime updatedAt;
  int statusId;

  TicketSearchResult({
    required this.ticketId,
    required this.ticketTitle,
    required this.orgId,
    required this.createdAt,
    required this.updatedAt,
    required this.statusId,
  });

  factory TicketSearchResult.fromJson(Map<String, dynamic> json) => TicketSearchResult(
    ticketId: json["ticket_id"],
    ticketTitle: json["ticket_title"],
    orgId: json["org_id"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    statusId: json["status_id"],
  );

  Map<String, dynamic> toJson() => {
    "ticket_id": ticketId,
    "ticket_title": ticketTitle,
    "org_id": orgId,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "status_id": statusId,
  };
}*/
