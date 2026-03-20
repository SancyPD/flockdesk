import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_response.dart';
import '../utils/shared_prefs.dart';
import '../utils/api_config.dart';
import 'package:http_parser/http_parser.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _signatureController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _userName;
  String? _userEmail;
  ProfileResponse? _profileData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchProfileImage();
  }

  Future<void> _loadUserData() async {
    final userName = await SharedPrefs.getUserName();
    final userEmail = await SharedPrefs.getUserEmail();
    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _nameController.text = userName ?? '';
      _emailController.text = userEmail ?? '';
    });
  }

  Future<void> _fetchProfileImage() async {
    try {
      final token = await SharedPrefs.getToken();
      if (token == null) return;
      
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/profile')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.body;
        final Map<String, dynamic> jsonData = data.isNotEmpty ? Map<String, dynamic>.from(json.decode(data)) : {};
        
        // Parse the complete profile data
        final profileResponse = ProfileResponse.fromJson(jsonData);
        
        setState(() {
          _profileData = profileResponse;
          _isLoadingProfile = false;
          
          // Update form fields with profile data
          _nameController.text = profileResponse.result.name;
          _emailController.text = profileResponse.result.email;
          _signatureController.text = _htmlToPlainText(profileResponse.result.emailSignature);
          
          // Update user data variables
          _userName = profileResponse.result.name;
          _userEmail = profileResponse.result.email;
          
          // Handle profile image
          final profileImage = profileResponse.result.profileImage;
          if (profileImage != null && profileImage.toString().isNotEmpty) {
            _profileImageUrl = profileImage.toString().startsWith('http')
                ? profileImage.toString()
                : '${ApiConfig.profileImageBaseUrl}/profile_images/$profileImage';
          }
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      // ignore error, fallback to initials
    }
  }

  Future<void> _pickImage() async {
    final image_picker.ImagePicker picker = image_picker.ImagePicker();
    final image_picker.XFile? image = await picker.pickImage(source: image_picker.ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  String _htmlToPlainText(String html) {
    // HTML to plain text conversion that preserves line breaks
    String text = html;
    
    // Replace paragraph tags with line breaks before removing other tags
    text = text.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    
    // Replace other block-level tags with line breaks
    text = text.replaceAll(RegExp(r'</div>\s*<div[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</br>', caseSensitive: false), '\n');
    
    // Remove remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    
    // Clean up multiple line breaks and whitespace
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n'); // Max 2 consecutive line breaks
    text = text.replaceAll(RegExp(r'[ \t]+'), ' '); // Multiple spaces/tabs to single space
    text = text.replaceAll(RegExp(r' \n'), '\n'); // Remove spaces before line breaks
    text = text.replaceAll(RegExp(r'\n '), '\n'); // Remove spaces after line breaks
    text = text.trim();
    
    return text;
  }


  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SharedPrefs.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.buildUrl('/saveProfile')),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['email_signature'] = _signatureController.text;
      request.fields['has_profile_image'] = _profileImage != null ? '1' : '0';
      request.fields['password'] = "";

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Update shared preferences with new user data
        await SharedPrefs.setUser({
          'name': _nameController.text,
          'email': _emailController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to update profile: $responseBody');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.white,
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFFF2EADB),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null),
                  child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty) && _userName != null && _userName!.isNotEmpty
                      ? Text(
                          _userName![0].toUpperCase(),
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w500),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Name', style: TextStyle(color: Color(0xFF828282), fontSize: 14)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email', style: TextStyle(color: Color(0xFF828282), fontSize: 14)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Signature', style: TextStyle(color: Color(0xFF828282), fontSize: 14)),
                  const SizedBox(height: 6),
                  
                  
                  // Editable Text Field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _signatureController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email signature (HTML supported)',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.save_alt, color: Colors.white),
                label: Text(
                  _isLoading ? 'Saving...' : 'Save',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isLoading ? null : () {},
              icon: const Icon(Icons.delete_outline, color: Colors.black),
              label: const Text('Delete Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _signatureController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 