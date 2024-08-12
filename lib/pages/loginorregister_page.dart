// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:lineup/pages/login.dart';
import 'package:lineup/pages/registerpage.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage=true;

  void togglePages()
  {
    setState(() {
      showLoginPage=!showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage){
      return Login(
        onTap: togglePages,
      );
    }else{
      return Registerpage(
        onTap: togglePages,
      );
    }
  }
}