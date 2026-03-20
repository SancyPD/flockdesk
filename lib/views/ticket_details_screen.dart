import 'dart:core';
import 'package:flockdesk/utils/attachment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart'
    show WebViewWidget, WebViewController, JavaScriptMode, JavaScriptMessage;
import '../utils/adjustable_webview.dart';
import '../models/ticket_status_response.dart';
import '../services/team_service.dart';
import '../models/team.dart';
import '../services/ticket_service.dart';
import '../models/ticket_details_response.dart';
import '../models/tags_response.dart';
import '../models/ticket_replies_response.dart';
import '../utils/shared_prefs.dart';
import '../models/agent_list_response.dart';
import 'package:file_picker/file_picker.dart';
import '../services/desk_service.dart';
import '../models/search_email_response.dart';
import '../utils/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/side_menu_widget.dart';

class TicketDetailsScreen extends StatefulWidget {
  final int ticketId;
  final bool fromTrash;
  final VoidCallback? onTicketTrashed; // Callback to refresh parent screen

  const TicketDetailsScreen({
    Key? key,
    required this.ticketId,
    required this.fromTrash,
    this.onTicketTrashed, // Optional callback
  }) : super(key: key);

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  bool _isSenderDetailsVisible = false;
  List<Team> _teams = [];
  Team? _selectedTeam;
  TicketDetailResult? _ticketDetails;
  bool _isLoadingTicketDetails = true;
  List<TicketStatus> _statuses = [];
  TicketStatus? _selectedStatus;
  List<TagDetails> _availableTags = [];
  List<TagDetails> _selectedTags = [];
  List<Agents> _agents = [];
  Agents? _selectedAgent;
  bool _isLoadingAgents = false;
  List<PlatformFile> _attachments = [];
  bool _isCcExpanded = false;
  List<String> _selectedCcEmails = [];
  bool _isCcSearchOpen = false;
  String _ccSearchQuery = '';
  List<SearchResult> _ccEmailResults = [];
  bool _isLoadingCcEmails = false;
  Timer? _ccSearchDebounce;
  bool _isMacrosOpen = false;
  bool _isCCMacrosVisible = false;
  List<Macro> _macros = [];
  bool _isLoadingMacros = false;
  final TextEditingController _replyController = TextEditingController();
  bool _showReplySection = false;
  bool _parentScrollEnabled = true;
  bool _isSendingReply = false;

  // Ticket replies state
  List<RepliesDatum> _replies = [];
  bool _isLoadingReplies = false;
  int _currentRepliesPage = 1;
  int _totalRepliesPages = 1;
  bool _hasUserScrolled = false; // Track if user has actively scrolled
  bool _isInitialScrolling = false; // Track if we're doing initial scroll

  // Scroll controller for auto-scrolling to bottom
  final ScrollController _scrollController = ScrollController();

  // GlobalKey for the last reply item
  final GlobalKey _lastReplyKey = GlobalKey();

