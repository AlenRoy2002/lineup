// ignore_for_file: unused_import, prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lineup/pages/email_verification_page.dart';
import 'package:lineup/pages/login.dart';
import 'package:lineup/pages/homepage.dart';
import 'package:lineup/pages/loginorregister_page.dart';
import 'package:lineup/pages/profilecollectionpage.dart';


class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user!.emailVerified) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      var userData = snapshot.data!.data() as Map<String, dynamic>;
                      bool profileComplete = userData['profileComplete'] ?? false;

                      if (profileComplete) {
                        return Homepage();
                      } else {
                        return ProfileCollectionPage(email: user.email!);
                      }
                    } else {
                      return ProfileCollectionPage(email: user.email!);
                    }
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              );
            } else {
              return EmailVerificationPage();
            }
          } else {
            return LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
