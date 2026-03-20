import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/views_response.dart' as views_response;
import '../views/inbox_screen.dart';
import '../views/edit_profile_screen.dart';
import '../views/tickets_by_view_screen.dart';
import '../views/recent_tickets_screen.dart';
import '../views/trash_screen.dart';
import '../utils/shared_prefs.dart';
import '../views/login_screen.dart';
import '../services/ticket_service.dart';

class ViewItem {
  final int viewId;
  final String viewTitle;
  final List<StatusItem> statuses;

  ViewItem({
    required this.viewId,
    required this.viewTitle,
    required this.statuses,
  });

  factory ViewItem.fromView(views_response.MenuView view) {
    return ViewItem(
      viewId: view.viewId,
      viewTitle: view.viewTitle,
      statuses: view.statuses
          .map((status) => StatusItem.fromStatus(status))
          .toList(),
    );
  }
}

class StatusItem {
  final int statusId;
  final String statusName;
  final String color;
  final int mailCount;
  final String background;

  StatusItem({
    required this.statusId,
    required this.statusName,
    required this.color,
    required this.mailCount,
    required this.background,
  });

  factory StatusItem.fromStatus(views_response.Status status) {
    return StatusItem(
      statusId: status.statusId,
      statusName: status.statusName,
      color: status.color,
      mailCount: status.mailCount,
      background: status.background,
    );
  }
}

class SideMenuWidget extends StatefulWidget {
  final Function(Widget, String) onScreenChange;
  final List<ViewItem> viewItems;
  final ValueNotifier<Map<int, bool>> viewExpansionNotifier;
  final Function(int) onViewExpansionToggle;
  final VoidCallback? onMenuOpened; // Callback when menu is opened
  final ValueNotifier<bool>? refreshNotifier;
  
  // Global key to access the widget from outside
  static final GlobalKey<_SideMenuWidgetState> globalKey = GlobalKey<_SideMenuWidgetState>();
  
  SideMenuWidget({
    required this.onScreenChange,
    required this.viewItems,
    required this.viewExpansionNotifier,
    required this.onViewExpansionToggle,
    this.onMenuOpened,
    this.refreshNotifier,
  }) : super(key: globalKey);

  // Static method to clear status selection (can be called from outside)
  static Future<void> clearStatusSelection() async {
    await SharedPrefs.setSelectedStatuses(null);
  }

  // Static method to refresh trash count (can be called from outside)
  static Future<void> refreshTrashCount() async {
    final state = globalKey.currentState;
    if (state != null) {
      await state._fetchTrashCount();
    }
  }

  // Static method to refresh inbox count (can be called from outside)
  static Future<void> refreshInboxCount() async {
    final state = globalKey.currentState;
    if (state != null) {
      await state._fetchInboxCount();
    }
  }



  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget>
    with WidgetsBindingObserver {
  bool _isProfileExpanded = false;
  bool _isNoReplyExpanded = false;
  bool _isInboxSelected = true;
  String? _userName;
  String? _userEmail;
  String? _userProfileImageUrl;

  // Track only the last selected status ID
  int? _lastSelectedStatusId;

  // Track if this is the first time opening the menu in this session
  bool _isFirstMenuOpen = true;
  
  // Track trash count
  int _trashCount = 0;
  bool _isLoadingTrashCount = false;
  bool _hasInitiallyFetchedTrashCount = false;
  
  // Track inbox count
  int _inboxCount = 0;
  bool _isLoadingInboxCount = false;
  bool _hasInitiallyFetchedInboxCount = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedStatuses();

    // Clear status selection on app start
    _clearSelectionOnAppStart();
  }

