// ignore_for_file: prefer_const_constructors, use_super_parameters

import 'package:flutter/material.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/lineupLogo.png', height: 150),
            SizedBox(height: 50),
            Text(
              'Welcome to LineUp',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[600]),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your ultimate turf booking platform',
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