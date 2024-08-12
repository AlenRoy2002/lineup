// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, library_private_types_in_public_api, use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  late String userStatus;

  @override
  void initState() {
    super.initState();
    userStatus = widget.userData['status'] ?? 'enabled'; // Default to 'enabled' if status is null
  }

  Future<void> _toggleUserStatus() async {
    String newStatus = userStatus == 'enabled' ? 'disabled' : 'enabled';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userData['uid']) // Assuming `uid` is the document ID
          .update({'status': newStatus});

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Photo
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(widget.userData['profile_image_url'] ?? 'https://via.placeholder.com/150'),
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(height: 16),
            // User Name
            Text(
              widget.userData['name'] ?? 'Unknown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // User Information
            _buildUserInfo('Email', widget.userData['email']),
            _buildUserInfo('Role', widget.userData['role']),
            _buildUserInfo('City', widget.userData['city']),
            _buildUserInfo('District', widget.userData['district']),
            _buildUserInfo('State', widget.userData['state']),
            _buildUserInfo('Phone Number', widget.userData['phone_number']),
             _buildUserInfo('Status', widget.userData['status']),
            SizedBox(height: 32),
            // Activate/Deactivate Button
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
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              SizedBox(
                width: 120,
                child: Text(
                  '$label:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Value
              Expanded(
                child: Text(
                  value ?? 'N/A',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
