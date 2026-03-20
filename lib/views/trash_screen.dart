import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trash_tickets_response.dart';
import '../services/ticket_service.dart';
import '../utils/shared_prefs.dart';
import '../widgets/side_menu_widget.dart';
import 'ticket_details_screen.dart';
import 'home_screen.dart';
import 'new_ticket_screen.dart';
import 'dart:async';

class TrashScreen extends StatefulWidget {
  final List<ViewItem> allViewItems; // All view items for the side menu
  final ValueNotifier<Map<int, bool>> allViewExpansionNotifier;
  final Function(int)
  onViewExpansionToggle; // Callback for toggling view expansion
  final Function(Widget, String)
  onMainScreenChange; // Callback to change main screen

  const TrashScreen({
    super.key,
    required this.allViewItems,
    required this.allViewExpansionNotifier,
    required this.onViewExpansionToggle,
    required this.onMainScreenChange,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TicketService _ticketService = TicketService();
  List<TrashTicket> _tickets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String? _userProfileImageUrl;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
    _loadTrashTickets(refresh: true);
    _preloadTrashCount();
  }

  // Preload trash count when screen launches
  Future<void> _preloadTrashCount() async {
    // Use a small delay to ensure the side menu widget is created
    await Future.delayed(const Duration(milliseconds: 100));
    SideMenuWidget.refreshTrashCount();
    SideMenuWidget.refreshInboxCount();
  }

  Future<void> _loadUserProfileImage() async {
    final url = await SharedPrefs.getUserProfileImageUrl();
    setState(() {
      _userProfileImageUrl = url;
    });
  }

  Future<void> _loadTrashTickets({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMorePages = true;
        });
      } else {
        // Check if we can load more pages before making the API call
        if (_currentPage >= _totalPages && _totalPages > 0) {
          setState(() {
            _hasMorePages = false;
          });
          return;
        }

        setState(() {
          _isLoadingMore = true;
        });
      }

      final ticketResponse = await _ticketService.getTrashTickets(
        dateSort: 2,
        idSort: 0,
        page: refresh ? 1 : _currentPage + 1,
      );

