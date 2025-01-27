// ignore_for_file: unused_import, prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, prefer_const_constructors, sort_child_properties_last, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lineup/pages/slot_booking_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TurfViewPage extends StatefulWidget {
  final Map<String, dynamic> turfData;
  final String userId;
  final String turfId;
  final Map<String, dynamic> userData;

  TurfViewPage({
    required this.turfData,
    required this.userId,
    required this.turfId,
    required this.userData,
  });

  @override
  _TurfViewPageState createState() => _TurfViewPageState();
}

class _TurfViewPageState extends State<TurfViewPage> {
  @override
  void initState() {
    super.initState();
    print('Debug - TurfViewPage initialized with turfId: ${widget.turfId}');
    // Verify the turf data
    print('Debug - Turf Data: ${widget.turfData}');
    print('Debug - TurfId from widget: ${widget.turfId}');
    // Also print the full turf data to verify
    print('Debug - Full turf data: ${widget.turfData}');
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.turfData['name'] ?? 'Turf Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(widget.turfData['images']),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.turfData['name'] ?? 'Unknown', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  _buildSectionTitle('Owner Details'),
                  _buildInfoRow(Icons.person, 'Owner Name', widget.turfData['owner_name'] ?? 'Unknown'),
                  _buildInfoRow(Icons.phone, 'Phone Number', widget.turfData['owner_phone'] ?? 'Unknown'),
                  SizedBox(height: 20),
                  _buildSectionTitle('Location'),
                  FutureBuilder<String>(
                    future: _getAddressFromLatLng(widget.turfData['location']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      return Text(snapshot.data ?? 'Address not found');
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openMap(widget.turfData['location']),
                    icon: Icon(Icons.map),
                    label: Text('Open in Maps'),
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle('Available Sports'),
                  _buildSportsGrid(widget.turfData['sports_categories']),
                  SizedBox(height: 20),
                  _buildSectionTitle('Amenities'),
                  _buildAmenitiesGrid(widget.turfData['amenities']),
                  SizedBox(height: 20),
                  _buildSectionTitle('Prices'),
                  ...(widget.turfData['boxes'] as List).map((box) => 
                    _buildInfoCard('Box ${box['number']}', '₹${box['price']}')
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle('Operating Hours'),
                  Text(
                    '${_formatTime(widget.turfData['start_time'])} - ${_formatTime(widget.turfData['end_time'])}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  SizedBox(height: 20),
                  _buildSectionTitle('Reviews'),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('turfId', isEqualTo: widget.turfId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      print('Debug - Query Parameters:');
                      print('Turf Name being queried: ${widget.turfData['name']}');
                      print('Connection State: ${snapshot.connectionState}');
                      
                      if (snapshot.hasData) {
                        print('Number of reviews found: ${snapshot.data!.docs.length}');
                        snapshot.data!.docs.forEach((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          print('Review Data: $data');
                        });
                      }

                      if (snapshot.hasError) {
                        print('Error in query: ${snapshot.error}');
                        return Center(child: Text('Error loading reviews'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final reviews = snapshot.data?.docs ?? [];

                      return Column(
                        children: [
                          if (reviews.isNotEmpty) _buildAverageRating(reviews),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: reviews.isEmpty ? 1 : reviews.length,
                            itemBuilder: (context, index) {
                             if (reviews.isEmpty) {
                                return Card(
                                  margin: EdgeInsets.all(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No reviews yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Be the first to review this turf!',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final reviewData = reviews[index].data() as Map<String, dynamic>;
                              return _buildReviewCard(reviewData);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        print('Debug: Turf ID being passed: ${widget.turfId}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SlotBookingPage(
                              turfData: widget.turfData,
                              turfId: widget.turfId,
                              userId: widget.userId,
                              userData: widget.userData,
                            ),
                          ),
                        );
                      },
                      child: Text('Book Slot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    
  }

  Widget _buildImageSlider(List<dynamic> images) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16/9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        viewportFraction: 0.8,
      ),
      items: images.map((image) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: Colors.grey,
              ),
              child: Image.network(image, fit: BoxFit.cover),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (label == 'Phone Number')
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _makePhoneCall(value),
                ),
                IconButton(
                  icon: Icon(Icons.message, color: Colors.green),
                  onPressed: () => _openWhatsApp(value),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call')),
      );
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters from the phone number
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Add the country code if it's not already there (assuming Indian numbers)
    if (!cleanedNumber.startsWith('91')) {
      cleanedNumber = '91$cleanedNumber';
    }

    var whatsappUrl = "https://wa.me/$cleanedNumber";
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsGrid(List<dynamic> sports) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: sports.length,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getSportIcon(sports[index]), size: 40),
              SizedBox(height: 8),
              Text(sports[index], textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmenitiesGrid(List<dynamic> amenities) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: amenities.length,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getAmenityIcon(amenities[index]), size: 40),
              SizedBox(height: 8),
              Text(amenities[index], textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football': return Icons.sports_soccer;
      case 'cricket': return Icons.sports_cricket;
      case 'basketball': return Icons.sports_basketball;
      case 'tennis': return Icons.sports_tennis;
      default: return Icons.sports;
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'parking': return Icons.local_parking;
      case 'changing rooms': return Icons.wc;
      case 'floodlights': return Icons.lightbulb;
      case 'refreshments': return Icons.local_cafe;
      default: return Icons.star;
    }
    
  }
  

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

  Future<void> _openMap(dynamic location) async {
    if (location == null) {
      print('Error: Location is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location data is not available')),
      );
      return;
    }

    double? latitude;
    double? longitude;

    if (location is GeoPoint) {
      latitude = location.latitude;
      longitude = location.longitude;
    } else if (location is Map<String, dynamic>) {
      latitude = location['latitude'] as double?;
      longitude = location['longitude'] as double?;
    }

    if (latitude == null || longitude == null) {
      print('Error: Invalid location data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid location data')),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    print('Attempting to launch URL: $url');

    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        print('Error: Could not launch $url');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map')),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while opening the map')),
      );
    }
  }

  Widget _buildAverageRating(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) return SizedBox.shrink();

    double totalRating = 0;
    reviews.forEach((doc) {
      final review = doc.data() as Map<String, dynamic>;
      totalRating += review['rating'] ?? 0;
    });

    double averageRating = totalRating / reviews.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Average Rating',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RatingBarIndicator(
                  rating: averageRating,
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 24.0,
                ),
                SizedBox(width: 8),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          (review['userName'] ?? 'A')[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          review['userName'] ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review['createdAt']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                RatingBarIndicator(
                  rating: (review['rating'] ?? 0).toDouble(),
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20.0,
                ),
                SizedBox(width: 8),
                Text(
                  (review['rating'] ?? 0).toString(),
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (review['review']?.isNotEmpty ?? false) ...[
              SizedBox(height: 12),
              Text(
                review['review'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('MMM d, yyyy').format(date.toDate());
    }
    return '';
  }
}


