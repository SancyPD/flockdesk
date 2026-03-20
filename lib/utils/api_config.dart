class ApiConfig {
  static const String baseUrl = 'https://helpdesk.mindlabs.systems/desk/public/api';
  static const String profileImageBaseUrl = 'https://helpdesk.mindlabs.systems/desk/storage/app/public';

  // API endpoints
  static const String login = '/login';
  static const String getActiveMacros = '/getActivemacros';
  static const String sendReply = '/sendReply';
  
  // Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}