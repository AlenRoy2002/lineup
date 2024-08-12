// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lineup/theme/theme_provider.dart';
import 'package:provider/provider.dart';

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
  final _localPlaceController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _locationError;
  File? _profileImage;
  String? _profileImageUrl;

  String? _countryValue;
  String? _stateValue;
  String? _cityValue;

  @override
  void initState() {
    super.initState();
    _populateFields();
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

  void _populateFields() {
    _nameController.text = widget.userData['name'] ?? '';
    _phoneNumberController.text = widget.userData['phone_number'] ?? '';
    _localPlaceController.text = widget.userData['local_place'] ?? '';
    _countryValue = widget.userData['country'];
    _stateValue = widget.userData['state'];
    _cityValue = widget.userData['city'];
    _profileImageUrl = widget.userData['profile_image_url'];
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
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to upload image: $e");
      rethrow;
    }
  }

  Future<void> _updateProfile() async {
    _validateName();
    _validatePhone();
    _validateLocalPlace();

    if (_nameError != null || _phoneError != null || _locationError != null ||
        _countryValue == null || _stateValue == null || _cityValue == null) {
      _showErrorDialog("Please fill all fields correctly.");
      return;
    }

    try {
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
          'country': _countryValue,
          'state': _stateValue,
          'city': _cityValue,
          'local_place': _localPlaceController.text.trim(),
        });

        widget.onProfileUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog("Failed to update profile: $e");
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
                currentCountry: _countryValue,
                currentState: _stateValue,
                currentCity: _cityValue,
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
                onPressed: _updateProfile,
                child: Text('Save Changes'),
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
}