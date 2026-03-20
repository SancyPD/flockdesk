import 'dart:convert';

ViewsResponse viewsResponseFromJson(String str) => ViewsResponse.fromJson(json.decode(str));

String viewsResponseToJson(ViewsResponse data) => json.encode(data.toJson());

class ViewsResponse {
  List<MenuView> result;

  ViewsResponse({required this.result});

  factory ViewsResponse.fromJson(Map<String, dynamic> json) => ViewsResponse(
    result: List<MenuView>.from(json["result"].map((x) => MenuView.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class MenuView {
  int viewId;
  int orgId;
  String viewTitle;
  String viewStatus;
  int sortOrder;
  List<Status> statuses;
  String tagNames;
  String teamNames;

  MenuView({
    required this.viewId,
    required this.orgId,
    required this.viewTitle,
    required this.viewStatus,
    required this.sortOrder,
    required this.statuses,
    required this.tagNames,
    required this.teamNames,
  });

  factory MenuView.fromJson(Map<String, dynamic> json) => MenuView(
    viewId: json["view_id"],
    orgId: json["org_id"],
    viewTitle: json["view_title"],
    viewStatus: json["view_status"],
    sortOrder: json["sort_order"],
    statuses: List<Status>.from(json["statuses"].map((x) => Status.fromJson(x))),
    tagNames: json["tag_names"],
    teamNames: json["team_names"],
  );

  Map<String, dynamic> toJson() => {
    "view_id": viewId,
    "org_id": orgId,
    "view_title": viewTitle,
    "view_status": viewStatus,
    "sort_order": sortOrder,
    "statuses": List<dynamic>.from(statuses.map((x) => x.toJson())),
    "tag_names": tagNames,
    "team_names": teamNames,
  };
}

class Status {
  int statusId;
  String color;
  String background;
  String statusName;
  int mailCount;

  Status({
    required this.statusId,
    required this.color,
    required this.background,
    required this.statusName,
    required this.mailCount,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    statusId: json["status_id"],
    color: json["color"],
    background: json["background"],
    statusName: json["status_name"],
    mailCount: json["mail_count"],
  );

  Map<String, dynamic> toJson() => {
    "status_id": statusId,
    "color": color,
    "background": background,
    "status_name": statusName,
    "mail_count": mailCount,
  };
}
