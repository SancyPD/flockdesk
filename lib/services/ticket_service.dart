import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/notifications_response.dart';
import '../models/ticket_response.dart';
import '../models/view_ticket_response.dart';
import '../models/ticket_details_response.dart';
import '../models/ticket_status_response.dart';
import '../models/tags_response.dart';
import '../models/serach_result.dart';
import '../models/recent_list_response.dart';
import '../models/ticket_replies_response.dart';
import '../models/trash_tickets_response.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_config.dart';

class TicketService {
  Future<TicketResponse> getInboxTickets() async {
    final token = await SharedPrefs.getToken();
    print("Token:$token");
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/inboxTickets')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'datesort': '2', 'idsort': '0'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TicketResponse.fromJson(data);
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getInboxTickets: $e'); // Debug log
      throw Exception('Failed to load tickets: $e');
    }
  }

  Future<ViewTicketResponse> getTicketsByView({
    required int viewId,
    required int statusId,
    required int dateSort,
    required int idSort,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getticketsByview')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'view_id': viewId.toString(),
          'status_id': statusId.toString(),
          'datesort': dateSort.toString(),
          'idsort': idSort.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ViewTicketResponse.fromJson(data);
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTicketsByView: $e'); // Debug log
      throw Exception('Failed to load tickets: $e');
    }
  }

  Future<bool> createTicket({
    required String toEmail,
    required String ccMails,
    required String toName,
    required String subject,
    required String mailContent,
    required String fromEmail,
    required int hasAttachments,
    required List<PlatformFile> attachments,
    required int teamId,
    required int assignTo,
    required int status,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      var uri = Uri.parse(ApiConfig.buildUrl('/createTicket'));
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['to_email'] = toEmail;
      request.fields['cc_mails'] = ccMails;
      request.fields['to_name'] = toName;
      request.fields['subject'] = subject;
      request.fields['mail_content'] = mailContent;
      request.fields['from_email'] = fromEmail;
      request.fields['has_attachments'] = hasAttachments.toString();
      if (teamId != 0) {
        request.fields['team_id'] = teamId.toString();
      } else {
        request.fields['team_id'] = "";
      }

      if (assignTo != 0) {
        request.fields['assign_to'] = assignTo.toString();
      } else {
        request.fields['assign_to'] = "";
      }

      if (status != 0) {
        request.fields['status'] = status.toString();
      } else {
        request.fields['status'] = "1";
      }

      // Attach files
      for (final file in attachments) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments[]',
              file.path!,
              filename: file.name,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments[]',
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final result = data['result'] as String?;
        if (result == 'Ticket Created successfully') {
          return true;
        } else {
          throw Exception('Unexpected response: $result');
        }
      } else {
        throw Exception('Failed to create ticket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createTicket: $e'); // Debug log
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<TicketDetailResult> getTicketDetails(int ticketId) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/ticketDetails')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'ticket_id': ticketId.toString()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TicketDetailResponse.fromJson(data).result;
      } else {
        throw Exception(
          'Failed to load ticket details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getTicketDetails: $e'); // Debug log
      throw Exception('Failed to load ticket details: $e');
    }
  }

  Future<List<TicketStatus>> getTicketStatuses() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getTicketstatus')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          // No specific body parameters mentioned for getTicketStatus
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TicketStatusResponse.fromJson(data).result;
      } else {
        throw Exception(
          'Failed to load ticket statuses: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getTicketStatuses: $e'); // Debug log
      throw Exception('Failed to load ticket statuses: $e');
    }
  }

  Future<List<TagDetails>> getActiveTags() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getActivetags')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TagsResponse.fromJson(data).result;
      } else {
        throw Exception('Failed to load active tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getActiveTags: $e');
      throw Exception('Failed to load active tags: $e');
    }
  }

  Future<NotificationsResponse> getNotifications() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getNotifications')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return NotificationsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getNotifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> clearNotifications() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      // Placeholder for the actual API call.
      // Replace '/clearNotifications' with the correct endpoint once known.
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/clearNotifications')),
        // *** REPLACE WITH ACTUAL ENDPOINT ***
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to clear notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in clearNotifications: $e');
      throw Exception('Failed to clear notifications: $e');
    }
  }

  Future<bool> updateTicket({
    required int ticketId,
    required int userId,
    required int teamId,
    required int statusId,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/updateTicket')),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'ticket_id': ticketId.toString(),
        'user_id': userId.toString(),
        'team_id': teamId.toString(),
        'status_id': statusId.toString(),
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('error')) {
        throw Exception(data['error'][0]);
      }
      return data['result'] == 'Updated Successfully';
    } else {
      throw Exception('Failed to update ticket: \\${response.statusCode}');
    }
  }

  Future<bool> updateTicketTags({
    required int ticketId,
    required List<int> tagIds,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final response = await http.post(
      Uri.parse(ApiConfig.buildUrl('/removeaddticketTags')),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'ticket_id': ticketId.toString(),
        'tags_needto_assign': tagIds.isEmpty ? '' : tagIds.join(','),
        'new_tags_needto_assign': '',
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('error')) {
        throw Exception(data['error'][0]);
      }
      return data['result'] == 'Updated successfully';
    } else {
      throw Exception('Failed to update ticket tags: \\${response.statusCode}');
    }
  }

  Future<SearchResult> searchTickets({
    required String searchKey,
    required int page,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/searchTickets')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'search_key': searchKey, 'page': page.toString()},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SearchResult.fromJson(data);
      } else {
        throw Exception('Failed to search tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchTickets: $e'); // Debug log
      throw Exception('Failed to search tickets: $e');
    }
  }

  Future<RecentListResponse> getRecentTickets({
    int dateSort = 2,
    int idSort = 0,
    int page = 1,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getTicketsbasedonactivity')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'datesort': dateSort.toString(),
          'idsort': idSort.toString(),
          'page': page.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return RecentListResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load recent tickets: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getRecentTickets: $e'); // Debug log
      throw Exception('Failed to load recent tickets: $e');
    }
  }

  Future<bool> trashTicket({
    required int ticketId,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/trashTickets')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'ticket_ids': ticketId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result'] == 'Trashed the selected tickets';
      } else {
        throw Exception('Failed to move ticket to trash: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in trashTicket: $e');
      throw Exception('Failed to move ticket to trash: $e');
    }
  }

  Future<TicketRepliesResponse> getTicketReplies({
    required int ticketId,
    int page = 1,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/ticketReplies')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'ticket_id': ticketId.toString(),
          'page': page.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TicketRepliesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load ticket replies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTicketReplies: $e');
      throw Exception('Failed to load ticket replies: $e');
    }
  }

  Future<int> getTrashCount() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getTrashCount')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result']['count'] ?? 0;
      } else {
        throw Exception('Failed to load trash count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTrashCount: $e');
      return 0; // Return 0 on error to avoid breaking the UI
    }
  }

  Future<TrashTicketsResponse> getTrashTickets({
    int dateSort = 2,
    int idSort = 0,
    int page = 1,
  }) async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getTrash')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'datesort': dateSort.toString(),
          'idsort': idSort.toString(),
          'page': page.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TrashTicketsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load trash tickets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTrashTickets: $e');
      throw Exception('Failed to load trash tickets: $e');
    }
  }

  Future<int> getInboxTicketsCount() async {
    final token = await SharedPrefs.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/inboxTicketsCount')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['result']['count'] ?? 0;
      } else {
        throw Exception('Failed to load inbox count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getInboxTicketsCount: $e');
      return 0;
    }
  }
}