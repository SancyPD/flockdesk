import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs.dart';
import '../models/search_email_response.dart';
import '../utils/api_config.dart';

class DeskService {
  Future<DeskListResponse> getDeskList({String key = ''}) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/listDesk')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'key': key,
      }),
    );

    if (response.statusCode == 200) {
      return DeskListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load desk list: ${response.statusCode}');
    }
  }

  Future<SearchEmailResponse> searchEmails({String key = ''}) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/searchEmail')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'key': key,
      }),
    );

    if (response.statusCode == 200) {
      return SearchEmailResponse.fromJson(json.decode(response.body));
    } else {
       throw Exception('Failed to search emails: ${response.statusCode}');
    }
  }
}

class DeskListResponse {
  final List<DeskResult> result;

  DeskListResponse({required this.result});

  factory DeskListResponse.fromJson(Map<String, dynamic> json) => DeskListResponse(
        result: List<DeskResult>.from(json["result"].map((x) => DeskResult.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "result": List<dynamic>.from(result.map((x) => x.toJson())),
      };
}

class DeskResult {
  final int deskId;
  final int orgId;
  final String emailAddress;
  final String deskStatus;

  DeskResult({
    required this.deskId,
    required this.orgId,
    required this.emailAddress,
    required this.deskStatus,
  });

  factory DeskResult.fromJson(Map<String, dynamic> json) => DeskResult(
        deskId: json["desk_id"],
        orgId: json["org_id"],
        emailAddress: json["email_address"],
        deskStatus: json["desk_status"],
      );

  Map<String, dynamic> toJson() => {
        "desk_id": deskId,
        "org_id": orgId,
        "email_address": emailAddress,
        "desk_status": deskStatus,
      };
} 