import 'package:flockdesk/views/ticket_details_screen.dart';
import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../models/notifications_response.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TicketService _ticketService = TicketService();
  List<NotificationResult> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await _ticketService.getNotifications();
      setState(() {
        _notifications = response.result ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _cleanTicketTitle(String title) {
    // Remove escaped quotes and clean up the title
    return title
        .replaceAll('\\"', '"') // Replace escaped quotes with regular quotes
        .replaceAll(
          '\\n',
          '\n',
        ) // Replace escaped newlines with actual newlines
        .replaceAll('\\t', '\t') // Replace escaped tabs with actual tabs
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/clear_notifications_ic.png',
              height: 36,
            ),
            onPressed: () async {
              // try {
              //   setState(() {
              //     _isLoading = true; // Show loading indicator during clearing
              //   });
              //   await _ticketService.clearNotifications();
              //   await _loadNotifications(); // Reload notifications after clearing
              // } catch (e) {
              //   setState(() {
              //     _error = e.toString(); // Show error if clearing fails
              //     _isLoading = false;
              //   });
              //   // Optionally show a SnackBar or AlertDialog for the error
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(content: Text('Failed to clear notifications: ${e.toString()}')),
              //   );
              // }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFEFEFEF)),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailsScreen(
                          ticketId: notification.ticketId,
                          fromTrash: false,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD5F0E8),
                                // Light green background
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/not_ic.png',
                                  height: 16,
                                  fit: BoxFit.contain,
                                  color: const Color(0xFF3BCAA4),
                                ), // Green checkmark
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cleanTicketTitle(
                                      notification.ticketTitle ?? '',
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF313131),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.notificationText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6A6A6A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8,),
                        Padding(
                          padding: const EdgeInsets.only(left: 50.0),
                          child: Text(
                            notification.ago ?? '',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
