// ignore_for_file: prefer_const_constructors, use_super_parameters

import 'package:flutter/material.dart';

class IntroPage2 extends StatelessWidget {
  const IntroPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 120, color: Colors.green[800]),
            SizedBox(height: 50),
            Text(
              'Easy Booking',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Book your favorite turf with just a few taps',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.green[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}