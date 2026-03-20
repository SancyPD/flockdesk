import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flockdesk/models/view_ticket_response.dart';
import 'package:flockdesk/models/serach_result.dart' as search_model;
import 'package:flockdesk/utils/shared_prefs.dart';
import '../services/ticket_service.dart';
import '../widgets/side_menu_widget.dart';
import 'notifications_screen.dart';
import 'ticket_details_screen.dart';
import 'new_ticket_screen.dart';
import 'dart:async';

class TicketsByViewScreen extends StatefulWidget {
  final int viewId;
  final int statusId;
  final String viewTitle;
  final String statusName;
  final List<ViewItem> allViewItems; // All view items for the side menu
  final ValueNotifier<Map<int, bool>> allViewExpansionNotifier;
  final Function(int)
  onAllViewExpansionToggle; // Callback for toggling view expansion
  final Function(Widget, String)
  onMainScreenChange; // Callback to change main screen
  final ValueNotifier<bool>? refreshNotifier;

  const TicketsByViewScreen({
    super.key,
    required this.viewId,
    required this.statusId,
    required this.viewTitle,
    required this.statusName,
    required this.allViewItems,
    required this.allViewExpansionNotifier,
    required this.onAllViewExpansionToggle,
    required this.onMainScreenChange,
    this.refreshNotifier,
  });

  @override
  State<TicketsByViewScreen> createState() => _TicketsByViewScreenState();
}

class _TicketsByViewScreenState extends State<TicketsByViewScreen> {
  final TicketService _ticketService = TicketService();
  List<ViewTicketResult> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String? _userProfileImageUrl;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _searchScrollController = ScrollController();
  List<search_model.TicketSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchMode = false;
  Timer? _searchDebounce;

  // Pagination for search
  int _currentSearchPage = 1;
  int _totalSearchPages = 0;
  bool _isLoadingMore = false;
  bool _hasMorePages = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
    _loadTicketsByView();
    _searchScrollController.addListener(_onSearchScroll);
    _preloadTrashCount();
    
