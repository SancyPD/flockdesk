import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../services/desk_service.dart';
import '../utils/shared_prefs.dart';
import '../models/search_email_response.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';


class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ticketService = TicketService();
  final _deskService = DeskService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final List<String> _ccEmails = [];
  final List<PlatformFile> _attachments = [];
  bool _isLoading = false;
  String? _error;
  List<DeskResult> _deskList = [];
  DeskResult? _selectedDesk;
  bool _isLoadingDesks = true;
  String _searchQuery = '';

  // State for To email dropdown
  String _toSearchQuery = '';
  List<SearchResult> _toEmailResults = [];
  bool _isLoadingToEmails = false;
  Timer? _toSearchDebounce;

  // State for Cc email dropdown
  bool _showCcField = false;
  final TextEditingController _ccTextController = TextEditingController();
  final FocusNode _ccFocusNode = FocusNode();
  final LayerLink _ccFieldLink = LayerLink();
  OverlayEntry? _ccDropdownOverlay;
  String _ccSearchQuery = '';
  List<SearchResult> _ccEmailResults = [];
  bool _isLoadingCcEmails = false;
  Timer? _ccSearchDebounce;

  String? _userProfileImageUrl;
  String? _userName;
  final TextEditingController _toTextController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();
  final LayerLink _toFieldLink = LayerLink();
  OverlayEntry? _toDropdownOverlay;
  List<dynamic> _macros = [];
  bool _isLoadingMacros = false;

  int? _selectedTeamId;
  int? _selectedStatusId;
  int? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    _loadDeskList();
    _loadUserProfileImage();
    _loadUserName();
    _toFocusNode.addListener(_handleToFocusChange);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _toSearchDebounce?.cancel();
    _ccSearchDebounce?.cancel();
    _toTextController.dispose();
    _toFocusNode.removeListener(_handleToFocusChange);
    _toFocusNode.dispose();
    _ccTextController.dispose();
    _ccFocusNode.dispose();
    _ccDropdownOverlay?.remove();
    super.dispose();
  }

  void _handleToFocusChange() {
    if (!_toFocusNode.hasFocus) {
      _removeToDropdownOverlay();
    } else if (_toTextController.text.isNotEmpty && (_isLoadingToEmails || _toEmailResults.isNotEmpty)) {
      _showToDropdownOverlay();
    }
  }

  void _showToDropdownOverlay() {
    _removeToDropdownOverlay();
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _toDropdownOverlay = OverlayEntry(
      builder: (context) {
        RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        return Positioned(
          width: 400,
          child: CompositedTransformFollower(
            link: _toFieldLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 59),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: _isLoadingToEmails
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _toEmailResults.length,
                      itemBuilder: (context, index) {
                        final emailResult = _toEmailResults[index];
                        return ListTile(
                          title: Text(emailResult.emailId),
                          subtitle: Text(emailResult.contactName),
                          onTap: () {
                            setState(() {
                              _toSearchQuery = emailResult.emailId;
                              _toEmailResults = [];
                            });
                            _toTextController.text = emailResult.emailId;
                            _toFocusNode.unfocus();
                            _removeToDropdownOverlay();
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
    overlay.insert(_toDropdownOverlay!);
  }

  void _removeToDropdownOverlay() {
    _toDropdownOverlay?.remove();
    _toDropdownOverlay = null;
  }

  Future<void> _loadDeskList() async {
    try {
      final response = await _deskService.getDeskList();
      setState(() {
        _deskList = response.result.where((desk) => desk.deskStatus == '1').toList();
        if (_deskList.isNotEmpty) {
          _selectedDesk = _deskList.first;
        }
        _isLoadingDesks = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load desk list: ${e.toString()}';
        _isLoadingDesks = false;
      });
    }
  }

  Future<void> _searchToEmails({String query = ''}) async {
    setState(() {
      _isLoadingToEmails = true;
    });
    try {
      final results = await _deskService.searchEmails(key: query);
      setState(() {
        _toEmailResults = results.result;
        _isLoadingToEmails = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search emails: ${e.toString()}';
        _isLoadingToEmails = false;
      });
    }
  }

  void _onToSearchChanged(String value) {
    if (_toSearchDebounce?.isActive ?? false) _toSearchDebounce!.cancel();
    _toSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchToEmails(query: value);
    });
  }

  Future<void> _searchCcEmails({String query = ''}) async {
    setState(() {
      _isLoadingCcEmails = true;
    });
    try {
      final results = await _deskService.searchEmails(key: query);
      setState(() {
        _ccEmailResults = results.result;
        _isLoadingCcEmails = false;
      });
      if (_ccFocusNode.hasFocus && query.isNotEmpty && (_isLoadingCcEmails || _ccEmailResults.isNotEmpty)) {
        _showCcDropdownOverlay();
      } else {
        _removeCcDropdownOverlay();
      }
    } catch (e) {
      setState(() {
        _isLoadingCcEmails = false;
      });
    }
  }

  void _onCcSearchChanged(String value) {
    _ccSearchDebounce?.cancel();
    _ccSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchCcEmails(query: value);
    });
  }

  void _showCcDropdownOverlay() {
    _removeCcDropdownOverlay();
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _ccDropdownOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 400,
          child: CompositedTransformFollower(
            link: _ccFieldLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 59),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: _isLoadingCcEmails
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _ccEmailResults.length,
                      itemBuilder: (context, index) {
                        final emailResult = _ccEmailResults[index];
                        return ListTile(
                          title: Text(emailResult.emailId),
                          subtitle: Text(emailResult.contactName),
                          onTap: () {
                            setState(() {
                              if (!_ccEmails.contains(emailResult.emailId)) {
                                _ccEmails.add(emailResult.emailId);
                              }
                              _ccTextController.clear();
                              _ccSearchQuery = '';
                              _ccEmailResults = [];
                            });
                            _ccFocusNode.requestFocus();
                            _removeCcDropdownOverlay();
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
    overlay.insert(_ccDropdownOverlay!);
  }

  void _removeCcDropdownOverlay() {
    _ccDropdownOverlay?.remove();
    _ccDropdownOverlay = null;
  }

  Future<void> _pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

      if (result != null) {
        bool hasOversized = false;
        const int maxSizeBytes = 10 * 1024 * 1024; // 10MB
        List<PlatformFile> newFiles = [];
        for (final file in result.files) {
          if (file.size <= maxSizeBytes) {
            if (!_attachments.any((f) => f.name == file.name && f.size == file.size)) {
              newFiles.add(file);
            }
          } else {
            hasOversized = true;
          }
        }
        setState(() {
          _attachments.addAll(newFiles);
        });
        if (hasOversized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Some files exceeded the 10MB limit and were not added.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserProfileImage() async {
    final url = await SharedPrefs.getUserProfileImageUrl();
    setState(() {
      _userProfileImageUrl = url;
    });
  }

  Future<void> _loadUserName() async {
    final name = await SharedPrefs.getUserName();
      setState(() {
      _userName = name;
      });
  }

  Future<void> _loadMacrosAndShowSheet() async {
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
          _macros = macrosList;
          _isLoadingMacros = false;
        });
        _showMacrosSheet();
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

  void _showMacrosSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        if (_isLoadingMacros) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_macros.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No macros available')),
          );
        }
        return SizedBox(
          height: 350,
          child: ListView.builder(
            itemCount: _macros.length,
            itemBuilder: (context, index) {
              final macro = _macros[index];
              return ListTile(
                title: Text(macro['macro_title'] ?? ''),
                onTap: () {
      setState(() {
                    _messageController.text = _htmlToPlainText(macro['macro_body'] ?? '');
      });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
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
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Max 2 consecutive newlines
    text = text.replaceAll(RegExp(r'[ \t]+'), ' '); // Multiple spaces/tabs to single space
    text = text.replaceAll(RegExp(r'\n '), '\n'); // Remove spaces after newlines
    text = text.replaceAll(RegExp(r' \n'), '\n'); // Remove spaces before newlines
    
    text = text.trim();

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // User Info Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _userProfileImageUrl != null && _userProfileImageUrl!.isNotEmpty
                            ? NetworkImage(_userProfileImageUrl!)
                            : const AssetImage('assets/images/user.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName != null && _userName!.isNotEmpty ? _userName! : 'User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                  ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  if (_deskList.isEmpty) return;
                                  final selected = await showModalBottomSheet<DeskResult>(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                          children: [
                                            const SizedBox(height: 12),
                                            const Text('Select Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const Divider(),
                                            ..._deskList.map((desk) => ListTile(
                                              leading: const Icon(Icons.email),
                                              title: Text(desk.emailAddress),
                                              onTap: () => Navigator.pop(context, desk),
                                              selected: desk == _selectedDesk,
                                            )),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  if (selected != null && selected != _selectedDesk) {
                                setState(() {
                                      _selectedDesk = selected;
                                });
                                  }
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                children: [
                                    Text(
                                      _selectedDesk?.emailAddress ?? '',
                                      style: const TextStyle(fontSize: 13),
                                  ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                                  ],
                                ),
                              ),
                                  ),
                                ],
                              ),
                            ),
                      // Replace close icon with close_1.png
                      IconButton(
                        icon: Image.asset('assets/images/close_1.png', width: 24, height: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: Image.asset('assets/images/menu_ic.png', width: 24, height: 24),
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                    ),
                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: _UpdateTicketOverlay(),
                                ),
                              ),
                                      ),
                          );
                          if (result != null) {
                                        setState(() {
                              _selectedTeamId = result['teamId'];
                              _selectedStatusId = result['statusId'];
                              _selectedAssigneeId = result['assigneeId'];
                                        });
                          }
                                  },
                                ),
                          ],
                ),
                  const SizedBox(height: 28),
                  // To Field
                const Text('To', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: 400,
                      child: CompositedTransformTarget(
                        link: _toFieldLink,
                        child: Container(
                          height: 59,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF2F2F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            focusNode: _toFocusNode,
                            controller: _toTextController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isCollapsed: true,
                              suffixIcon: _toTextController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _toTextController.clear();
                                          _toSearchQuery = '';
                                          _toEmailResults = [];
                                        });
                                        _removeToDropdownOverlay();
                                      },
                                    )
                                  : null,
                            ),
                            style: const TextStyle(fontSize: 16),
                            onChanged: (value) {
                              setState(() {
                                _toSearchQuery = value;
                              });
                              _onToSearchChanged(value);
                              if (_toFocusNode.hasFocus && value.isNotEmpty && (_isLoadingToEmails || _toEmailResults.isNotEmpty)) {
                                _showToDropdownOverlay();
                              } else {
                                _removeToDropdownOverlay();
                              }
                                  },
                                ),
                              ),
                      ),
                  ),
                ),
                  if (_showCcField) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            const Text('CC', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            CompositedTransformTarget(
                              link: _ccFieldLink,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                            onTap: () {
                                  _ccFocusNode.requestFocus();
                                },
                                child: Container(
                                  height: _ccEmails.isEmpty ? 59 : null,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF2F2F2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            ..._ccEmails.map((email) => Chip(
                                                  label: Text(email),
                                              deleteIcon: Image.asset(
                                                'assets/images/clear_ic.png',
                                                width: 12,
                                                height: 12,
                                              ),
                                                  onDeleted: () {
                              setState(() {
                                                      _ccEmails.remove(email);
                              });
                            },

                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  backgroundColor: Colors.white,
                                                )),
                                            SizedBox(
                                              width: 120,
                          child: TextField(
                                                focusNode: _ccFocusNode,
                                                controller: _ccTextController,
                                                textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.zero,
                                                  isCollapsed: true,
                                                  suffixIcon: _ccTextController.text.isNotEmpty
                                                      ? IconButton(
                                                          icon: const Icon(Icons.clear, size: 20),
                                                          onPressed: () {
                                        setState(() {
                                                              _ccTextController.clear();
                                          _ccSearchQuery = '';
                                                              _ccEmailResults = [];
                                                            });
                                                            _removeCcDropdownOverlay();
                                                          },
                                                        )
                                                      : null,
                                                ),
                                                style: const TextStyle(fontSize: 16),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _ccSearchQuery = value;
                                                  });
                                                  _onCcSearchChanged(value);
                                                  if (_ccFocusNode.hasFocus && value.isNotEmpty && (_isLoadingCcEmails || _ccEmailResults.isNotEmpty)) {
                                                    _showCcDropdownOverlay();
                                                  } else {
                                                    _removeCcDropdownOverlay();
                                                  }
                                                },
                                                onSubmitted: (value) {
                                                  if (value.isNotEmpty && !_ccEmails.contains(value)) {
                                                    setState(() {
                                                      _ccEmails.add(value);
                                                    });
                                                    _ccTextController.clear();
                                                    _ccSearchQuery = '';
                                                    _ccEmailResults = [];
                                                    _removeCcDropdownOverlay();
                                                  }
                                  },
                                ),
                              ),
                      ],
                                        ),
                                      ),
                    ],
                  ),
                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Subject Field
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                  Container(
                    height: 59,
                    decoration: ShapeDecoration(
                      // color: const Color(0xFFF8F8F8),
                      color: const Color(0xFFF2F2F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                    ),
                      style: const TextStyle(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                  ),
                  const SizedBox(height: 24),
                  // Message Field
                const Text('Message', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue...',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                  const SizedBox(height: 24),
                  // Action Row (CC, Add Screenshot/File, Macros)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCcField = !_showCcField;
                          });
                        },
                  child: Container(
                          height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFFC7C7C7)),
                              borderRadius: BorderRadius.circular(100),
                    ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 2,
                                offset: Offset(0, 2),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                              Text(
                                'CC',
                                style: TextStyle(
                                  color: const Color(0xFF3F3F3F),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pickAttachment,
                        child: Container(
                          height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFFC7C7C7)),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 2,
                                offset: Offset(0, 2),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.attach_file, size: 18, color: Color(0xFF828282)),
                              const SizedBox(width: 8),
                              Text(
                                'Add Screenshot / File',
                                style: TextStyle(
                                  color: const Color(0xFF828282),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loadMacrosAndShowSheet,
                        child: Container(
                          height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFFC7C7C7)),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 2,
                                offset: Offset(0, 2),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.grid_view, size: 18, color: Color(0xFF828282)),
                              const SizedBox(width: 8),
                              Text(
                                'Macros',
                                style: TextStyle(
                                  color: const Color(0xFF828282),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  height: 1.30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                      children: _attachments.map((file) {
                      return Chip(
                          label: Text(file.name, overflow: TextOverflow.ellipsis),
                        backgroundColor: Colors.grey[100],
                        deleteIcon: Image.asset(
                          'assets/images/clear_ic.png',
                          width: 12,
                          height: 12,
                        ),                        onDeleted: () {
                          setState(() {
                              _attachments.remove(file);
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      );
                    }).toList(),
                  ),
                ],
                  const SizedBox(height: 24),
                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      onPressed: _isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        try {
                          final token = await SharedPrefs.getToken();
                          if (token == null) {
                            throw Exception('No authentication token found');
                          }
                          final htmlContent = _messageController.text
                              .split('\n')
                              .map((line) => '<p>$line</p>')
                              .join('');
                          final success = await _ticketService.createTicket(
                            toEmail: _toTextController.text,
                            ccMails: _ccEmails.join(','),
                            toName: _toTextController.text,
                            subject: _subjectController.text,
                            mailContent: htmlContent,
                            fromEmail: _selectedDesk?.emailAddress ?? '',
                            hasAttachments: _attachments.isNotEmpty ? 1 : 0,
                            attachments: _attachments,
                            teamId: _selectedTeamId ?? 0,
                            assignTo: _selectedAssigneeId ?? 0,
                            status: _selectedStatusId ?? 0,
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ticket created successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            Navigator.pop(context, true); // Return true to indicate success
                          }
                        } catch (e) {
                          setState(() {
                            _error = e.toString();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create ticket: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'Send',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Preview Link
                  /*Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Preview',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF3F3F3F),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 

class _UpdateTicketOverlay extends StatefulWidget {
  final List<Map<String, dynamic>>? teamData;
  final List<Map<String, dynamic>>? statusData;
  final List<Map<String, dynamic>>? assigneeData;
  final int? initialTeamId;
  final int? initialStatusId;
  final int? initialAssigneeId;
  const _UpdateTicketOverlay({this.teamData, this.statusData, this.assigneeData, this.initialTeamId, this.initialStatusId, this.initialAssigneeId});
  @override
  State<_UpdateTicketOverlay> createState() => _UpdateTicketOverlayState();
}

class _UpdateTicketOverlayState extends State<_UpdateTicketOverlay> {
  int? _selectedTeamId;
  int? _selectedStatusId;
  int? _selectedAssigneeId;
  List<Map<String, dynamic>> _teamList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _assigneeList = [];
  bool _isLoadingTeams = true;
  bool _isLoadingStatuses = true;
  bool _isLoadingAssignees = false;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _fetchStatuses();
    if (widget.initialTeamId != null) _selectedTeamId = widget.initialTeamId;
    if (widget.initialStatusId != null) _selectedStatusId = widget.initialStatusId;
    if (widget.initialAssigneeId != null) _selectedAssigneeId = widget.initialAssigneeId;
  }

  Future<void> _fetchTeams() async {
    setState(() { _isLoadingTeams = true; });
    try {
      final token = await SharedPrefs.getToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/listTeams')),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final teams = (data['result'] as List).map((t) => t as Map<String, dynamic>).toList();
        setState(() {
          _teamList = teams;
          _isLoadingTeams = false;
        });
      } else {
        setState(() { _isLoadingTeams = false; });
      }
    } catch (e) {
      setState(() { _isLoadingTeams = false; });
    }
  }

  Future<void> _fetchStatuses() async {
    setState(() { _isLoadingStatuses = true; });
    try {
      final token = await SharedPrefs.getToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/getTicketstatus')),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final statuses = (data['result'] as List).map((s) => s as Map<String, dynamic>).toList();
        int? openId;
        for (final status in statuses) {
          if ((status['status_name'] as String).toLowerCase() == 'open') {
            openId = status['status_id'];
            break;
          }
        }
        setState(() {
          _statusList = statuses;
          _isLoadingStatuses = false;
          if (openId != null) {
            _selectedStatusId = openId;
          } else if (statuses.isNotEmpty) {
            _selectedStatusId = statuses.first['status_id'];
          }
        });
      } else {
        setState(() { _isLoadingStatuses = false; });
      }
    } catch (e) {
      setState(() { _isLoadingStatuses = false; });
    }
  }

  Future<void> _fetchAssignees(int teamId) async {
    setState(() { _isLoadingAssignees = true; });
    try {
      final token = await SharedPrefs.getToken();
      if (token == null) return;
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/listAgentsByteam')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'team_id': teamId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agents = (data['result'] as List).map((a) => a as Map<String, dynamic>).toList();
        setState(() {
          _assigneeList = agents;
          _isLoadingAssignees = false;
        });
      } else {
        setState(() { _assigneeList = []; _isLoadingAssignees = false; });
      }
    } catch (e) {
      setState(() { _assigneeList = []; _isLoadingAssignees = false; });
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
            const Text('Ticket Info', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Image.asset('assets/images/close_1.png', width: 24, height: 24),
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
            child: DropdownButton<String>(
               value: _selectedTeamId != null ? _teamList.firstWhere((t) => t['team_id'] == _selectedTeamId)['team_title'] : null,
                isExpanded: true,
                hint: const Text('Select a team'),
               items: _teamList
                   .map((team) => DropdownMenuItem<String>(
                         value: team['team_title'],
                         child: Text(team['team_title']),
                       ))
                   .toList(),
               onChanged: (value) {
                 final team = _teamList.firstWhere((t) => t['team_title'] == value);
                            setState(() {
                   _selectedTeamId = team['team_id'];
                   _selectedAssigneeId = null;
                            });
                 if (_selectedTeamId != null) {
                   _fetchAssignees(_selectedTeamId!);
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
                          const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                    height: 48,
                            decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                            ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                         value: _selectedStatusId != null ? _statusList.firstWhere((s) => s['status_id'] == _selectedStatusId)['status_name'] : null,
                          isExpanded: true,
                         items: _statusList
                             .map((status) => DropdownMenuItem<String>(
                                   value: status['status_name'],
                                   child: Text(status['status_name']),
                                 ))
                             .toList(),
                         onChanged: (value) {
                           final status = _statusList.firstWhere((s) => s['status_name'] == value);
                                      setState(() {
                             _selectedStatusId = status['status_id'];
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
                          const Text('Assignee', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                    height: 48,
                            decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                            ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                         value: _selectedAssigneeId != null ? _assigneeList.firstWhere((a) => a['id'] == _selectedAssigneeId)['name'] : null,
                          isExpanded: true,
                          hint: const Text('Select'),
                         items: _assigneeList
                             .map((assignee) => DropdownMenuItem<String>(
                                   value: assignee['name'],
                                   child: Text(assignee['name']),
                                 ))
                             .toList(),
                         onChanged: (value) {
                           final agent = _assigneeList.firstWhere((a) => a['name'] == value);
                                      setState(() {
                             _selectedAssigneeId = agent['id'];
                                      });
                                    },
                          disabledHint: _isLoadingAssignees ? const Text('Loading...') : null,
                          ),
                      ),
                    ),
                  ],
                ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'teamId': _selectedTeamId,
                'statusId': _selectedStatusId,
                'assigneeId': _selectedAssigneeId,
        });
      },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 