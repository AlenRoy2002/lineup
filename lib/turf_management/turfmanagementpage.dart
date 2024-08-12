// ignore_for_file: prefer_const_constructors, sort_child_properties_last, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'dart:io';

import 'package:csc_picker/csc_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class TurfHomePage extends StatelessWidget {
  final String userId;

  TurfHomePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Turf Management')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildCard(context, 'Turf Profile', Icons.business, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TurfProfilePage(userId: userId)),
            );
          }),
          _buildCard(context, 'Manage Bookings', Icons.calendar_today, () {
            // Navigate to Manage Bookings page
          }),
          _buildCard(context, 'Financial Reports', Icons.bar_chart, () {
            // Navigate to Financial Reports page
          }),
          _buildCard(context, 'Settings', Icons.settings, () {
            // Navigate to Settings page
          }),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class TurfProfilePage extends StatefulWidget {
  final String userId;

  TurfProfilePage({required this.userId});

  @override
  _TurfProfilePageState createState() => _TurfProfilePageState();
}

class _TurfProfilePageState extends State<TurfProfilePage> {
  late Future<DocumentSnapshot> _turfFuture;

  @override
  void initState() {
    super.initState();
    _turfFuture = FirebaseFirestore.instance.collection('turfs').doc(widget.userId).get();
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Turf Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _turfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return TurfManagementPage(userId: widget.userId);
          }

          Map<String, dynamic> turfData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turfData['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                _buildInfoCard('Rate per Hour', '₹${turfData['rate_per_hour']}'),
                _buildInfoCard('Country', turfData['country'] ?? 'N/A'),
                _buildInfoCard('State', turfData['state'] ?? 'N/A'),
                _buildInfoCard('City', turfData['city'] ?? 'N/A'),
                _buildInfoCard('Status', turfData['status']),
                SizedBox(height: 20),
                Text('Turf Images:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: (turfData['images'] as List).length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(turfData['images'][index], fit: BoxFit.cover),
                    );
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTurfProfilePage(userId: widget.userId, turfData: turfData),
                      ),
                    ).then((_) {
                      setState(() {
                        _turfFuture = FirebaseFirestore.instance.collection('turfs').doc(widget.userId).get();
                      });
                    });
                  },
                  child: Text('Edit Turf Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EditTurfProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> turfData;

  EditTurfProfilePage({required this.userId, required this.turfData});

  @override
  _EditTurfProfilePageState createState() => _EditTurfProfilePageState();
}

class _EditTurfProfilePageState extends State<EditTurfProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  String? _countryValue;
  String? _stateValue;
  String? _cityValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.turfData['name']);
    _rateController = TextEditingController(text: widget.turfData['rate_per_hour'].toString());
    _countryValue = widget.turfData['country'];
    _stateValue = widget.turfData['state'];
    _cityValue = widget.turfData['city'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _updateTurf() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('turfs').doc(widget.userId).update({
          'name': _nameController.text,
          'rate_per_hour': double.parse(_rateController.text),
          'country': _countryValue,
          'state': _stateValue,
          'city': _cityValue,
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update turf: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Turf Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Turf Name*'),
                validator: (value) => value!.isEmpty ? 'Please enter turf name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _rateController,
                decoration: InputDecoration(labelText: 'Rate per Hour*'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter rate per hour';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 20),
              CSCPicker(
                showStates: true,
                showCities: true,
                flagState: CountryFlag.DISABLE,
                countryFilter: [CscCountry.India],
                countrySearchPlaceholder: "Country",
                stateSearchPlaceholder: "State",
                citySearchPlaceholder: "City",
                countryDropdownLabel: "*Country",
                stateDropdownLabel: "*State",
                cityDropdownLabel: "*City",
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
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: isDarkMode ? Colors.grey[700] : Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                disabledDropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
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
              ElevatedButton(
                onPressed: _updateTurf,
                child: Text('Update Turf Profile'),
                style: ElevatedButton.styleFrom(
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
class TurfManagementPage extends StatefulWidget {
  final String userId;

  TurfManagementPage({required this.userId});

  @override
  _TurfManagementPageState createState() => _TurfManagementPageState();
}

class _TurfManagementPageState extends State<TurfManagementPage> {
  List<File?> _turfImages = List.filled(4, null);
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  
  String? _countryValue;
  String? _stateValue;
  String? _cityValue;

  bool _isLoading = false;

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _turfImages[index] = File(pickedFile.path);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (int i = 0; i < _turfImages.length; i++) {
      if (_turfImages[i] != null) {
        String fileName = 'turf_${widget.userId}_$i.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('turf_images/$fileName');
        await ref.putFile(_turfImages[i]!);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<void> _addTurf() async {
    if (_formKey.currentState!.validate()) {
      if (_countryValue == null || _stateValue == null || _cityValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select country, state, and city')),
        );
        return;
      }
      if (_turfImages.where((image) => image != null).length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload all 4 turf images')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        List<String> imageUrls = await _uploadImages();
        await FirebaseFirestore.instance.collection('turfs').doc(widget.userId).set({
          'name': _nameController.text,
          'rate_per_hour': double.parse(_rateController.text),
          'country': _countryValue,
          'state': _stateValue,
          'city': _cityValue,
          'images': imageUrls,
          'status': 'pending',
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add turf: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('Add Your Turf')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Turf Name*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter turf name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _rateController,
                decoration: InputDecoration(labelText: 'Rate per Hour*'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rate per hour';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              CSCPicker(
                showStates: true,
                showCities: true,
                flagState: CountryFlag.DISABLE,
                countryFilter: [CscCountry.India],
                countrySearchPlaceholder: "Country",
                stateSearchPlaceholder: "State",
                citySearchPlaceholder: "City",
                countryDropdownLabel: "*Country",
                stateDropdownLabel: "*State",
                cityDropdownLabel: "*City",
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
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: isDarkMode ? Colors.grey[700] : Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                disabledDropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
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
              Text('Upload Turf Images (4 sides)*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _turfImages[index] == null
                          ? Icon(Icons.add_a_photo, size: 50)
                          : Image.file(_turfImages[index]!, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _addTurf,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Add Your Turf'),
                style: ElevatedButton.styleFrom(
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