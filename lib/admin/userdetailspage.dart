import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late String userStatus;
  String locationName = 'Loading...';
  String? turfName;

  @override
  void initState() {
    super.initState();
    userStatus = widget.userData['status'] ?? 'enabled';
    _getLocationName();
    if (widget.userData['role'] == 'Turf Owner') {
      _fetchTurfName();
    }
  }

  Future<void> _getLocationName() async {
    try {
      GeoPoint location = widget.userData['location'];
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          locationName = '${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      print('Error getting location name: $e');
      setState(() {
        locationName = 'Unknown location';
      });
    }
  }

  Future<void> _fetchTurfName() async {
    try {
      QuerySnapshot turfSnapshot = await FirebaseFirestore.instance
          .collection('turfs')
          .where('users', isEqualTo: widget.userData['uid'])
          .limit(1)
          .get();

      if (turfSnapshot.docs.isNotEmpty) {
        setState(() {
          turfName = turfSnapshot.docs.first['name'];
        });
      }
    } catch (e) {
      print('Error fetching turf name: $e');
    }
  }

  Future<void> _toggleUserStatus() async {
    if (userStatus == 'enabled') {
      _showDeactivationDialog();
    } else {
      await _updateUserStatus('enabled');
    }
  }

  Future<void> _showDeactivationDialog() async {
    String? reason;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Deactivate User'),
          content: TextField(
            onChanged: (value) {
              reason = value;
            },
            decoration: InputDecoration(hintText: "Enter reason for deactivation"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Deactivate'),
              onPressed: () async {
                if (reason != null && reason!.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateUserStatus('disabled', reason: reason);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a reason for deactivation')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserStatus(String newStatus, {String? reason}) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      if (reason != null) {
        updateData['deactivation_reason'] = reason;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userData['uid'])
          .update(updateData);

      setState(() {
        userStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus == 'enabled' ? 'User Activated' : 'User Deactivated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage(widget.userData['profile_image_url'] ?? 'https://via.placeholder.com/150'),
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(height: 16),
            Text(
              widget.userData['name'] ?? 'Unknown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildInfoCard(Icons.email, 'Email', widget.userData['email']),
            _buildInfoCard(Icons.phone, 'Phone', widget.userData['phone_number']),
            _buildInfoCard(Icons.work, 'Role', widget.userData['role']),
            if (widget.userData['role'] == 'Turf Owner' && turfName != null)
              _buildInfoCard(Icons.sports_soccer, 'Turf Name', turfName!),
            _buildInfoCard(Icons.location_on, 'Location', locationName),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleUserStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: userStatus == 'disabled' ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                userStatus == 'disabled' ? 'Activate' : 'Deactivate',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String? value) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? 'N/A', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
