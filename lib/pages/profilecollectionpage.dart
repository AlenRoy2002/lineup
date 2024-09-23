// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, sort_child_properties_last

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lineup/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lineup/pages/homepage.dart';

class ProfileCollectionPage extends StatefulWidget {
  final String email;
  const ProfileCollectionPage({Key? key, required this.email}) : super(key: key);

  @override
  _ProfileCollectionPageState createState() => _ProfileCollectionPageState();
}

class _ProfileCollectionPageState extends State<ProfileCollectionPage> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;
  String? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<GeoPoint?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog("Error", "Location services are disabled.");
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showDialog("Error", "Location permissions are denied.");
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showDialog("Error", "Location permissions are permanently denied, we cannot request permissions.");
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      _showDialog("Error", "Failed to get current location: $e");
      return null;
    }
  }

  bool _validatePhoneNumber(String phoneNumber) {
    // Indian phone number regex pattern
    final RegExp phoneRegex = RegExp(r'^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  Future<void> saveUserProfile() async {
    if (_nameController.text.trim().isEmpty || _selectedRole == null) {
      _showDialog("Error", "Please fill all fields correctly.");
      return;
    }

    if (!_validatePhoneNumber(_phoneNumberController.text.trim())) {
      _showDialog("Error", "Please enter a valid Indian phone number.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      GeoPoint? currentLocation = await _getCurrentLocation();
      if (currentLocation == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_profileImage != null) {
          await _uploadImage();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': widget.email,
          'phone_number': _phoneNumberController.text.trim(),
          'role': _selectedRole,
          'location': currentLocation,
          'profile_image_url': _profileImageUrl,
          'profileComplete': true,
          'status': 'enabled',
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showDialog("Error", "Failed to save profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Complete Your Profile"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null ? Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).primaryColor) : null,
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
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      hint: Text('Select Your Role'),
                      items: <String>['Player', 'Turf Owner'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : saveUserProfile,
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text("Save Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
      await _uploadImage();
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
      _showDialog("Error", "Failed to upload image: $e");
    }
  }
}
