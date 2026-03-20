import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/team.dart';
import '../models/agent_list_response.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_config.dart';

class TeamService {
  Future<List<Team>> listTeams(String token) async {
    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/listTeams')),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['result'] != null) {
        return (data['result'] as List)
            .map((e) => Team.fromJson(e))
            .where((team) => team.teamStatus == '1') // Filter by team_status '1'
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<List<Agents>> getAgentsByTeam(int teamId) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/listAgentsByteam')),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'team_id': teamId.toString(),
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return AgentsListResponse.fromJson(data).result;
    } else {
      throw Exception('Failed to load agents: ${response.statusCode}');
    }
  }
} 