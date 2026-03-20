import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'new_ticket_screen.dart';
import 'notifications_screen.dart';
import 'inbox_screen.dart';
import '../widgets/side_menu_widget.dart';
import '../services/profile_service.dart';
import '../models/views_response.dart';
import '../utils/shared_prefs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _currentScreen = const InboxScreen();
  String _currentTitle = 'Inbox';
  List<ViewItem> _viewItems = [];
  ValueNotifier<Map<int, bool>> _viewExpansionNotifier = ValueNotifier({});
  ValueNotifier<bool> _refreshNotifier = ValueNotifier(false);
  bool _isLoadingViews = true;
  String? _userProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadViews();
    _loadUserProfileImage();
    _preloadTrashCount();
  }

  // Preload trash count when home screen launches
  Future<void> _preloadTrashCount() async {
    // Use a small delay to ensure the side menu widget is created
    await Future.delayed(const Duration(milliseconds: 100));
    SideMenuWidget.refreshTrashCount();
    SideMenuWidget.refreshInboxCount();
  }

  Future<void> _loadViews() async {
    try {
      final List<MenuView> views = await ProfileService().getViews();
      setState(() {
        _viewItems = views.map((view) => ViewItem.fromView(view)).toList();
        _isLoadingViews = false;
        // Initialize expansion state for each view item to false in the notifier
        final initialExpansionState = <int, bool>{};
        for (var viewItem in _viewItems) {
          initialExpansionState[viewItem.viewId] = false;
        }
        _viewExpansionNotifier.value = initialExpansionState;
      });
    } catch (e) {
      print('Error fetching views: $e');
      setState(() {
        _isLoadingViews = false;
      });
    }
  }

  Future<void> _loadUserProfileImage() async {
    final url = await SharedPrefs.getUserProfileImageUrl();
    setState(() {
      _userProfileImageUrl = url;
    });
  }

  void _toggleViewExpansion(int viewId) {
    final currentMap = Map<int, bool>.from(_viewExpansionNotifier.value);
    final isCurrentlyExpanded = currentMap[viewId] ?? false;

    // If the clicked view is currently expanded, just close it
    if (isCurrentlyExpanded) {
      currentMap[viewId] = false;
    } else {
      // If the clicked view is not expanded, close all other views and expand this one
      for (var key in currentMap.keys) {
        currentMap[key] = false;
      }
      currentMap[viewId] = true;
    }

    _viewExpansionNotifier.value = currentMap;
  }

  void _changeScreen(Widget screen, String title) {
    setState(() {
      _currentScreen = screen;
      _currentTitle = title;
    });
  }

  Widget _getCurrentScreen() {
    if (_currentScreen is InboxScreen) {
      return InboxScreen(refreshNotifier: _refreshNotifier);
    }
    // For other screens, we'll need to handle them differently
    // since they are created in the side menu with their own parameters
    return _currentScreen;
  }

  // Method to refresh the current screen
  void _refreshCurrentScreen() {
    _refreshNotifier.value = !_refreshNotifier.value; // Toggle to trigger refresh
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: SideMenuWidget(
          onScreenChange: _changeScreen,
          viewItems: _viewItems,
          viewExpansionNotifier: _viewExpansionNotifier,
          onViewExpansionToggle: _toggleViewExpansion,
          refreshNotifier: _refreshNotifier,
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
          title: Row(
            children: [
              Text(
                _currentTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),

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
                // If ticket was created successfully, refresh the current screen
                if (result == true) {
                  _refreshCurrentScreen();
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
        body: _getCurrentScreen(),
        /*  floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewTicketScreen()),
              );
            },
            child: Image.asset(
              'assets/images/floating_but.png',
              width: 70,
              height: 70,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,*/
      ),
    );
  }
}
