// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lineup/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onProfileUpdated;

  const ProfileEditScreen({
    Key? key,
    required this.userData,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _populateFields() {
    _nameController.text = widget.userData['name'] ?? '';
    _phoneNumberController.text = widget.userData['phone_number'] ?? '';
    _profileImageUrl = widget.userData['profile_image_url'];
  }

  Future<GeoPoint?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  bool _validatePhoneNumber(String phoneNumber) {
    final RegExp phoneRegex = RegExp(r'^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog("Please enter your name.");
      return;
    }

    if (!_validatePhoneNumber(_phoneNumberController.text.trim())) {
      _showErrorDialog("Please enter a valid Indian phone number.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      GeoPoint? currentLocation = await _getCurrentLocation();
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_profileImage != null) {
          await _uploadImage();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim(),
          'location': currentLocation,
          'profile_image_url': _profileImageUrl,
        });

        widget.onProfileUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog("Failed to update profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null 
                      ? FileImage(_profileImage!) 
                      : (_profileImageUrl != null 
                          ? NetworkImage(_profileImageUrl!) as ImageProvider 
                          : AssetImage('assets/default_profile.png')),
                  child: _profileImage == null && _profileImageUrl == null
                      ? Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).primaryColor)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                  hintText: 'Name',
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                  hintText: 'Phone Number (Indian)',
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (_profileImage != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference reference = FirebaseStorage.instance.ref().child('profile_photos/$fileName');
        UploadTask uploadTask = reference.putFile(_profileImage!);

        await uploadTask.whenComplete(() async {
          _profileImageUrl = await reference.getDownloadURL();
          print('Profile Image URL: $_profileImageUrl');
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to upload image: $e");
      rethrow;
    }
  }
}