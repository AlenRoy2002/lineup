// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, use_super_parameters, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:lineup/intro_pages/intro_page1.dart';
import 'package:lineup/intro_pages/intro_page2.dart';
import 'package:lineup/intro_pages/intro_page3.dart';
import 'package:lineup/pages/auth_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 2);
              });
            },
            children: [IntroPage1(), IntroPage2(), IntroPage3()],
          ),
          Container(
            alignment: const Alignment(0, 0.85),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.jumpToPage(2);
                  },
                  child: Text('Skip', style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
                SmoothPageIndicator(controller: _controller, count: 3),
                onLastPage
                    ? TextButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('showOnboarding', false);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => AuthPage()),
                          );
                        },
                        child: Text('Done', style: TextStyle(color: Theme.of(context).primaryColor)),
                      )
                    : TextButton(
                        onPressed: () {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Text('Next', style: TextStyle(color: Theme.of(context).primaryColor)),
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }
}