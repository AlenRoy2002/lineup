// ignore_for_file: prefer_const_constructors, sort_child_properties_last, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, prefer_final_fields, unused_import, use_build_context_synchronously, library_private_types_in_public_api, sized_box_for_whitespace, prefer_conditional_assignment, unused_field, depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:lineup/turf_management/manage_bookings_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lineup/turf_management/financial_report.dart';

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
             _buildCard(context, 'Turf Profile', Icons.business, () async {
            DocumentSnapshot turfDoc = await FirebaseFirestore.instance.collection('turfs').doc(userId).get();
            if (turfDoc.exists) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TurfDetailsPage(userId: userId)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TurfManagementPage(userId: userId)),
              );
            }
          }),
          _buildCard(context, 'Manage Bookings', Icons.calendar_today, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageBookingsPage(turfId: userId),
              ),
            );
          }),
          _buildCard(context, 'Financial Reports', Icons.bar_chart, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinancialReportPage(userId: userId, turfId: userId),
              ),
            );
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

class TurfDetailsPage extends StatelessWidget {
  final String userId;

  TurfDetailsPage({required this.userId});

  Future<String> _getAddressFromLatLng(GeoPoint location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
    } catch (e) {
      print('Error: $e');
    }
    return 'Address not found';
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dateTime = DateTime(2022, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Turf Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('turfs').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          Map<String, dynamic> turfData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSlider(turfData['images']),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turfData['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _buildSectionTitle('Location'),
                      FutureBuilder<String>(
                        future: _getAddressFromLatLng(turfData['location']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          return Text(snapshot.data ?? 'Address not found');
                        },
                      ),
                      SizedBox(height: 16),
                      _buildSectionTitle('Available Sports'),
                      Wrap(
                        spacing: 8,
                        children: (turfData['sports_categories'] as List).map((sport) => Chip(label: Text(sport))).toList(),
                      ),
                      SizedBox(height: 16),
                      _buildSectionTitle('Amenities'),
                      Wrap(
                        spacing: 8,
                        children: (turfData['amenities'] as List).map((amenity) => Chip(label: Text(amenity))).toList(),
                      ),
                      SizedBox(height: 16),
                      _buildSectionTitle('Prices'),
                      ...(turfData['boxes'] as List).map((box) => Text('Box ${box['number']}: ₹${box['price']}')),
                      SizedBox(height: 16),
                      _buildSectionTitle('Operating Hours'),
                      Text('${_formatTime(turfData['start_time'])} - ${_formatTime(turfData['end_time'])}'),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTurfProfilePage(userId: userId, turfData: turfData),
                            ),
                          );
                        },
                        child: Text('Edit Details'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSlider(List<dynamic> images) {
    return Container(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(images[index], fit: BoxFit.cover);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  late List<TextEditingController> _boxControllers;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  List<String> _selectedSports = [];
  List<String> _selectedAmenities = [];
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.turfData['name']);
    _boxControllers = (widget.turfData['boxes'] as List).map((box) => 
      TextEditingController(text: box['price'].toString())
    ).toList();
    _startTime = _parseTimeOfDay(widget.turfData['start_time']);
    _endTime = _parseTimeOfDay(widget.turfData['end_time']);
    _selectedSports = List<String>.from(widget.turfData['sports_categories']);
    _selectedAmenities = List<String>.from(widget.turfData['amenities']);
    _selectedLocation = LatLng(
      widget.turfData['location'].latitude,
      widget.turfData['location'].longitude
    );
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _boxControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateTurf() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('turfs').doc(widget.userId).update({
          'name': _nameController.text,
          'boxes': List.generate(_boxControllers.length, (index) => {
            'number': index + 1,
            'price': double.parse(_boxControllers[index].text),
          }),
          'start_time': '${_startTime.hour}:${_startTime.minute}',
          'end_time': '${_endTime.hour}:${_endTime.minute}',
          'sports_categories': _selectedSports,
          'amenities': _selectedAmenities,
          'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update turf: $e')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectLocationFromMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapSelectionPage(initialLocation: _selectedLocation)),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: 16),
              Text('Boxes and Prices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._boxControllers.asMap().entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: 'Box ${entry.key + 1} Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Please enter price' : null,
                  ),
                )
              ),
              SizedBox(height: 16),
              Text('Operating Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Start Time'),
                      readOnly: true,
                      controller: TextEditingController(text: _formatTimeOfDay(_startTime)),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'End Time'),
                      readOnly: true,
                      controller: TextEditingController(text: _formatTimeOfDay(_endTime)),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Sports Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: ['Cricket', 'Football', 'Basketball', 'Tennis'].map((sport) => 
                  FilterChip(
                    label: Text(sport),
                    selected: _selectedSports.contains(sport),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSports.add(sport);
                        } else {
                          _selectedSports.remove(sport);
                        }
                      });
                    },
                  )
                ).toList(),
              ),
              SizedBox(height: 16),
              Text('Amenities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: ['Parking', 'Food Court', 'Gallery', 'Sports Store', 'Changing Rooms', 'Floodlights', 'Refreshments'].map((amenity) => 
                  FilterChip(
                    label: Text(amenity),
                    selected: _selectedAmenities.contains(amenity),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  )
                ).toList(),
              ),
              SizedBox(height: 16),
              Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: _selectLocationFromMap,
                child: Text('Change Location'),
              ),
              if (_selectedLocation != null)
                Text('Selected: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'),
              SizedBox(height: 24),
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
  final _formKey = GlobalKey<FormState>();
  List<File?> _turfImages = List.filled(4, null);
  
  final _nameController = TextEditingController();
  
  final _licenseController = TextEditingController();
  File? _licenseFile;

  bool _isLoading = false;

  List<String> _selectedSports = [];
  List<Map<String, dynamic>> _boxes = [{'number': 1, 'price': ''}];

  TimeOfDay _startTime = TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 22, minute: 0);

  LatLng? _selectedLocation;

  List<String> _availableAmenities = ['Parking', 'Food Court', 'Gallery', 'Sports Store'];
  List<String> _selectedAmenities = [];

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

  Future<void> _pickLicense() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _licenseFile = File(pickedFile.path);
        _licenseController.text = pickedFile.path.split('/').last;
      });
    }
  }

  void _addBox() {
    setState(() {
      _boxes.add({'number': _boxes.length + 1, 'price': ''});
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _showLocationError('Location services are disabled. Please enable the services');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _showLocationError('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return _showLocationError('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError('Could not get current location: $e');
    }
  }

  void _showLocationError(String message) {
    print('Location Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectLocationFromMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapSelectionPage(initialLocation: _selectedLocation ?? LatLng(0, 0))),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Widget _buildLocationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: Text('Add Turf')),
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
              SizedBox(height: 20),
              Text('Turf Photos*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _turfImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _pickImage(index),
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: _turfImages[index] != null
                              ? DecorationImage(
                                  image: FileImage(_turfImages[index]!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _turfImages[index] == null
                            ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400])
                            : null,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text('License (JPG or PDF)*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: 'License File',
                        suffixIcon: Icon(Icons.attach_file),
                      ),
                      readOnly: true,
                      validator: (value) => value!.isEmpty ? 'Please upload license file' : null,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.upload_file),
                    onPressed: _pickLicense,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('Sports Categories*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  'Cricket',
                  'Football',
                  'Basketball',
                  'Hockey'
                ].map((sport) => FilterChip(
                  label: Text(sport),
                  selected: _selectedSports.contains(sport),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSports.add(sport);
                      } else {
                        _selectedSports.remove(sport);
                      }
                    });
                  },
                )).toList(),
              ),
              SizedBox(height: 20),
              Text('Boxes and Prices*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ..._boxes.map((box) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text('Box ${box['number']}'),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => box['price'] = value,
                        validator: (value) => value!.isEmpty ? 'Please enter price' : null,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              ElevatedButton(
                onPressed: _addBox,
                child: Text('Add Another Box'),
              ),
              SizedBox(height: 20),
              Text('Operating Hours*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Start Time'),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startTime.format(context),
                      ),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'End Time'),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _endTime.format(context),
                      ),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('Turf Location*', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildLocationButton(
                      icon: Icons.my_location,
                      label: 'Current Location',
                      onPressed: _getCurrentLocation,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: _buildLocationButton(
                      icon: Icons.map,
                      label: 'Choose from Map',
                      onPressed: _selectLocationFromMap,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (_selectedLocation != null)
                AnimatedOpacity(
                  opacity: _selectedLocation != null ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Selected Location: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _availableAmenities.map((amenity) => FilterChip(
                  label: Text(amenity),
                  selected: _selectedAmenities.contains(amenity),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                )).toList(),
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

  Future<void> _addTurf() async {
    if (_formKey.currentState!.validate()) {
      if (_turfImages.where((image) => image != null).length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload all 4 turf images')),
        );
        return;
      }
      if (_selectedSports.isEmpty) {
        _showDialog('Error', 'Please select at least one sport category');
        return;
      }
      if (_licenseFile == null) {
        _showDialog('Error', 'Please upload a license file');
        return;
      }
      if (_boxes.any((box) => box['price'].isEmpty)) {
        _showDialog('Error', 'Please enter prices for all boxes');
        return;
      }
      if (_selectedLocation == null) {
        _showLocationError('Please select a location for your turf');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Fetch user data
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
        
        if (!userDoc.exists) {
          throw Exception('User data not found');
        }

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String ownerName = userData['name'] ?? 'Unknown';
        String ownerPhone = userData['phone_number'] ?? 'Unknown';

        List<String> imageUrls = await _uploadImages();
        String licenseUrl = await _uploadLicense();
        await FirebaseFirestore.instance.collection('turfs').doc(widget.userId).set({
          'name': _nameController.text,
          'images': imageUrls,
          'license_url': licenseUrl,
          'sports_categories': _selectedSports,
          'boxes': _boxes,
          'start_time': '${_startTime.hour}:${_startTime.minute}',
          'end_time': '${_endTime.hour}:${_endTime.minute}',
          'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
          'amenities': _selectedAmenities,
          'status': 'pending',
          'owner_name': ownerName,  // Add owner name
          'owner_phone': ownerPhone,  // Add owner phone
        });
        Navigator.pop(context);
      } catch (e) {
        _showDialog('Error', 'Failed to add turf: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadLicense() async {
    String fileName = 'license_${widget.userId}.${_licenseFile!.path.split('.').last}';
    Reference ref = FirebaseStorage.instance.ref().child('turf_licenses/$fileName');
    await ref.putFile(_licenseFile!);
    return await ref.getDownloadURL();
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
}

class MapSelectionPage extends StatefulWidget {
  final LatLng? initialLocation;

  MapSelectionPage({this.initialLocation});

  @override
  _MapSelectionPageState createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  LatLng? selectedLocation;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation ?? LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation!,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        onTap: (latLng) {
          setState(() {
            selectedLocation = latLng;
          });
        },
        markers: {
          if (selectedLocation != null)
            Marker(
              markerId: MarkerId('selectedLocation'),
              position: selectedLocation!,
            ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, selectedLocation);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}

// class FinancialReportPage extends StatefulWidget {
//   final String userId;

//   const FinancialReportPage({Key? key, required this.userId}) : super(key: key);

//   @override
//   _FinancialReportPageState createState() => _FinancialReportPageState();
// }

// class _FinancialReportPageState extends State<FinancialReportPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final storage = FlutterSecureStorage();
//   late Web3Client _web3client;
//   bool _isLoading = true;
//   Map<String, dynamic> _statistics = {};
//   List<Map<String, dynamic>> _transactions = [];
  
//   // Blockchain configuration
//   static const String _rpcUrl = 'YOUR_BLOCKCHAIN_RPC_URL';
//   static const String _contractAddress = 'YOUR_SMART_CONTRACT_ADDRESS';

//   @override
//   void initState() {
//     super.initState();
//     _initializeBlockchain();
//     _loadFinancialData();
//   }

//   Future<void> _initializeBlockchain() async {
//     final client = Client();
//     _web3client = Web3Client(_rpcUrl, client);
//   }

//   Future<void> _loadFinancialData() async {
//     try {
//       setState(() => _isLoading = true);

//       // Fetch booking statistics
//       final bookingStats = await _getBookingStatistics();
      
//       // Fetch payment records
//       final payments = await _getPaymentRecords();
      
//       // Fetch blockchain transactions
//       final blockchainData = await _getBlockchainTransactions();

//       setState(() {
//         _statistics = bookingStats;
//         _transactions = payments;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error loading financial data: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<Map<String, dynamic>> _getBookingStatistics() async {
//     final QuerySnapshot bookings = await _firestore
//         .collection('bookings')
//         .where('userId', isEqualTo: widget.userId)
//         .get();

//     double totalRevenue = 0;
//     Map<String, int> sportsCounts = {};
//     Map<String, double> monthlyRevenue = {};

//     for (var doc in bookings.docs) {
//       final data = doc.data() as Map<String, dynamic>;
//       final amount = data['totalAmount'] as double;
//       final sport = data['sport'] as String;
//       final date = (data['date'] as Timestamp).toDate();
//       final monthKey = DateFormat('MMM yyyy').format(date);

//       totalRevenue += amount;
//       sportsCounts[sport] = (sportsCounts[sport] ?? 0) + 1;
//       monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;
//     }

//     return {
//       'totalRevenue': totalRevenue,
//       'totalBookings': bookings.docs.length,
//       'sportsCounts': sportsCounts,
//       'monthlyRevenue': monthlyRevenue,
//     };
//   }

//   Future<List<Map<String, dynamic>>> _getPaymentRecords() async {
//     try {
//       final QuerySnapshot payments = await _firestore
//           .collection('bookings')
//           .where('userId', isEqualTo: widget.userId)
//           .where('status', isEqualTo: 'completed')
//           .orderBy('createdAt', descending: true)
//           .get();

//       return payments.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'bookingId': doc.id,
//           'amount': data['totalAmount'],
//           'date': data['createdAt'],
//           'transactionHash': data['transactionHash'],
//         };
//       }).toList();
//     } catch (e) {
//       print('Error fetching payment records: $e');
//       return [];
//     }
//   }

//   Future<List<Map<String, dynamic>>> _getBlockchainTransactions() async {
//     try {
//       // Implement your blockchain transaction fetching logic here
//       return [];
//     } catch (e) {
//       print('Error fetching blockchain transactions: $e');
//       return [];
//     }
//   }

//   void _showTransactionDetails(Map<String, dynamic> transaction) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Transaction Details'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Booking ID: ${transaction['bookingId']}'),
//             Text('Amount: ₹${transaction['amount']}'),
//             Text('Date: ${DateFormat('MMM d, yyyy').format(transaction['date'].toDate())}'),
//             SizedBox(height: 16),
//             _buildBlockchainVerification(transaction),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: Text('Close'),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<String> _verifyBlockchainTransaction(String? transactionHash) async {
//     if (transactionHash == null) return 'not verified';
    
//     try {
//       // Implement your blockchain verification logic here
//       return 'verified';
//     } catch (e) {
//       print('Error verifying blockchain transaction: $e');
//       return 'verification failed';
//     }
//   }

//   Widget _buildRevenueChart() {
//     final monthlyData = Map<String, double>.from(_statistics['monthlyRevenue'] ?? {});
    
//     return Container(
//       height: 300,
//       padding: EdgeInsets.all(16),
//       child: LineChart(
//         LineChartData(
//           gridData: FlGridData(show: true),
//           titlesData: FlTitlesData(
//             leftTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 40,
//                 getTitlesWidget: (value, _) => Text('₹${value.toInt()}'),
//               ),
//             ),
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 30,
//                 getTitlesWidget: (value, _) {
//                   final months = monthlyData.keys.toList();
//                   if (value.toInt() >= 0 && value.toInt() < months.length) {
//                     return Text(
//                       months[value.toInt()],
//                       style: TextStyle(fontSize: 12),
//                     );
//                   }
//                   return const Text('');
//                 },
//               ),
//             ),
//             topTitles: AxisTitles(
//               sideTitles: SideTitles(showTitles: false),
//             ),
//             rightTitles: AxisTitles(
//               sideTitles: SideTitles(showTitles: false),
//             ),
//           ),
//           lineBarsData: [
//             LineChartBarData(
//               spots: monthlyData.entries
//                   .map((e) => FlSpot(
//                       monthlyData.keys.toList().indexOf(e.key).toDouble(),
//                       e.value))
//                   .toList(),
//               isCurved: true,
//               color: Colors.blue,
//               dotData: FlDotData(show: true),
//               belowBarData: BarAreaData(show: false),
//             ),
//           ],
//           borderData: FlBorderData(
//             show: true,
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTransactionsList() {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: _transactions.length,
//       itemBuilder: (context, index) {
//         final transaction = _transactions[index];
//         return ListTile(
//           title: Text('Booking ID: ${transaction['bookingId']}'),
//           subtitle: Text(DateFormat('MMM d, yyyy').format(
//               transaction['date'].toDate())),
//           trailing: Text(
//             '₹${transaction['amount']}',
//             style: TextStyle(
//               color: Colors.green,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           onTap: () => _showTransactionDetails(transaction),
//         );
//       },
//     );
//   }

//   Widget _buildBlockchainVerification(Map<String, dynamic> transaction) {
//     return FutureBuilder<String>(
//       future: _verifyBlockchainTransaction(transaction['transactionHash']),
//       builder: (context, snapshot) {
//         return Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 snapshot.data == 'verified' 
//                     ? Icons.verified 
//                     : Icons.pending,
//                 color: snapshot.data == 'verified' 
//                     ? Colors.green 
//                     : Colors.orange,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Blockchain Status: ${snapshot.data ?? 'Verifying...'}',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Financial Report'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadFinancialData,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Summary Cards
//                   Row(
//                     children: [
//                       _buildSummaryCard(
//                         'Total Revenue',
//                         '₹${_statistics['totalRevenue']?.toStringAsFixed(2)}',
//                         Icons.monetization_on,
//                       ),
//                       _buildSummaryCard(
//                         'Total Bookings',
//                         '${_statistics['totalBookings']}',
//                         Icons.book_online,
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 24),
                  
//                   // Revenue Chart
//                   Text(
//                     'Revenue Trend',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   _buildRevenueChart(),
//                   SizedBox(height: 24),

//                   // Transactions List
//                   Text(
//                     'Recent Transactions',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   _buildTransactionsList(),
//                 ],
//               ),
//             ),
//     );
//   }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