    // Listen to refresh notifier
    widget.refreshNotifier?.addListener(_onRefreshTriggered);
  }

  // Preload trash count when screen launches
  Future<void> _preloadTrashCount() async {
    // Use a small delay to ensure the side menu widget is created
    await Future.delayed(const Duration(milliseconds: 100));
    SideMenuWidget.refreshTrashCount();
    SideMenuWidget.refreshInboxCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchScrollController.dispose();
    _searchDebounce?.cancel();
    widget.refreshNotifier?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    if (mounted) {
      _loadTicketsByView();
    }
  }

  Future<void> _loadUserProfileImage() async {
    final url = await SharedPrefs.getUserProfileImageUrl();
    setState(() {
      _userProfileImageUrl = url;
    });
  }

  Future<void> _loadTicketsByView() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final ticketResponse = await _ticketService.getTicketsByView(
        viewId: widget.viewId,
        statusId: widget.statusId,
        dateSort: 2,
        idSort: 0,
      );
      setState(() {
        _tickets = ticketResponse.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  void _onSearchScroll() {
    if (_searchScrollController.position.pixels >=
        _searchScrollController.position.maxScrollExtent - 200) {
      _loadMoreSearchResults();
    }
  }

  Future<void> _searchTickets(String searchKey, {bool loadMore = false}) async {
    if (searchKey.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchResults = [];
        _currentSearchPage = 1;
        _totalSearchPages = 0;
        _hasMorePages = false;
      });
      return;
    }

    try {
      setState(() {
        if (loadMore) {
          _isLoadingMore = true;
        } else {
          _isSearching = true;
          _isSearchMode = true;
          _currentSearchPage = 1;
          _searchResults = [];
        }
      });

      final searchResponse = await _ticketService.searchTickets(
        searchKey: searchKey,
        page: _currentSearchPage,
      );

      setState(() {
        if (loadMore) {
          _searchResults.addAll(searchResponse.result);
          _isLoadingMore = false;
        } else {
          _searchResults = searchResponse.result;
          _isSearching = false;
        }

        _totalSearchPages = searchResponse.totalPages;
        _hasMorePages = _currentSearchPage < _totalSearchPages;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: ${e.toString()}';
        _isSearching = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchTickets(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchMode = false;
      _searchResults = [];
      _currentSearchPage = 1;
      _totalSearchPages = 0;
      _hasMorePages = false;
    });
  }

  void _loadMoreSearchResults() {
    if (_hasMorePages && !_isLoadingMore && _searchController.text.isNotEmpty) {
      setState(() {
        _currentSearchPage++;
      });
      _searchTickets(_searchController.text, loadMore: true);
    }
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    search_model.TicketSearchResult searchResult,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailsScreen(
              ticketId: searchResult.ticketId,
              fromTrash: false,
              onTicketTrashed: () {
                // Refresh the tickets by view list when ticket is moved to trash
                _loadTicketsByView();
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanTicketTitle(searchResult.ticketTitle),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF313131),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last Update: ${_formatDateTime(searchResult.updatedAt)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF828282),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getStatusTextColor(searchResult.statusId),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon(
                  //   Icons.check_circle,
                  //   size: 16,
                  //   color: _getStatusTextColor(searchResult.statusId),
                  // ),
                  // const SizedBox(width: 6),
                  Text(
                    _getStatusText(searchResult.statusId),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: _getStatusTextColor(searchResult.statusId),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour ago';
    } else {
      return '${difference.inDays} day ago';
    }
  }

  /* Color _getAvatarColor(int index) {
    final colors = [
      Color(0xFFfabebe),
      Color(0xFFe6beff),
      Color(0xFFaaffc3),
      Color(0xFFF28BA8),
      Color(0xFF8DD694),
      Color(0xFFFFF6A1),
      Color(0xFF8CA8F0),
      Color(0xFFFFB884),
      Color(0xFFC59DDC),
      Color(0xFFF5A9F3),
      Color(0xFFD4F58D),
      Color(0xFF80CCCC),
      Color(0xFFC6A98A),
      Color(0xFFD48A8A),
      Color(0xFF8A8AD4),
      Color(0xFFCCCCCC),
      Color(0xFF46f0f0),
    ];

    // Use index to cycle through colors
    return colors[index % colors.length];
  } */
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
          onViewExpansionToggle: widget.onAllViewExpansionToggle,
        ),
        // floatingActionButton: Padding(
        //   padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        //   child: GestureDetector(
        //     onTap: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => const NewTicketScreen()),
        //       );
        //     },
        //     child: Image.asset(
        //       'assets/images/floating_but.png',
        //       width: 70,
        //       height: 70,
        //     ),
        //   ),
        // ),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 5,
                backgroundColor: _getStatusTextColor(widget.statusId),
              ),
              const SizedBox(width: 5),
              Text(
                widget.viewTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),

              /*  Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.statusId),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.statusName,
                  style: TextStyle(
                      color: _getStatusTextColor(widget.statusId),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),*/
            ],
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
                // If ticket was created successfully, refresh the tickets list
                if (result == true) {
                  _loadTicketsByView();
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tickets...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  print("Tapped Expanded area");
                },
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _isSearchMode
                    ? _searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'No results found',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              controller: _searchScrollController,
                              itemCount:
                                  _searchResults.length +
                                  (_hasMorePages ? 1 : 0),
                              separatorBuilder: (context, index) => Container(
                                height: 1,
                                color: const Color(0xFFEFEFEF),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                if (index == _searchResults.length) {
                                  // Show loading indicator for pagination
                                  return _hasMorePages
                                      ? Container(
                                          padding: const EdgeInsets.all(16),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }

                                return _buildSearchResultItem(
                                  context,
                                  _searchResults[index],
                                );
                              },
                            )
                    : RefreshIndicator(
                        onRefresh: _loadTicketsByView,
                        child: ListView.separated(
                          itemCount: _tickets.length,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            color: const Color(0xFFEFEFEF),
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                          ),
                          itemBuilder: (context, index) {
                            print("Building item $index");
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
                              statusTextColor: _getStatusTextColor(
                                ticket.statusId,
                              ),
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
            ),
          ],
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
            builder: (context) => TicketDetailsScreen(
              ticketId: ticketId,
              fromTrash: false,
              onTicketTrashed: () {
                // Refresh the tickets by view list when ticket is moved to trash
                _loadTicketsByView();
              },
            ),
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

  String _formatDateTime(DateTime dateTime) {
    // Parse the input string as UTC
    DateTime utcTime = DateFormat(
      "yyyy-MM-dd HH:mm:ss",
    ).parseUtc(dateTime.toString());

    // Convert to IST (+05:30)
    DateTime istTime = utcTime.add(const Duration(hours: 5, minutes: 30));

    // Format as required
    String formatted = DateFormat("dd-MM-yyyy hh:mm:ss a").format(istTime);

    return formatted;

  }
}