      setState(() {
        if (refresh) {
          _tickets = ticketResponse.result;
          _isLoading = false;
        } else {
          _tickets.addAll(ticketResponse.result);
          _isLoadingMore = false;
        }
        _currentPage = ticketResponse.currentPage;
        _totalPages = ticketResponse.totalPages;
        _hasMorePages = _currentPage < _totalPages;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColor(int statusId) {
    switch (statusId) {
      case 1: // New
        return const Color(0xffE6F7EC);
      case 2: // In Progress
        return const Color(0xffE3F0FF);
      case 3: // Pending
        return const Color(0xffFFEAEA);
      case 4: // Done
        return const Color(0xffFFF7E6);
      default:
        return const Color(0xffE6F7EC);
    }
  }

  Color _getStatusTextColor(int statusId) {
    switch (statusId) {
      case 1: // New
        return const Color(0xff39CAA4);
      case 2: // In Progress
        return const Color(0xffA486AA);
      case 3: // Pending
        return const Color(0xff7F9BCE);
      default:
        return const Color(0xff339CAA4);
    }
  }

  String _getStatusText(int statusId) {
    switch (statusId) {
      case 1:
        return 'Open';
      case 2:
        return 'Pending';
      case 3:
        return 'Completed';
      default:
        return 'New';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: SideMenuWidget(
          onScreenChange: (screen, title) {
            widget.onMainScreenChange(screen, title);
            Navigator.of(context).pop();
          },
          viewItems: widget.allViewItems,
          viewExpansionNotifier: widget.allViewExpansionNotifier,
          onViewExpansionToggle: widget.onViewExpansionToggle,
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/images/menu.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text(
            'Trash',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Image.asset(
                'assets/images/add_but.png',
                width: 24,
                height: 24,
                color: Color(0xff313131),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewTicketScreen(),
                  ),
                );
                // If ticket was created successfully, refresh the trash list
                if (result == true) {
                  _loadTrashTickets();
                }
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/images/notification_ic.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                // TODO: Navigate to NotificationsScreen
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    _userProfileImageUrl != null &&
                        _userProfileImageUrl!.isNotEmpty
                    ? NetworkImage(_userProfileImageUrl!)
                    : const AssetImage('assets/images/user.png')
                          as ImageProvider,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadTrashTickets(refresh: true),
                child: ListView.separated(
                  itemCount: _tickets.length + (_hasMorePages ? 1 : 0),
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    color: const Color(0xFFEFEFEF),
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end for pagination
                    if (index == _tickets.length) {
                      if (_hasMorePages &&
                          !_isLoadingMore &&
                          _currentPage < _totalPages) {
                        // Load more data when reaching the end
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadTrashTickets();
                        });
                      }
                      return _hasMorePages && _currentPage < _totalPages
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }

                    final ticket = _tickets[index];
                    return _ticketItem(
                      context,
                      ticketId: ticket.ticketId,
                      avatar: ticket.img.isNotEmpty
                          ? ticket.img
                          : 'assets/images/user.png',
                      fromAvatar: ticket.img.isNotEmpty
                          ? ticket.img
                          : 'assets/images/user.png',
                      title: ticket.contactName,
                      subtitle: _cleanTicketTitle(ticket.ticketTitle),
                      status: _getStatusText(ticket.statusId),
                      statusColor: _getStatusColor(ticket.statusId),
                      statusTextColor: _getStatusTextColor(ticket.statusId),
                      time: ticket.agoTime,
                      comments: ticket.totalReplyCount,
                      contactNameF: ticket.contactName.substring(0,2),
                      lastSentByName: ticket.lastSentByName,
                      itemIndex: index,
                    );
                  },
                ),
              ),

      ),
    );
  }

  Widget _ticketItem(
    BuildContext context, {
    required int ticketId,
    required String avatar,
    required String fromAvatar,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
    required String time,
    required int comments,
    required String contactNameF,
    required String lastSentByName,
    required int itemIndex,
  }) {
    return GestureDetector(
      onTap: () {
        print("GestureDetector item clicked");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TicketDetailsScreen(ticketId: ticketId, fromTrash: true),
          ),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        leading: CircleAvatar(
          backgroundColor: _getAvatarColor(itemIndex),
          child: Center(
            child: Text(
              contactNameF.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          radius: 18,
        ),
        title: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "#$ticketId",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: const Color(0xFF828282),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                if (lastSentByName.isNotEmpty) ...[
                  Image.asset(
                    'assets/images/reply_ic.png',
                    width: 13,
                    height: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    extractFirstPart(lastSentByName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xff3F3F3F),
                    ),
                  ),
                ],
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: Color(0xff828282),
                      ),
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      'assets/images/messages_ic.png',
                      width: 16,
                      height: 16,
                      color: Color(0xff454545),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      comments > 99 ? "99+" : '$comments',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xff454545),
                      ),
                    ),
                  ],
                ),
              ],
            )
            /*Row(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/user_ic.png',
                      width: 13,
                      height: 13,
                    ),
                    SizedBox(width: 3),
                    Container(
                      width: 90,
                      child: Text(
                        extractFirstPart(_cleanTicketTitle(title)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xFF3F3F3F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (lastSentByName.isNotEmpty) ...[
                        Image.asset(
                          'assets/images/reply_ic.png',
                          width: 13,
                          height: 13,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            extractFirstPart(lastSentByName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff3F3F3F),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Color(0xff828282),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Image.asset(
                        'assets/images/messages_ic.png',
                        width: 16,
                        height: 16,
                        color: Color(0xff454545),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        comments > 99 ? "99+" : '$comments',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xff454545),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Color(0xFFffabc2),
      Color(0xFFcadff2),
      Color(0xFFd0c3bd),
      Color(0xFF9fdfea),
      Color(0xFFfbd0da),
      Color(0xFFd9d9d9),
      Color(0xFFfebfb8),
      Color(0xFFc1ded9),
      Color(0xFFfedbcf),
      Color(0xFFd6c8ed),
      Color(0xFFe9d7de),
      Color(0xFFd2e2c0),
      Color(0xFFc0d5fd),
    ];

    // Use index to cycle through colors
    return colors[index % colors.length];
  }


  String extractFirstPart(String input) {
    if (input.contains(' ')) {
      return input.split(' ')[0];
    } else if (input.contains('.')) {
      return input.split('.')[0];
    } else {
      return input;
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
}
