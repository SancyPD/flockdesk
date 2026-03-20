import 'package:http/http.dart' as http;
import '../models/profile_response.dart';
import '../models/views_response.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_config.dart';

class ProfileService {
  Future<Result> getUserProfile() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse(ApiConfig.buildUrl('/profile'));
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final profileResponse = profileResponseFromJson(response.body);
        return profileResponse.result;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<List<MenuView>> getViews() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse(ApiConfig.buildUrl('/getViews'));
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final viewsResponse = viewsResponseFromJson(response.body);
        // Filter for views where view_status is '1'
        return viewsResponse.result.where((view) => view.viewStatus == '1').toList();
      } else {
        throw Exception('Failed to load views: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load views: $e');
    }
  }
} 