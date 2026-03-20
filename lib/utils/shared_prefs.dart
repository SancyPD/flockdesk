import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'dart:convert';

class SharedPrefs {

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return json.decode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> setUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // Save name, email, and profile_image explicitly for quick access
    if (user['name'] != null) {
      await prefs.setString('user_name', user['name']);
    }
    if (user['email'] != null) {
      await prefs.setString('user_email', user['email']);
    }
    if (user['profile_image'] != null) {
      await prefs.setString('user_profile_image', user['profile_image']);
    }
    await prefs.setString('user', json.encode(user));
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? (await getUser())?['name'] as String?;
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? (await getUser())?['email'] as String?;
  }

  static Future<String?> getUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_profile_image') ?? (await getUser())?['profile_image'] as String?;
  }

  static const String profileImageBaseUrl = '${ApiConfig.profileImageBaseUrl}/profile_images/';

  static Future<String?> getUserProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? image = prefs.getString('user_profile_image');
    if (image == null || image.isEmpty) {
      final user = await getUser();
      image = user?['profile_image'] as String?;
    }
    if (image == null || image.isEmpty) return null;
    return profileImageBaseUrl + image;
  }

  static Future<int?> getUserId() async {
    final user = await getUser();
    return user?['id'] as int?;
  }

  static Future<int?> getOrgId() async {
    final user = await getUser();
    return user?['org_id'] as int?;
  }

  static Future<String?> getRoleType() async {
    final user = await getUser();
    return user?['role_type'] as String?;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Store last selected status ID for side menu
  static Future<void> setSelectedStatuses(int? lastSelectedStatusId) async {
    final prefs = await SharedPreferences.getInstance();
    if (lastSelectedStatusId != null) {
      await prefs.setInt('last_selected_status_id', lastSelectedStatusId);
    } else {
      await prefs.remove('last_selected_status_id');
    }
  }

  // Retrieve last selected status ID for side menu
  static Future<int?> getSelectedStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_selected_status_id');
  }

  // Store last access time for detecting app reloads
  static Future<void> setLastAccessTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_access_time', time.toIso8601String());
  }

  // Retrieve last access time for detecting app reloads
  static Future<DateTime?> getLastAccessTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_access_time');
    if (timeStr != null) {
      try {
        return DateTime.parse(timeStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Manually clear status selection (can be called from anywhere)
  static Future<void> clearStatusSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_selected_status_id');
    await prefs.remove('last_access_time');
  }
} 