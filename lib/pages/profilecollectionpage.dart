// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, sort_child_properties_last

import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final _localPlaceController = TextEditingController();
  String? _userRole;
  String? _roleError;
  File? _profileImage;
  String? _profileImageUrl;

  String? _countryValue;
  String? _stateValue;
  String? _cityValue;
  String? _nameError;
  String? _phoneError;
  String? _locationError;

  bool _isLoading = false; // Flag for loading state

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _phoneNumberController.addListener(_validatePhone);
    _localPlaceController.addListener(_validateLocalPlace);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _phoneNumberController.removeListener(_validatePhone);
    _localPlaceController.removeListener(_validateLocalPlace);
    _nameController.dispose();
    _phoneNumberController.dispose();
    _localPlaceController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      if (_nameController.text.trim().isEmpty || !RegExp(r'^[a-zA-Z ]+$').hasMatch(_nameController.text.trim())) {
        _nameError = "Please enter a valid name containing only alphabets.";
      } else {
        _nameError = null;
      }
    });
  }

  void _validatePhone() {
    setState(() {
      if (_phoneNumberController.text.trim().isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneNumberController.text.trim())) {
        _phoneError = "Please enter a valid 10-digit Indian phone number.";
      } else {
        _phoneError = null;
      }
    });
  }

  void _validateLocalPlace() {
    setState(() {
      if (_localPlaceController.text.trim().isEmpty) {
        _locationError = "Local place is required.";
      } else {
        _locationError = null;
      }
    });
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

  Future<void> saveUserProfile() async {
    _validateName();
    _validatePhone();
    _validateLocalPlace();

    if (_nameError != null || _phoneError != null || _locationError != null ||
        _userRole == null || _countryValue == null || _stateValue == null || _cityValue == null) {
      _showDialog("Error", "Please fill all fields correctly.");
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _uploadImage();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': widget.email,
          'phone_number': _phoneNumberController.text.trim(),
          'role': _userRole,
          'country': _countryValue,
          'state': _stateValue,
          'city': _cityValue,
          'local_place': _localPlaceController.text.trim(),
          'profile_image_url': _profileImageUrl,
          'profileComplete': true,
          'status': 'enabled',
        });

        // Navigate to the Homepage and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
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
      _showDialog("Error", "Failed to upload image: $e");
      rethrow;
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
                    errorText: _nameError,
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                    hintText: 'Phone Number',
                    errorText: _phoneError,
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: TextEditingController(text: widget.email),
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                    hintText: 'Email',
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _userRole,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.group, color: Theme.of(context).primaryColor),
                    hintText: 'Select Role',
                    errorText: _roleError,
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  items: [
                    DropdownMenuItem(
                      value: 'Player',
                      child: Text('Player'),
                    ),
                    DropdownMenuItem(
                      value: 'Turf Owner',
                      child: Text('Turf Owner'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _userRole = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                CSCPicker(
                  showStates: true,
                  showCities: true,
                  flagState: CountryFlag.DISABLE,
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                  disabledDropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: Colors.grey.shade300,
                  ),
                  selectedItemStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  dropdownHeadingStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  dropdownItemStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  dropdownDialogRadius: 10.0,
                  searchBarRadius: 10.0,
                  countrySearchPlaceholder: "Country",
                  stateSearchPlaceholder: "State",
                  citySearchPlaceholder: "City",
                  countryDropdownLabel: "*Country",
                  stateDropdownLabel: "*State",
                  cityDropdownLabel: "*City",
                  countryFilter: [CscCountry.India],
                  onCountryChanged: (value) {
                    setState(() {
                      _countryValue = value;
                    });
                  },
                  onStateChanged: (value) {
                    setState(() {
                      _stateValue = value;
                    });
                  },
                  onCityChanged: (value) {
                    setState(() {
                      _cityValue = value;
                    });
                  },
                ),
                if (_countryValue == null || _stateValue == null || _cityValue == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Please select your country, state, and city.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                SizedBox(height: 20),
                TextField(
                  controller: _localPlaceController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_city, color: Theme.of(context).primaryColor),
                    hintText: 'Local Place',
                    errorText: _locationError,
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
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
}