  // Store scroll position before loading older messages
  double _scrollPositionBeforeLoad = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTicketAndTeams();
  }

  @override
  void dispose() {
    _ccSearchDebounce?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicketAndTeams() async {
    try {
      // Fetch ticket details first
      final ticketDetails = await TicketService().getTicketDetails(
        widget.ticketId,
      );
      // Then fetch teams
      final teams = await TeamService().listTeams(
        await SharedPrefs.getToken() ?? '',
      );
      // Fetch ticket statuses
      final statuses = await TicketService().getTicketStatuses();
      final tags = await TicketService().getActiveTags(); // Fetch active tags
      // Fetch agents for the assigned team
      List<Agents> agents = [];
      if (ticketDetails.assignedTeam != 0) {
        agents = await TeamService().getAgentsByTeam(
          ticketDetails.assignedTeam,
        );
      }

      setState(() {
        _ticketDetails = ticketDetails;
        _teams = teams;
        _statuses = statuses;
        _availableTags = tags;
        _agents = agents;
        _isLoadingTicketDetails = false;

        // Find and pre-select the assigned team
        if (_ticketDetails!.assignedTeam == 0) {
          _selectedTeam = null;
        } else {
          _selectedTeam = _teams.firstWhere(
            (team) => team.teamId == _ticketDetails!.assignedTeam,
            orElse: () => _teams.first, // Fallback to first team if not found
          );
        }

        // Find and pre-select the current ticket status using status_id from ticket details
        _selectedStatus = _statuses.firstWhere(
          (status) => status.statusId == _ticketDetails!.statusId,
          orElse: () =>
              _statuses.first, // Fallback to first status if not found
        );

        // Pre-select the assigned agent if available
        if (_agents.isNotEmpty) {
          _selectedAgent = _agents.firstWhere(
            (agent) => agent.id == _ticketDetails!.assignedUser,
            orElse: () => _agents.first,
          );
        } else {
          _selectedAgent = null;
        }

        // Initialize _selectedTags based on ticketDetails
        _selectedTags = _ticketDetails!.tags.map((ticketTag) {
          return _availableTags.firstWhere(
            (availableTag) => availableTag.tagId == ticketTag.tagId,
            orElse: () => ticketTag,
          );
        }).toList();
      });

      // Fetch ticket replies separately - only page 1 initially
      await _fetchTicketReplies();
    } catch (e) {
      print('Failed to load data: $e');
      setState(() {
        _isLoadingTicketDetails = false;
      });
    }
  }

  Future<void> _fetchTicketReplies({int page = 1}) async {
    print('_fetchTicketReplies called with page: $page');
    print(
      'Current state: _hasUserScrolled=$_hasUserScrolled, _isInitialScrolling=$_isInitialScrolling',
    );
    try {
      setState(() {
        _isLoadingReplies = true;
      });

      final repliesResponse = await TicketService().getTicketReplies(
        ticketId: widget.ticketId,
        page: page,
      );

      print(
        'API Response: currentPage=${repliesResponse.result.currentPage}, totalPages=${repliesResponse.result.totalPages}, repliesCount=${repliesResponse.result.repliesData.length}',
      );

      setState(() {
        if (page == 1) {
          // First page - replace all replies (latest messages)
          // API typically returns latest first, so reverse to show latest at bottom
          // This ensures latest replies appear at the bottom for proper scrolling
          _replies = repliesResponse.result.repliesData.reversed.toList();
        } else {
          // Subsequent pages - prepend older replies at the beginning
          // These should be in chronological order (oldest first) for proper display
          _replies.insertAll(
            0,
            repliesResponse.result.repliesData.reversed.toList(),
          );

          // For older pages, maintain scroll position to avoid disrupting user experience
          // The older replies are prepended at the top, so the user's current view remains stable
          // This mimics chat app behavior where older messages load above without moving the view
        }

        // Update pagination info from response
        _currentRepliesPage = repliesResponse.result.currentPage;
        _totalRepliesPages = repliesResponse.result.totalPages;
        _isLoadingReplies = false;

        // Debug: Print pagination state
        _printPaginationState();

        // Scroll to show first item of page 1 at bottom (only for first page)
        if (page == 1) {
          _scrollToShowFirstItem();
        } else {
          // For older pages, maintain scroll position to avoid disrupting user experience
          // The older replies are prepended at the top, so the user's current view remains stable
          // This mimics chat app behavior where older messages load above without moving the view
          _maintainScrollPosition(repliesResponse.result.repliesData.length);
        }
      });
    } catch (e) {
      print('Failed to load ticket replies: $e');
      setState(() {
        _isLoadingReplies = false;
      });
    }
  }

  Future<void> _loadMoreReplies() async {
    print('_loadMoreReplies called');
    print(
      'Conditions: currentPage=$_currentRepliesPage, totalPages=$_totalRepliesPages, isLoading=$_isLoadingReplies',
    );
    print(
      'User scroll state: _hasUserScrolled=$_hasUserScrolled, _isInitialScrolling=$_isInitialScrolling',
    );

    // Additional safeguard: only load more if user has explicitly scrolled and not during initial scroll
    if (!_hasUserScrolled || _isInitialScrolling) {
      print(
        'Blocked loading more replies: user has not scrolled or is initial scrolling',
      );
      return;
    }

    // Check if there are more pages and not currently loading
    if (_currentRepliesPage < _totalRepliesPages && !_isLoadingReplies) {
      print(
        'Loading older replies: current page $_currentRepliesPage, total pages $_totalRepliesPages',
      );

      // Store current scroll position before loading older messages
      if (_scrollController.hasClients) {
        _scrollPositionBeforeLoad = _scrollController.position.pixels;
        print('Stored scroll position before load: $_scrollPositionBeforeLoad');
      }

      await _fetchTicketReplies(page: _currentRepliesPage + 1);
    } else {
      print(
        'Cannot load more: current page $_currentRepliesPage, total pages $_totalRepliesPages, loading: $_isLoadingReplies',
      );
    }
  }

  void _printPaginationState() {
    print('Pagination State:');
    print('  Current Page: $_currentRepliesPage');
    print('  Total Pages: $_totalRepliesPages');
    print('  Replies Count: ${_replies.length}');
    print('  Is Loading: $_isLoadingReplies');
    print(
      '  Can Load More: ${_currentRepliesPage < _totalRepliesPages && !_isLoadingReplies}',
    );
  }

  void _resetPagination() {
    _currentRepliesPage = 1;
    _totalRepliesPages = 1;
    _replies.clear();
    _webViewHeights.clear(); // Clear WebView heights
    _hasUserScrolled = false; // Reset user scroll flag
    _isInitialScrolling = false; // Reset initial scrolling flag
    _scrollPositionBeforeLoad = 0.0; // Reset stored scroll position
    print('Pagination reset - will load latest messages first');
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            // Use the same logic as _scrollToShowFirstItem
            final maxExtent = _scrollController.position.maxScrollExtent;
            final viewportHeight = _scrollController.position.viewportDimension;

            if (maxExtent <= viewportHeight) {
              // Content fits in viewport, just scroll to top
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } else {
              // Try to find the last reply's position using GlobalKey
              final RenderBox? lastReplyBox =
                  _lastReplyKey.currentContext?.findRenderObject()
                      as RenderBox?;

              if (lastReplyBox != null) {
                // Get the position of the last reply
                final position = lastReplyBox.localToGlobal(Offset.zero);
                final scrollPosition = _scrollController.offset + position.dy;

                // Scroll to show the last reply at the bottom of viewport
                final targetPosition =
                    scrollPosition - viewportHeight + 100; // 100px buffer

                _scrollController.animateTo(
                  targetPosition.clamp(0.0, maxExtent),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              } else {
                // Fallback: use the old method
                final targetPosition =
                    maxExtent -
                    (viewportHeight * 0.3); // Show last 30% of content
                _scrollController.animateTo(
                  targetPosition.clamp(0.0, maxExtent),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              }
            }
          }
        });
      });
    }
  }

  void _scrollToShowFirstItem() {
    if (_scrollController.hasClients && _replies.isNotEmpty) {
      setState(() {
        _isInitialScrolling =
            true; // Prevent loading more replies during initial scroll
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            final maxExtent = _scrollController.position.maxScrollExtent;
            final viewportHeight = _scrollController.position.viewportDimension;

            print('Scroll Debug for Ticket 1187:');
            print('  Max Extent: $maxExtent');
            print('  Viewport Height: $viewportHeight');
            print('  Replies Count: ${_replies.length}');

            if (maxExtent <= viewportHeight) {
              // Content fits in viewport, just scroll to top
              _scrollController
                  .animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  )
                  .then((_) {
                    if (mounted) {
                      setState(() {
                        _isInitialScrolling = false;
                      });
                    }
                  });
            } else {
              // Try to find the last reply's position using GlobalKey
              final RenderBox? lastReplyBox =
                  _lastReplyKey.currentContext?.findRenderObject()
                      as RenderBox?;

              if (lastReplyBox != null) {
                // Get the position of the last reply
                final position = lastReplyBox.localToGlobal(Offset.zero);
                final scrollPosition = _scrollController.offset + position.dy;

                print('  Last reply position: $position');
                print('  Scroll position for last reply: $scrollPosition');

                // Scroll to show the last reply at the bottom of viewport
                final targetPosition =
                    scrollPosition - viewportHeight + 100; // 100px buffer

                _scrollController
                    .animateTo(
                      targetPosition.clamp(0.0, maxExtent),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    )
                    .then((_) {
                      if (mounted) {
                        setState(() {
                          _isInitialScrolling = false;
                        });
                      }
                    });
              } else {
                // Fallback: use the old method
                final targetPosition =
                    maxExtent -
                    (viewportHeight * 0.3); // Show last 30% of content

                print('  Fallback - Target Position: $targetPosition');

                _scrollController
                    .animateTo(
                      targetPosition.clamp(0.0, maxExtent),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    )
                    .then((_) {
                      if (mounted) {
                        setState(() {
                          _isInitialScrolling = false;
                        });
                      }
                    });
              }
            }
          }
        });
      });
    }
  }

  void _maintainScrollPosition(int newItemsCount) {
    if (_scrollController.hasClients && _scrollPositionBeforeLoad > 0) {
      print('Maintaining scroll position for $newItemsCount new items');
      print('Original position before load: $_scrollPositionBeforeLoad');

      // Store the current replies count before the new items were added
      final oldRepliesCount = _replies.length - newItemsCount;
      print(
        'Old replies count: $oldRepliesCount, New total: ${_replies.length}',
      );

      // Use a more accurate approach to maintain scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            // Calculate approximate height per item based on current scroll metrics
            final currentMaxExtent = _scrollController.position.maxScrollExtent;
            final approximateItemHeight = currentMaxExtent / _replies.length;

            // Calculate the height of newly added items
            final newContentHeight = newItemsCount * approximateItemHeight;

            print('Approximate item height: $approximateItemHeight');
            print('New content height: $newContentHeight');
            print('Current max extent: $currentMaxExtent');

            // The target position should be the old position plus the height of new content
            final targetPosition = _scrollPositionBeforeLoad + newContentHeight;

            print('Calculated target position: $targetPosition');

            // Jump to the calculated position to maintain user's view
            if (targetPosition <= currentMaxExtent) {
              _scrollController.jumpTo(targetPosition);
              print('Scroll position maintained at: $targetPosition');
            } else {
              _scrollController.jumpTo(currentMaxExtent);
              print('Scroll position set to max extent: $currentMaxExtent');
            }
          }
        });
      });
    }
  }

  void _loadOlderReplies() {
    if (_currentRepliesPage < _totalRepliesPages && !_isLoadingReplies) {
      print('Manually loading older replies');
      _hasUserScrolled = true; // Mark as user-initiated
      _loadMoreReplies();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTicketDetails) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ticketDetails == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load ticket details.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white, // background color (optional)
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1A000000),
                        // #0000000A = black with 10% opacity
                        offset: const Offset(0, 4),
                        // X: 0, Y: 4 → shadow only at bottom
                        blurRadius: 4,
                        // blur effect
                        spreadRadius: 0, // no spread
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Sender Info section
                      Container(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Image.asset(
                                'assets/images/back_arrow.png',
                                width: 7,
                                height: 14,
                                fit: BoxFit.fill,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                    '${_cleanTicketTitle(_ticketDetails!.ticketTitle)} - #${widget.ticketId}',
                                    style: const TextStyle(
                                      color: Color(0xFF313131),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                    maxLines: _isSenderDetailsVisible ? 10 : 1,
                                    overflow: _isSenderDetailsVisible
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    softWrap: true, // wrap to next line
                                  ),
                              ),
                            ),
                            widget.fromTrash
                                ? SizedBox()
                                : PopupMenuButton<String>(
                                    color: Colors.white,
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.black,
                                    ),
                                    onSelected: (String value) {
                                      if (value == 'delete') {
                                        _showTrashConfirmationDialog();
                                      } else if (value == 'update') {
                                        _showUpdateInfoDialog();
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/trash_ic.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'update',
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/edit_ic.png',
                                              width: 15,
                                              height: 15,
                                              color: Color(0xffA9A9A9),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Update Info'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      if (_isSenderDetailsVisible) ...[
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Email container
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFECECEC),
                                    ),
                                  ),
                                  child: Text(
                                    _ticketDetails!.contactDetails.emailId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color:const Color(0xFF454545) ,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // From and CC Emails
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Received At :',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _ticketDetails!.suggestedFromEmail,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFEFEFEF),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CC :',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _ticketDetails!.mustCcMails.isNotEmpty
                                        ? _ticketDetails!.mustCcMails.join(', ')
                                        : 'No CC',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // const SizedBox(height: 20),
                      // // Ticket Subject
                      // Text(
                      //   _cleanTicketTitle(_ticketDetails!.ticketTitle),
                      //   style: const TextStyle(
                      //     fontSize: 22,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.black87,
                      //     height: 1.3,
                      //   ),
                      // ),
                      const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSenderDetailsVisible = !_isSenderDetailsVisible;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        _isSenderDetailsVisible
                            ? 'assets/images/up_arrow_detail.png'
                            : 'assets/images/down_arrow_detail.png',
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, bottom: 10),
                  child: const Text(
                    'Replies',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A6A6A),
                    ),
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      // Debug scroll metrics
                      print(
                        'Scroll: pixels=${scrollInfo.metrics.pixels}, maxScrollExtent=${scrollInfo.metrics.maxScrollExtent}',
                      );

                      // Track if user has scrolled
                      if (scrollInfo.metrics.pixels > 0) {
                        _hasUserScrolled = true;
                      }

                      // Only load older pages when user actively scrolls to the very top
                      // Ignore scroll events during initial scrolling
                      if (scrollInfo.metrics.pixels <= 50 &&
                          _currentRepliesPage < _totalRepliesPages &&
                          !_isLoadingReplies &&
                          _replies.isNotEmpty &&
                          _hasUserScrolled &&
                          !_isInitialScrolling) {
                        // Only load if user has actively scrolled and not during initial scroll
                        print('User scrolled to top - loading older replies');
                        _loadMoreReplies();
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: _parentScrollEnabled
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Replies Section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Replies List
                                if (_replies.isEmpty)
                                  (_isLoadingReplies)
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32.0),
                                            child: Text(
                                              'No replies yet',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(bottom: 0),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount:
                                        _replies.length +
                                        (_isLoadingReplies ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == 0 && _isLoadingReplies) {
                                        // Loader at the top while fetching older messages
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: SpinKitThreeBounce(
                                              color: const Color(0xFF828282),
                                              size: 16.0,
                                            ),
                                          ),
                                        );
                                      }

                                      // Show replies in chronological order (oldest to newest)
                                      // The data structure in _replies:
                                      // - First page (latest) is reversed from API to show latest at bottom
                                      // - Older pages are also reversed and prepended at top
                                      // Result: chronological order with latest message at bottom, auto-scroll to show latest first
                                      final replyIndex = _isLoadingReplies
                                          ? index - 1
                                          : index;
                                      if (replyIndex < 0)
                                        return const SizedBox.shrink();

                                      final reply = _replies[replyIndex];
                                      final cleanedHtml = reply.messageHtml
                                          .replaceAll(
                                            RegExp(
                                              r'display\s*:\s*none[^;"]*;?',
                                            ),
                                            '',
                                          )
                                          .replaceAll(
                                            RegExp(r'\s+'),
                                            ' ',
                                          ) // collapse multiple spaces/newlines
                                          .replaceAll(
                                            "&nbsp;",
                                            " ",
                                          ) // replace non-breaking spaces
                                          .trim();

                                      // Check if this is the last reply to add GlobalKey
                                      final isLastReply =
                                          replyIndex == _replies.length - 1;

                                      return Padding(
                                        key: isLastReply ? _lastReplyKey : null,
                                        padding: const EdgeInsets.only(
                                          bottom: 24.0,
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                CircleAvatar(
                                                  radius: 15,
                                                  backgroundColor: Color(
                                                    0xFFBED6F5,
                                                  ),
                                                  child: Text(
                                                    reply
                                                            .messageSentBy
                                                            .isNotEmpty
                                                        ? reply.messageSentBy[0]
                                                              .toUpperCase()
                                                        : '',
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              reply
                                                                  .messageSentBy,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    reply.sentBy ==
                                                                        "1"
                                                                    ? const Color(
                                                                        0xFF313131,
                                                                      )
                                                                    : const Color(
                                                                        0xFF454545,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 10),
                                                          Text(
                                                            _formatReplyTime(
                                                              reply.updatedAt,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          // Tick indicators based on sentBy and sentStatus
                                                          if (reply.sentBy ==
                                                              "1") ...[
                                                            if (reply
                                                                    .sentStatus ==
                                                                "1") ...[
                                                              // Single tick for sentStatus == 1 (message sent)
                                                              Icon(
                                                                Icons.done,
                                                                size: 14,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ] else if (reply
                                                                    .sentStatus ==
                                                                "2") ...[
                                                              // Two ticks for sentStatus == 2 (WhatsApp style)
                                                              Stack(
                                                                children: [
                                                                  Icon(
                                                                    Icons.done,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                  Positioned(
                                                                    left: 2,
                                                                    child: Icon(
                                                                      Icons
                                                                          .done,
                                                                      size: 14,
                                                                      color: Colors
                                                                          .grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ] else if (reply
                                                                    .sentStatus ==
                                                                "3") ...[
                                                              // Blue tick for sentStatus == 3 (WhatsApp style - double blue ticks)
                                                              Stack(
                                                                children: [
                                                                  Icon(
                                                                    Icons.done,
                                                                    size: 14,
                                                                    color: const Color(
                                                                      0xFF34B7F1,
                                                                    ), // WhatsApp blue color
                                                                  ),
                                                                  Positioned(
                                                                    left: 2,
                                                                    child: Icon(
                                                                      Icons
                                                                          .done,
                                                                      size: 14,
                                                                      color: const Color(
                                                                        0xFF34B7F1,
                                                                      ), // WhatsApp blue color
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ],
                                                        ],
                                                      ),
                                                      _isComplexHtml(
                                                            reply.messageHtml,
                                                          )
                                                          ? _buildHtmlWidget(
                                                              reply.messageHtml,
                                                              replyIndex,
                                                            )
                                                          :
                                                            // Message
                                                            Container(
                                                              width: double
                                                                  .infinity,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                  ),
                                                              child: HtmlWidget(
                                                                cleanedHtml,
                                                                customWidgetBuilder: (element) {
                                                                  if (element
                                                                          .localName ==
                                                                      'img') {
                                                                    final src =
                                                                        element
                                                                            .attributes['src'];
                                                                    final style =
                                                                        element
                                                                            .attributes['style'] ??
                                                                        '';

                                                                    // Skip tracking pixels
                                                                    if (style.contains(
                                                                          'display:none',
                                                                        ) ||
                                                                        element.attributes['width'] ==
                                                                            '1') {
                                                                      return null;
                                                                    }

                                                                    return _buildImageWidget(src ?? '');
                                                                  }
                                                                  return null;
                                                                },
                                                              ),
                                                            ),

                                                      GridView.builder(
                                                        shrinkWrap: true,
                                                        // so it fits inside another scrollable
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        // disable inner scroll
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              // number of items per row
                                                              crossAxisSpacing:
                                                                  8,
                                                              mainAxisSpacing:
                                                                  8,
                                                              childAspectRatio:
                                                                  3.5, // controls height vs width
                                                            ),
                                                        itemCount: reply
                                                            .attachments
                                                            .length,
                                                        itemBuilder: (context, index) {
                                                          final attachment = reply
                                                              .attachments[index];
                                                          return InkWell(
                                                            onTap: () {
                                                              _downloadFile(
                                                                attachment
                                                                    .fullPath,
                                                              );
                                                            },
                                                            child: AttachmentTile(
                                                              fileName: attachment
                                                                  .attachmentName,
                                                              fileUrl:
                                                                  attachment
                                                                      .fullPath,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      SizedBox(height: 10),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Show divider for all replies except the latest one (last item)
                                            if (replyIndex <
                                                _replies.length - 1)
                                              Container(
                                                color: const Color(0xFFF2F2F2),
                                                height: 1,
                                                width: double.infinity,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                //Reply section
                Visibility(
                  visible: _showReplySection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/type_reply_bg.png"),
                        // your image path
                        fit: BoxFit.fill, // cover the entire container
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CC Emails Section (inside reply box) - Visible when CC is expanded
                        if (_isCcExpanded && _isCCMacrosVisible) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEFEFEF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Show existing CC emails if any, otherwise show placeholder
                                if (_ticketDetails!.mustCcMails.isNotEmpty) ...[
                                  Text(
                                    _ticketDetails!.mustCcMails.join(', '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ] else ...[
                                  Text(
                                    'No CC emails added yet',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Add icon to add new CC emails
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCcSearchOpen = !_isCcSearchOpen;
                                      if (_isCcSearchOpen) {
                                        _searchCcEmails(query: _ccSearchQuery);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // CC Search Section
                        if (_isCcSearchOpen && _isCCMacrosVisible) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                              // border: Border.all(color: const Color(0xFFEFEFEF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        textAlign: TextAlign.start,
                                        decoration: const InputDecoration(
                                          hintText: 'Search email...',
                                          prefixIcon: Icon(
                                            Icons.search,
                                            size: 20,
                                          ),
                                          // smaller icon if needed
                                          prefixIconConstraints: BoxConstraints(
                                            // 👈 control icon box size
                                            minWidth: 40,
                                            minHeight: 20,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        onChanged: _onCcSearchChanged,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCcSearchOpen = !_isCcSearchOpen;
                                        });
                                      },
                                      child: Image.asset(
                                        'assets/images/clear_ic.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isLoadingCcEmails)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (_ccEmailResults.isNotEmpty)
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 150,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _ccEmailResults.length,
                                      itemBuilder: (context, index) {
                                        final emailResult =
                                            _ccEmailResults[index];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            emailResult.emailId,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          subtitle: Text(
                                            emailResult.contactName,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              if (!_selectedCcEmails.contains(
                                                emailResult.emailId,
                                              )) {
                                                _selectedCcEmails.add(
                                                  emailResult.emailId,
                                                );
                                              }
                                              _isCcSearchOpen = false;
                                              _ccSearchQuery = '';
                                              _ccEmailResults = [];
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Selected CC Emails
                        if (_selectedCcEmails.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _selectedCcEmails
                                .map(
                                  (email) => Chip(
                                    label: Text(
                                      email,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    deleteIcon: Image.asset(
                                      'assets/images/clear_ic.png',
                                      width: 12,
                                      height: 12,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedCcEmails.remove(email);
                                      });
                                    },
                                    backgroundColor: Colors.blue[100],
                                    labelStyle: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isCCMacrosVisible)
                                    Row(
                                      children: [
                                        // CC Button
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isCcExpanded = !_isCcExpanded;
                                              if (_isCcExpanded) {
                                                _searchCcEmails(
                                                  query: _ccSearchQuery,
                                                );
                                              }
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFEFEFEF),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            'CC${_ticketDetails!.mustCcMails.isNotEmpty ? ' (${_ticketDetails!.mustCcMails.length})' : ''}',
                                            style: const TextStyle(
                                              color: Color(0xFF3F3F3F),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Macros Button
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isMacrosOpen = !_isMacrosOpen;
                                              if (_isMacrosOpen &&
                                                  _macros.isEmpty) {
                                                _loadMacros();
                                              }
                                            });
                                          },
                                          icon: Image.asset(
                                            'assets/images/macros_ic.png',
                                            width: 12,
                                            height: 12,
                                          ),
                                          label: const Text(
                                            'Macros',
                                            style: TextStyle(
                                              color: Color(0xFF828282),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Color(0xFFEFEFEF),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Attachment Icon
                                        Container(
                                          child: IconButton(
                                            icon: Image.asset(
                                              'assets/images/attach_ic.png',
                                              width: 18,
                                              height: 24,
                                            ),
                                            onPressed: _pickAttachments,
                                            splashRadius: 20,
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  // Reply Text Field and Send Button on same line
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isCCMacrosVisible =
                                                !_isCCMacrosVisible;
                                          });
                                        },
                                        child: Padding(
                                          padding: _isCCMacrosVisible
                                              ? const EdgeInsets.only(top: 14.0)
                                              : const EdgeInsets.only(
                                                  top: 12.0,
                                                ),
                                          child: _isCCMacrosVisible
                                              ? Image.asset(
                                                  'assets/images/minus_square.png',
                                                  height: 20,
                                                  width: 20,
                                                  fit: BoxFit.contain,
                                                )
                                              : Image.asset(
                                                  'assets/images/add_square.png',
                                                  height: 23,
                                                  width: 23,
                                                  fit: BoxFit.contain,
                                                ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            top: 12,
                                            bottom: 12,
                                          ),
                                          child: TextField(
                                            textAlign: TextAlign.start,
                                            controller: _replyController,
                                            minLines: 1,
                                            maxLines: 5,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Type your reply here...',
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 0,
                                                  ),
                                              hintStyle: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF828282),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _isSendingReply
                                            ? null
                                            : _sendReply,
                                        icon: _isSendingReply
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.grey),
                                                ),
                                              )
                                            : Image.asset(
                                                'assets/images/send.png',
                                                width: 46,
                                                height: 46,
                                              ),
                                        splashRadius: 25,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Attached Files
                        if (_attachments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _attachments
                                .map(
                                  (file) => Chip(
                                    label: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    deleteIcon: Image.asset(
                                      'assets/images/clear_ic.png',
                                      width: 12,
                                      height: 12,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _attachments.remove(file);
                                      });
                                    },
                                    backgroundColor: Colors.green[100],
                                    labelStyle: const TextStyle(
                                      color: Colors.green,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Macros Dropdown
                if (_isMacrosOpen && _isCCMacrosVisible) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEFEFEF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoadingMacros)
                          const Center(child: CircularProgressIndicator())
                        else if (_macros.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _macros.length,
                              itemBuilder: (context, index) {
                                final macro = _macros[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    macro.macroTitle,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    _selectMacro(macro);
                                    setState(() {
                                      _isMacrosOpen = false;
                                    });
                                  },
                                );
                              },
                            ),
                          )
                        else
                          const Text(
                            'No macros available',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_showReplySection)
            Positioned(
              right: 16,
              bottom: 25,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showReplySection = true;
                    _isCCMacrosVisible = false;
                  });
                },
                child: Image.asset(
                  'assets/images/send_reply.png',
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      // Handle hex color
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } else if (colorString.startsWith('rgb(') && colorString.endsWith(')')) {
      // Handle RGB color
      final rgbValues = colorString
          .substring(4, colorString.length - 1)
          .split(' ') // Split by space instead of comma
          .map((s) => int.parse(s.trim()))
          .toList();
      if (rgbValues.length == 3) {
        return Color.fromRGBO(rgbValues[0], rgbValues[1], rgbValues[2], 1.0);
      }
    }
    // Default to a transparent color or throw an error if the format is unknown
    return Colors.transparent;
  }

  bool _isComplexHtml(String html) {
    // Heuristic: if it contains complex HTML structures → use WebView for better rendering
    return html.contains("<table") ||
        html.contains("background:") ||
        html.contains("<style") ||
        html.contains("class=") ||
        html.contains("<img") ||
        html.contains("MsoNormal") ||
        html.contains("WordSection") ||
        html.length > 500; // Use WebView for longer content
  }

  // Map to store WebView heights for different replies
  final Map<int, double> _webViewHeights = {};

  // Custom HTML widget that displays content using AdjustableWebView for complex HTML
  Widget _buildHtmlWidget(String html, int replyIndex) {
    print("HTML Widget using AdjustableWebView");
    
    // Pre-process HTML to group consecutive images together and add responsive styling
    final processedHtml = _preprocessHtmlForWebView(html);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: AdjustableWebView(html: processedHtml),
    );
  }

  // Pre-process HTML specifically for WebView rendering with better image grouping
  String _preprocessHtmlForWebView(String html) {
    String processedHtml = html;
    
    // Pattern to match consecutive <img> tags (with optional whitespace between them)
    final consecutiveImgPattern = RegExp(r'(<img[^>]*>)(\s*<img[^>]*>)+', multiLine: true);
    
    // Replace consecutive images with a flex container
    processedHtml = processedHtml.replaceAllMapped(consecutiveImgPattern, (match) {
      final allMatches = RegExp(r'<img[^>]*>').allMatches(match.group(0)!).toList();
      final imgTags = allMatches.map((m) => m.group(0)!).join('');
      
      return '''
        <div style="display: flex; flex-wrap: wrap; align-items: center; gap: 4px; margin: 4px 0;">
          $imgTags
        </div>
      ''';
    });
    
    // Add comprehensive CSS styling optimized for WebView
    final cssStyle = '''
      <style>
        /* Reset and base styles */
        * {
          box-sizing: border-box;
        }
        
        body {
          margin: 0;
          padding: 8px;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          font-size: 14px;
          line-height: 1.4;
          color: #333;
          word-wrap: break-word;
          overflow-x: auto;
        }
        
        /* Style for images inside flex containers (grouped images) */
        div[style*="display: flex"] img {
          display: inline-block !important;
          vertical-align: middle !important;
          margin: 0 !important;
          max-width: 80px !important;
          max-height: 50px !important;
          height: auto !important;
          width: auto !important;
          object-fit: contain !important;
          border-radius: 4px;
        }
        
        /* Style for standalone images */
        img:not(div[style*="display: flex"] img) {
          display: block !important;
          margin: 8px auto !important;
          max-width: 100% !important;
          max-height: 300px !important;
          height: auto !important;
          width: auto !important;
          object-fit: contain !important;
          border-radius: 4px;
        }
        
        /* Ensure proper text wrapping */
        p, div, span {
          white-space: normal !important;
          word-wrap: break-word !important;
        }
        
        /* Table styling */
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 8px 0;
        }
        
        table img {
          max-width: 100% !important;
          height: auto !important;
        }
        
        /* Remove any conflicting styles from existing HTML */
        .MsoNormal {
          margin: 0 !important;
        }
        
        /* Responsive design */
        @media (max-width: 400px) {
          div[style*="display: flex"] img {
            max-width: 60px !important;
            max-height: 40px !important;
          }
        }
      </style>
    ''';
    
    return cssStyle + processedHtml;
  }

  // Legacy method for HtmlWidget (kept for fallback)
  String _preprocessHtmlForImageGrouping(String html) {
    // Enhanced approach: detect consecutive images and wrap them in flex containers
    String processedHtml = html;
    
    // Pattern to match consecutive <img> tags (with optional whitespace between them)
    final consecutiveImgPattern = RegExp(r'(<img[^>]*>)(\s*<img[^>]*>)+', multiLine: true);
    
    // Replace consecutive images with a flex container
    processedHtml = processedHtml.replaceAllMapped(consecutiveImgPattern, (match) {
      final allMatches = RegExp(r'<img[^>]*>').allMatches(match.group(0)!).toList();
      final imgTags = allMatches.map((m) => m.group(0)!).join('');
      
      return '''
        <div style="display: flex; flex-wrap: wrap; align-items: center; gap: 4px; margin: 4px 0;">
          $imgTags
        </div>
      ''';
    });
    
    // Add comprehensive CSS styling
    final cssStyle = '''
      <style>
        /* Style for images inside flex containers (grouped images) */
        div[style*="display: flex"] img {
          display: inline-block !important;
          vertical-align: middle !important;
          margin: 0 !important;
          max-width: 80px !important;
          max-height: 50px !important;
          height: auto !important;
          width: auto !important;
          object-fit: contain !important;
        }
        
        /* Style for standalone images */
        img:not(div[style*="display: flex"] img) {
          display: block !important;
          margin: 8px auto !important;
          max-width: 100% !important;
          max-height: 300px !important;
          height: auto !important;
          width: auto !important;
          object-fit: contain !important;
        }
        
        /* Ensure proper text wrapping */
        p, div, span {
          white-space: normal !important;
          word-wrap: break-word !important;
        }
        
        /* Allow horizontal scrolling for wide content */
        body {
          overflow-x: auto !important;
          word-wrap: break-word !important;
        }
        
        /* Remove any conflicting styles */
        table img {
          max-width: none !important;
          max-height: none !important;
        }
      </style>
    ''';
    
    return cssStyle + processedHtml;
  }

  // Fallback method to estimate content height based on HTML content
  double _estimateContentHeight(String html) {
    // Simple heuristic: count lines and estimate height
    final lines = html.split('\n').length;
    final words = html.split(' ').length;

    // Rough estimation: 20px per line, minimum 100px, maximum 600px
    final estimatedHeight = (lines * 20 + words * 2).clamp(100.0, 600.0);
    return estimatedHeight.toDouble();
  }

  // Unified image widget builder with proper error handling and authentication
  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'No image URL provided',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Validate URL format
    if (!_isValidUrl(imageUrl)) {
      print('Invalid image URL: $imageUrl');
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Invalid image URL',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Convert relative URLs to absolute URLs if needed
    final fullImageUrl = _getFullImageUrl(imageUrl);
    print('Loading image: $fullImageUrl');

    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final maxImageHeight = screenWidth < 400 ? 50.0 : 60.0; // Smaller height for inline images

    // Handle data URLs differently (no network request needed)
    if (imageUrl.startsWith('data:')) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: maxImageHeight, // Responsive height for mobile screens
          maxWidth: 80, // Smaller width for inline images
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
            _decodeBase64Image(imageUrl),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              print('Data URL image loading error: $error');
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Invalid image data',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      );
    }

    // Handle network URLs with authentication
    return FutureBuilder<Map<String, String>>(
      future: _getImageHeaders(),
      builder: (context, snapshot) {
        final headers = snapshot.data ?? <String, String>{};
        
        return Container(
          constraints: BoxConstraints(
            maxHeight: maxImageHeight, // Responsive height for mobile screens
            maxWidth: 80, // Smaller width for inline images
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
              fullImageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              headers: headers,
              errorBuilder: (context, error, stackTrace) {
                print('Image loading error for URL: $fullImageUrl');
                print('Error: $error');
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Image failed to load',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'URL: ${imageUrl.length > 50 ? '${imageUrl.substring(0, 50)}...' : imageUrl}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 8),
                        Text(
                          'Loading image...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        );
      },
    );
  }

  // Validate if the URL is properly formatted
  bool _isValidUrl(String url) {
    try {
      // Handle data URLs (base64 encoded images)
      if (url.startsWith('data:')) {
        return _isValidDataUrl(url);
      }
      
      // Handle HTTP/HTTPS URLs
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Validate data URLs (base64 encoded images)
  bool _isValidDataUrl(String dataUrl) {
    try {
      // Check if it's a valid data URL format: data:[<mediatype>][;base64],<data>
      if (!dataUrl.startsWith('data:')) return false;
      
      final parts = dataUrl.split(',');
      if (parts.length != 2) return false;
      
      final header = parts[0];
      final data = parts[1];
      
      // Check if it's base64 encoded
      if (!header.contains('base64')) return false;
      
      // Check if data is not empty
      if (data.isEmpty) return false;
      
      // Basic base64 validation (should only contain valid base64 characters)
      final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      return base64Regex.hasMatch(data);
    } catch (e) {
      return false;
    }
  }

  // Convert relative URLs to absolute URLs
  String _getFullImageUrl(String imageUrl) {
    // If it's a data URL, return as is (no conversion needed)
    if (imageUrl.startsWith('data:')) {
      return imageUrl;
    }
    
    // If it's already an absolute URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it's a relative URL, prepend the base URL
    if (imageUrl.startsWith('/')) {
      return 'https://helpdesk.mindlabs.systems$imageUrl';
    }

    // If it's a relative path without leading slash, add the storage path
    return 'https://helpdesk.mindlabs.systems/desk/storage/app/public/$imageUrl';
  }

  // Decode base64 data URL to bytes
  Uint8List _decodeBase64Image(String dataUrl) {
    try {
      // Extract the base64 data part after the comma
      final base64Data = dataUrl.split(',')[1];
      return base64Decode(base64Data);
    } catch (e) {
      print('Error decoding base64 image: $e');
      // Return a minimal 1x1 transparent PNG as fallback
      return base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    }
  }

  // Get headers for authenticated image requests
  Future<Map<String, String>> _getImageHeaders() async {
    final headers = <String, String>{
      'User-Agent': 'FlockDesk-Mobile/1.0',
    };

    // Add authentication token if available and if the image URL requires it
    // Note: Data URLs don't need authentication headers
    try {
      final token = await SharedPrefs.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting token for image headers: $e');
    }

    return headers;
  }

  /*  String _formatReplyTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hour ago";
    } else {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    }
  }*/

  String _formatReplyTime(DateTime dateTime) {
    // Parse input as UTC
    DateTime utcTime = DateFormat(
      "yyyy-MM-dd HH:mm:ss",
    ).parseUtc(dateTime.toString());

    // Convert to IST
    DateTime istTime = utcTime.add(const Duration(hours: 5, minutes: 30));

    // Format to desired output
    String formatted = DateFormat("dd-MM-yyyy, h:mm:ss a").format(istTime);

    return formatted;
    // Format to dd-MM-yyyy hh:mm:ss a (12-hour format)
    // final formatter = DateFormat("dd-MM-yyyy hh:mm:ss a");
    // return formatter.format(dateTime);
  }

  Future<void> _pickAttachments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result != null) {
      List<PlatformFile> validFiles = result.files
          .where((file) => file.size <= 20 * 1024 * 1024)
          .toList();
      if (validFiles.length < result.files.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Some files were larger than 20MB and were not added.',
            ),
          ),
        );
      }
      setState(() {
        _attachments.addAll(validFiles);
      });
    }
  }

  Future<void> _searchCcEmails({String query = ''}) async {
    setState(() {
      _isLoadingCcEmails = true;
    });
    try {
      final results = await DeskService().searchEmails(key: query);
      setState(() {
        _ccEmailResults = results.result;
        _isLoadingCcEmails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCcEmails = false;
      });
    }
  }

  void _onCcSearchChanged(String value) {
    setState(() {
      _ccSearchQuery = value;
    });
    if (_ccSearchDebounce?.isActive ?? false) _ccSearchDebounce!.cancel();
    _ccSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchCcEmails(query: value);
    });
  }

  Future<void> _loadMacros() async {
    setState(() {
      _isLoadingMacros = true;
    });
    try {
      final token = await SharedPrefs.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getActivemacros')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final macrosList = data['result'] as List;
        setState(() {
          _macros = macrosList.map((macro) => Macro.fromJson(macro)).toList();
          _isLoadingMacros = false;
        });
      } else {
        setState(() {
          _isLoadingMacros = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMacros = false;
      });
    }
  }

  void _selectMacro(Macro macro) {
    // Convert HTML content to plain text for the text field
    _replyController.text = _htmlToPlainText(macro.macroBody);
  }

  String _htmlToPlainText(String html) {
    if (html.isEmpty) return '';

    String text = html;

    // Handle specific HTML structures before removing tags
    // Convert <br> and <br/> to newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Convert <p> tags to newlines (paragraph breaks)
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');

    // Convert <div> tags to newlines
    text = text.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');

    // Convert <li> tags to bullet points
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    // Convert <ul> and <ol> tags
    text = text.replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<ul[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<ol[^>]*>', caseSensitive: false), '');

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    // Clean up multiple consecutive newlines and spaces
    text = text.replaceAll(
      RegExp(r'\n\s*\n\s*\n'),
      '\n\n',
    ); // Max 2 consecutive newlines
    text = text.replaceAll(
      RegExp(r'[ \t]+'),
      ' ',
    ); // Multiple spaces/tabs to single space
    text = text.replaceAll(
      RegExp(r'\n '),
      '\n',
    ); // Remove spaces after newlines
    text = text.replaceAll(
      RegExp(r' \n'),
      '\n',
    ); // Remove spaces before newlines

    text = text.trim();

    return text;
  }

  String _getUniqueCcEmails() {
    // Combine mustCcMails and selectedCcEmails, remove duplicates
    Set<String> uniqueEmails = Set<String>.from(_ticketDetails!.mustCcMails);
    uniqueEmails.addAll(_selectedCcEmails);
    return uniqueEmails.join(',');
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply message')),
      );
      return;
    }

    // Prevent multiple submissions
    if (_isSendingReply) return;

    setState(() {
      _isSendingReply = true;
    });

    try {
      final token = await SharedPrefs.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        setState(() {
          _isSendingReply = false;
        });
        return;
      }

      final replyText = _replyController.text;
      final currentTime = DateTime.now();
      final currentUser = await SharedPrefs.getUserName() ?? 'You';

      // Prepare attachments array
      List<Map<String, dynamic>> attachments = [];
      for (var file in _attachments) {
        attachments.add({
          'name': file.name,
          'bytes': file.bytes,
          'size': file.size,
        });
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'ticket_id': widget.ticketId,
        'to_email': _ticketDetails!.contactDetails.emailId,
        'cc_mails': _getUniqueCcEmails(),
        'mail_content': replyText,
        'from_email': _ticketDetails!.suggestedFromEmail,
        'has_attachments': _attachments.isNotEmpty ? 1 : 0,
        'attachments[]': attachments,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/sendReply')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'Reply sent successfully') {
          // Immediately add the new reply to the local state
          if (_ticketDetails != null) {
            final newReply = Reply(
              replyId: DateTime.now().millisecondsSinceEpoch,
              // Temporary ID
              messageId: '',
              referenceId: '',
              ticketId: widget.ticketId,
              sentBy: currentUser,
              senderId: 0,
              messageText: replyText,
              textContent: replyText,
              messageHtml: replyText,
              sendFrom: _ticketDetails!.suggestedFromEmail,
              sendTo: _ticketDetails!.contactDetails.emailId,
              createdAt: currentTime,
              updatedAt: currentTime,
              ccMails: _getUniqueCcEmails(),
              sentStatus: 'sent',
              messageSentBy: currentUser,
              attachments: [], // Empty attachments for now
            );

            setState(() {
              // _ticketDetails!.replies.add(newReply);
            });
          }

          // Clear the reply field and attachments
          setState(() {
            _replyController.clear();
            _attachments.clear();
            _selectedCcEmails.clear();
          });

          // Hide the keyboard
          FocusScope.of(context).unfocus();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply sent successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset pagination and refresh replies to show the new reply
          _resetPagination();
          await _fetchTicketReplies();

          // Scroll to show the new reply
          _scrollToShowFirstItem();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['result'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reply. Status: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReply = false;
        });
      }
    }
  }

  void _showTrashConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Move to Trash'),
              content: const Text('Do you want to move this ticket to Trash?'),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final success = await TicketService().trashTicket(
                              ticketId: widget.ticketId,
                            );
                            if (success) {
                              if (mounted) {
                                // Refresh trash count in side menu
                                SideMenuWidget.refreshTrashCount();

                                // Call the callback to refresh parent screen
                                widget.onTicketTrashed?.call();

                                // Close the dialog first
                                Navigator.of(context).pop();

                                // Then pop back to previous screen
                                Navigator.of(context).pop();

                                // Show success message on the parent screen
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ticket moved to trash successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                });
                              }
                            } else {
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to move ticket to trash',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Yes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdateInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 40,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _UpdateTicketOverlay(
                teams: _teams,
                statuses: _statuses,
                agents: _agents,
                availableTags: _availableTags,
                initialTeam: _selectedTeam,
                initialStatus: _selectedStatus,
                initialAgent: _selectedAgent,
                initialTags: _selectedTags,
                ticketId: widget.ticketId,
                onUpdateSuccess: () {
                  _fetchTicketAndTeams();
                },
              ),
            ),
          ),
        );
      },
    );
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

  String _sanitizeHtmlContent(String htmlContent) {
    if (htmlContent.isEmpty) return '';

    // Basic HTML sanitization to prevent rendering issues
    String sanitized = htmlContent;

    // Remove potentially dangerous tags
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<iframe[^>]*>.*?</iframe>', dotAll: true),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<object[^>]*>.*?</object>', dotAll: true),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'<embed[^>]*>.*?</embed>', dotAll: true),
      '',
    );

    // Clean up excessive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Ensure proper HTML structure
    if (!sanitized.startsWith('<')) {
      // If content doesn't start with HTML tags, wrap it in a paragraph
      sanitized = '<p>$sanitized</p>';
    }

    return sanitized.trim();
  }

  Future<void> _downloadFile(fileUrl) async {
    final Uri url = Uri.parse(fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class _TagDropdown extends StatefulWidget {
  final List<TagDetails> selectedTags;
  final List<TagDetails> availableTags;
  final ValueChanged<TagDetails> onTagSelected;
  final ValueChanged<TagDetails> onTagRemoved;

  const _TagDropdown({
    required this.selectedTags,
    required this.availableTags,
    required this.onTagSelected,
    required this.onTagRemoved,
  });

  @override
  State<_TagDropdown> createState() => _TagDropdownState();
}

class _TagDropdownState extends State<_TagDropdown> {
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    setState(() {
      _isDropdownOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.availableTags
                    .map(
                      (tag) => ListTile(
                        title: Text(tag.tagName),
                        onTap: () {
                          widget.onTagSelected(tag);
                          _removeDropdown();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: double.infinity,
          // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          // decoration: BoxDecoration(
          //   color: const Color(0xFFF5F5F5),
          //   borderRadius: BorderRadius.circular(12),
          //   border: Border.all(color: Colors.grey.shade300),
          // ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...widget.selectedTags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InputChip(
                            label: Text(
                              tag.tagName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            deleteIcon: Image.asset(
                              'assets/images/clear_ic.png',
                              width: 12,
                              height: 12,
                            ),
                            onDeleted: () {
                              widget.onTagRemoved(tag);
                            },
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Update...',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }
}

class Macro {
  final int macroId;
  final String macroTitle;
  final String macroBody;

  Macro({
    required this.macroId,
    required this.macroTitle,
    required this.macroBody,
  });

  factory Macro.fromJson(Map<String, dynamic> json) => Macro(
    macroId: json['macro_id'] ?? 0,
    macroTitle: json['macro_title'] ?? '',
    macroBody: json['macro_body'] ?? '',
  );
}

class _UpdateTicketOverlay extends StatefulWidget {
  final List<Team>? teams;
  final List<TicketStatus>? statuses;
  final List<Agents>? agents;
  final List<TagDetails>? availableTags;
  final Team? initialTeam;
  final TicketStatus? initialStatus;
  final Agents? initialAgent;
  final List<TagDetails>? initialTags;
  final int ticketId;
  final VoidCallback? onUpdateSuccess;

  const _UpdateTicketOverlay({
    this.teams,
    this.statuses,
    this.agents,
    this.availableTags,
    this.initialTeam,
    this.initialStatus,
    this.initialAgent,
    this.initialTags,
    required this.ticketId,
    this.onUpdateSuccess,
  });

  @override
  State<_UpdateTicketOverlay> createState() => _UpdateTicketOverlayState();
}

class _UpdateTicketOverlayState extends State<_UpdateTicketOverlay> {
  Team? _selectedTeam;
  TicketStatus? _selectedStatus;
  Agents? _selectedAgent;
  List<TagDetails> _selectedTags = [];
  List<Team> _teamList = [];
  List<TicketStatus> _statusList = [];
  List<Agents> _agentList = [];
  List<TagDetails> _availableTags = [];
  bool _isLoadingTeams = true;
  bool _isLoadingStatuses = true;
  bool _isLoadingAgents = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    setState(() {
      _teamList = widget.teams ?? [];
      _statusList = widget.statuses ?? [];
      _agentList = widget.agents ?? [];
      _availableTags = widget.availableTags ?? [];
      _selectedTeam = widget.initialTeam;
      _selectedStatus = widget.initialStatus;
      _selectedAgent = widget.initialAgent;
      _selectedTags = List.from(widget.initialTags ?? []);
      _isLoadingTeams = false;
      _isLoadingStatuses = false;
    });
  }

  Future<void> _fetchAgents(int teamId) async {
    setState(() {
      _isLoadingAgents = true;
    });
    try {
      final agents = await TeamService().getAgentsByTeam(teamId);
      setState(() {
        _agentList = agents;
        _selectedAgent = null;
        _isLoadingAgents = false;
      });
    } catch (e) {
      setState(() {
        _agentList = [];
        _isLoadingAgents = false;
      });
    }
  }

  Future<void> _updateTicket() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final ticketId = widget.ticketId;
      final userId = _selectedAgent?.id ?? 0;
      final teamId = _selectedTeam?.teamId ?? 0;
      final statusId = _selectedStatus?.statusId ?? 0;
      final tagIds = _selectedTags.map((tag) => tag.tagId).toList();

      final success = await TicketService().updateTicket(
        ticketId: ticketId,
        userId: userId,
        teamId: teamId,
        statusId: statusId,
      );

      if (success) {
        final tagsSuccess = await TicketService().updateTicketTags(
          ticketId: ticketId,
          tagIds: tagIds,
        );

        if (tagsSuccess) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onUpdateSuccess?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket info updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onUpdateSuccess?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ticket updated, but failed to update tags'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update ticket'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Update Ticket Info',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Image.asset(
                'assets/images/close_1.png',
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Team', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Team>(
              value: _selectedTeam,
              isExpanded: true,
              hint: const Text('Select a team'),
              items: _teamList
                  .map(
                    (team) => DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.teamTitle),
                    ),
                  )
                  .toList(),
              onChanged: (Team? value) async {
                setState(() {
                  _selectedTeam = value;
                  _selectedAgent = null;
                });
                if (value != null && value.teamId != 0) {
                  await _fetchAgents(value.teamId);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TicketStatus>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: _statusList
                            .map(
                              (status) => DropdownMenuItem<TicketStatus>(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _parseColor(status.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(status.statusName),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (TicketStatus? value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignee',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Agents>(
                        value: _selectedAgent,
                        isExpanded: true,
                        hint: const Text('Select'),
                        items: _agentList
                            .map(
                              (agent) => DropdownMenuItem<Agents>(
                                value: agent,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        agent.name.isNotEmpty
                                            ? agent.name[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        agent.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Agents? value) {
                          if (_selectedTeam == null ||
                              _selectedTeam!.teamId == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a team first'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedAgent = value;
                          });
                        },
                        disabledHint: _isLoadingAgents
                            ? const Text('Loading...')
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _TagDropdown(
            selectedTags: _selectedTags,
            availableTags: _availableTags
                .where((tag) => !_selectedTags.contains(tag))
                .toList(),
            onTagSelected: (tag) {
              setState(() {
                _selectedTags.add(tag);
              });
            },
            onTagRemoved: (tag) {
              setState(() {
                _selectedTags.removeWhere(
                  (element) => element.tagId == tag.tagId,
                );
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: _isUpdating ? null : _updateTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } else if (colorString.startsWith('rgb(') && colorString.endsWith(')')) {
      final rgbValues = colorString
          .substring(4, colorString.length - 1)
          .split(' ')
          .map((s) => int.parse(s.trim()))
          .toList();
      if (rgbValues.length == 3) {
        return Color.fromRGBO(rgbValues[0], rgbValues[1], rgbValues[2], 1.0);
      }
    }
    return Colors.transparent;
  }
}
