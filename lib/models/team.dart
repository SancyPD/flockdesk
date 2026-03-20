class Team {
  final int teamId;
  final int orgId;
  final String teamTitle;
  final String teamStatus;
  final String members;

  Team({
    required this.teamId,
    required this.orgId,
    required this.teamTitle,
    required this.teamStatus,
    required this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['team_id'],
      orgId: json['org_id'],
      teamTitle: json['team_title'],
      teamStatus: json['team_status'],
      members: json['members'],
    );
  }
} 