  // Clear status selection when app starts
  Future<void> _clearSelectionOnAppStart() async {
    final lastAccessTime = await SharedPrefs.getLastAccessTime();
    final currentTime = DateTime.now();

    // If no last access time or more than 1 minute has passed, clear selection
    if (lastAccessTime == null ||
        currentTime.difference(lastAccessTime).inMinutes > 1) {
      setState(() {
        _lastSelectedStatusId = null;
      });
      await _saveSelectedStatuses();
    }

    // Update last access time
    await SharedPrefs.setLastAccessTime(currentTime);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load previously selected status from SharedPreferences
  Future<void> _loadSelectedStatuses() async {
    final lastSelectedStatusId = await SharedPrefs.getSelectedStatuses();
    final lastAccessTime = await SharedPrefs.getLastAccessTime();
    final currentTime = DateTime.now();

    // If more than 5 minutes have passed since last access, clear the selection
    if (lastAccessTime != null &&
        currentTime.difference(lastAccessTime).inMinutes > 5) {
      setState(() {
        _lastSelectedStatusId = null;
      });
      await _saveSelectedStatuses();
    } else {
      setState(() {
        _lastSelectedStatusId = lastSelectedStatusId;
      });
    }

    // Update last access time
    await SharedPrefs.setLastAccessTime(currentTime);
  }

  // Save last selected status to SharedPreferences
  Future<void> _saveSelectedStatuses() async {
    await SharedPrefs.setSelectedStatuses(_lastSelectedStatusId);
  }

  // Fetch trash count from API
  Future<void> _fetchTrashCount() async {
    if (_isLoadingTrashCount) return;
    
    setState(() {
      _isLoadingTrashCount = true;
    });
    
    try {
      final count = await TicketService().getTrashCount();
      setState(() {
        _trashCount = count;
        _isLoadingTrashCount = false;
        _hasInitiallyFetchedTrashCount = true;
      });
    } catch (e) {
      print('Error fetching trash count: $e');
      setState(() {
        _trashCount = 0;
        _isLoadingTrashCount = false;
        _hasInitiallyFetchedTrashCount = true;
      });
    }
  }

  // Method to refresh trash count (can be called from outside)
  Future<void> refreshTrashCount() async {
    await _fetchTrashCount();
  }

  // Fetch inbox count from API
  Future<void> _fetchInboxCount() async {
    if (_isLoadingInboxCount) return;
    
    setState(() {
      _isLoadingInboxCount = true;
    });
    
    try {
      final count = await TicketService().getInboxTicketsCount();
      setState(() {
        _inboxCount = count;
        _isLoadingInboxCount = false;
        _hasInitiallyFetchedInboxCount = true;
      });
    } catch (e) {
      print('Error fetching inbox count: $e');
      setState(() {
        _inboxCount = 0;
        _isLoadingInboxCount = false;
        _hasInitiallyFetchedInboxCount = true;
      });
    }
  }

  // Method to refresh inbox count (can be called from outside)
  Future<void> refreshInboxCount() async {
    await _fetchInboxCount();
  }

  // Helper to parse color strings (handling both hex and rgb)
  Color parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      // Hex color
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor; // Add FF for opaque
      }
      return Color(int.parse(hexColor, radix: 16));
    } else if (colorString.startsWith('rgb')) {
      // RGB color
      final regex = RegExp(r'\d+\s*\d*\s*\d*');
      final matches = regex.firstMatch(colorString);
      if (matches != null) {
        final rgbValues = matches.group(0)?.split(' ').map(int.parse).toList();
        if (rgbValues != null && rgbValues.length == 3) {
          return Color.fromARGB(255, rgbValues[0], rgbValues[1], rgbValues[2]);
        }
      }
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Clear status selection on first menu open (app reload)
    if (_isFirstMenuOpen) {
      _lastSelectedStatusId = null;
      _isFirstMenuOpen = false;
      _saveSelectedStatuses();

      // Notify parent that menu was opened
      widget.onMenuOpened?.call();
    }
    
    // Only fetch trash count if not already fetched initially
    if (!_hasInitiallyFetchedTrashCount) {
      _fetchTrashCount();
    }
    
    // Only fetch inbox count if not already fetched initially
    if (!_hasInitiallyFetchedInboxCount) {
      _fetchInboxCount();
    }

    return Drawer(
      backgroundColor: const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Column(
          children: [
            // Logo section
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/m_logo.png', height: 40),
              ),
            ),
            // OVERVIEW section header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'OVERVIEW',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFA9A9A9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(height: 1, color: const Color(0xFFEFEFEF)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Map<int, bool>>(
                valueListenable: widget.viewExpansionNotifier,
                builder: (context, viewExpansionState, child) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isInboxSelected = true;
                            // Reset status selection when navigating to Inbox
                            _lastSelectedStatusId = null;
                          });
                          _saveSelectedStatuses(); // Save the cleared selection
                          widget.onScreenChange(const InboxScreen(), 'Inbox');
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/inbox_ic.png',
                                width: 25,
                                height: 25,
                                color: _isInboxSelected
                                    ? const Color(0xFF3F3F3F)
                                    : const Color(0xFFA9A9A9),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Text(
                                  'Inbox',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isInboxSelected
                                        ? const Color(0xFF292D32)
                                        : const Color(0xFF50585E),
                                  ),
                                ),
                              ),
                              if (_inboxCount > 0 || _isLoadingInboxCount)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isLoadingInboxCount
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF838383),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          '$_inboxCount',
                                          style: const TextStyle(
                                            color: Color(0xFF838383),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Dynamically build view items from passed data
                      ...widget.viewItems.map((viewItem) {
                        final isExpanded =
                            viewExpansionState[viewItem.viewId] ?? false;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () =>
                                  widget.onViewExpansionToggle(viewItem.viewId),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 25, height: 25),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Text(
                                        viewItem.viewTitle,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isExpanded
                                              ? const Color(0xFF292D32)
                                              : const Color(0xFF50585E),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: isExpanded
                                          ? const Color(0xFF292D32)
                                          : const Color(0xFF50585E),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              ...viewItem.statuses
                                  .map(
                                    (status) => InkWell(
                                      onTap: () {
                                        // Set the selected status for this view
                                        setState(() {
                                          _lastSelectedStatusId =
                                              status.statusId;
                                        });
                                        _saveSelectedStatuses(); // Save immediately

                                        Navigator.pop(context); // Close drawer
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TicketsByViewScreen(
                                                  viewId: viewItem.viewId,
                                                  statusId: status.statusId,
                                                  viewTitle: viewItem.viewTitle,
                                                  statusName: status.statusName,
                                                  allViewItems:
                                                      widget.viewItems,
                                                  allViewExpansionNotifier:
                                                      widget
                                                          .viewExpansionNotifier,
                                                  onAllViewExpansionToggle:
                                                      widget
                                                          .onViewExpansionToggle,
                                                  onMainScreenChange:
                                                      widget.onScreenChange,
                                                  refreshNotifier: widget.refreshNotifier,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              _lastSelectedStatusId ==
                                                  status.statusId
                                              ? const Color(0xFFF5F8F9)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        margin: const EdgeInsets.only(
                                          left: 72.0,
                                          right: 16.0,
                                          top: 4,
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            _lastSelectedStatusId ==
                                                    status.statusId
                                                ? Image.asset(
                                                    'assets/images/selected_pointer.png',
                                                    width: 9,
                                                    height: 6,
                                                    fit: BoxFit.cover,
                                                  )
                                                : SizedBox(width: 9),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                status.statusName,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      _lastSelectedStatusId ==
                                                          status.statusId
                                                      ? const Color(0xFF2F3337)
                                                      : const Color(0xFF86939D),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFFFF),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                '${status.mailCount}',
                                                style: const TextStyle(
                                                  color: Color(0xFF828282),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ],
                        );
                      }).toList(),
                      InkWell(
                        onTap: () {
                          // Reset status selection when navigating to Recent
                          setState(() {
                            _lastSelectedStatusId = null;
                          });
                          _saveSelectedStatuses(); // Save the cleared selection

                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecentTicketsScreen(
                                allViewItems: widget.viewItems,
                                allViewExpansionNotifier:
                                    widget.viewExpansionNotifier,
                                onAllViewExpansionToggle:
                                    widget.onViewExpansionToggle,
                                onMainScreenChange: widget.onScreenChange,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/recent_ic.png',
                                width: 25,
                                height: 25,

                              ),
                              const SizedBox(width: 32),
                              const Expanded(
                                child: Text(
                                  'Recent',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Reset status selection when navigating to Trash
                          setState(() {
                            _lastSelectedStatusId = null;
                          });
                          _saveSelectedStatuses(); // Save the cleared selection

                          // Refresh trash count when navigating to trash
                          _fetchTrashCount();

                          // Navigate to Trash screen
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrashScreen(
                                allViewItems: widget.viewItems,
                                allViewExpansionNotifier: widget.viewExpansionNotifier,
                                onViewExpansionToggle: widget.onViewExpansionToggle,
                                onMainScreenChange: widget.onScreenChange,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/trash_ic.png',
                                width: 25,
                                height: 25,
                              ),
                              const SizedBox(width: 32),
                              const Expanded(
                                child: Text(
                                  'Trash',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ),
                              if (_trashCount > 0 || _isLoadingTrashCount)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F6F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isLoadingTrashCount
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF838383),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          '$_trashCount',
                                          style: const TextStyle(
                                            color: Color(0xFF838383),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // const Divider(color: Color(0xFFEFEFEF)),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFEFEF),width: 1)
              ),
              margin: const EdgeInsets.only(left: 10.0,right: 10.0,bottom: 10.0,top: 20.0),
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isProfileExpanded = !_isProfileExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: _userProfileImageUrl != null
                              ? NetworkImage(_userProfileImageUrl!)
                              : const AssetImage('assets/images/user.png')
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName ?? 'Loading...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              Text(
                                _userEmail ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF828282),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isProfileExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF454545),
                        ),
                      ],
                    ),
                  ),
                  if (_isProfileExpanded) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Image.asset(
                        'assets/images/edit_ic.png',
                        width: 15,
                        height: 15,

                      ),
                      title: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF313131),
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFEFEFEF)),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Image.asset(
                        'assets/images/log_out_ic.png',
                        height: 15,
                        width: 15,
                        fit: BoxFit.contain,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF313131),
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        // Clear selected statuses on logout
                        _lastSelectedStatusId = null;
                        await _saveSelectedStatuses();

                        await SharedPrefs.clearAll();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isExpandable = false,
    bool isExpanded = false,
    List<Widget>? children,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Image.asset(
            'assets/images/inbox_ic.png',
            height: 24,
            color: const Color(0xFFA9A9A9),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF313131),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          trailing: isExpandable
              ? Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF313131),
                )
              : null,
          onTap: onTap,
        ),
        if (isExpanded && children != null) ...children,
      ],
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String text,
    Widget? trailing,
    VoidCallback? onTap,
    double leadingIndent = 20.0, // Default indent for regular items
    double iconSize = 24.0,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: leadingIndent, right: 16.0),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Color(0xFF313131)),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Future<void> _loadUserData() async {
    final userName = await SharedPrefs.getUserName();
    final userEmail = await SharedPrefs.getUserEmail();
    final userProfileImageUrl = await SharedPrefs.getUserProfileImageUrl();
    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userProfileImageUrl = userProfileImageUrl;
    });
  }
}
