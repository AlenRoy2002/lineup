// ignore_for_file: unused_import, unnecessary_import, unnecessary_const, prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api, use_build_context_synchronously, sort_child_properties_last, avoid_print

import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lineup/components/my_textfield.dart';
import 'package:lineup/components/my_button.dart';
import 'package:lineup/components/square_tile.dart';
import 'package:lineup/pages/otp_screen.dart';

import 'package:lineup/services/auth_services.dart';
import 'package:lineup/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class Registerpage extends StatefulWidget {
  final Function()? onTap;
  Registerpage({super.key, required this.onTap});

  @override
  _RegisterpageState createState() => _RegisterpageState();
}

// ignore: unused_element
class _RegisterpageState extends State<Registerpage> {
  // text editing controllers
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isLoadingPhone = false;

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return false;
    } else if (!EmailValidator.validate(email)) {
      setState(() => emailError = "Please enter a valid email");
      return false;
    }
    setState(() => emailError = null);
    return true;
  }

  bool validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      return false;
    } else if (password.length < 8) {
      setState(
          () => passwordError = "Password must be at least 8 characters long");
      return false;
    }
    // You can add more password criteria here (e.g., requiring uppercase, lowercase, numbers, special characters)
    setState(() => passwordError = null);
    return true;
  }

  bool validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Please confirm your password");
      return false;
    } else if (password != confirmPassword) {
      setState(() => confirmPasswordError = "Passwords don't match");
      return false;
    }
    setState(() => confirmPasswordError = null);
    return true;
  }

  // sign user in method
  void signUserUp() async {
    // Validate all fields
    bool isEmailValid = validateEmail(emailController.text);
    bool isPasswordValid = validatePassword(passwordController.text);
    bool isConfirmPasswordValid = validateConfirmPassword(
        passwordController.text, confirmpasswordController.text);

    // If all validations pass, proceed with sign up
    if (isEmailValid && isPasswordValid && isConfirmPasswordValid) {
      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        Navigator.pop(context);
        showVerificationMessage();
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        showErrorMessage(e.code);
      }
    }
  }

  void initiatePhoneLogin() {
    setState(() {
      isLoadingPhone = true;
    });
    _authService.verifyPhoneNumber(
      phoneNumber: phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() {
          isLoadingPhone = false;
        });
        await _authService.signInWithPhoneCredential(credential);
        // Navigate to home page or do post-login actions
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isLoadingPhone = false;
        });
        showErrorMessage(e.message ?? "Verification failed");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          isLoadingPhone = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              verificationId: verificationId,
              phoneNumber: phoneController.text,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          isLoadingPhone = false;
        });
        // Handle timeout
      },
    );
  }

  void showVerificationMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Your Email'),
        content: Text(
            'A verification email has been sent to ${emailController.text}. Please verify your email before logging in.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showErrorMessage(String message) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.deepPurple,
            title: Center(
                child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            )),
          );
        });
  }

  void showPhoneDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Phone Number"),
          content: TextField(
            controller: phoneController,
            decoration: InputDecoration(
              hintText: "+1234567890",
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Send OTP"),
              onPressed: () {
                if (phoneController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  initiatePhoneLogin();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a phone number")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
@override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'images/lineupLogo.png',
                    height: 120,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Let's get you set up",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 30),
                  // Email field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                      hintText: 'Email',
                      errorText: emailError,
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    onChanged: (value) => validateEmail(value),
                  ),
                  SizedBox(height: 15),
                  // Password field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                      hintText: 'Password',
                      errorText: passwordError,
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    onChanged: (value) => validatePassword(value),
                  ),
                  SizedBox(height: 15),
                  // Confirm Password field
                  TextField(
                    controller: confirmpasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                      hintText: 'Confirm Password',
                      errorText: confirmPasswordError,
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                    onChanged: (value) => validateConfirmPassword(passwordController.text, value),
                  ),
                  SizedBox(height: 15),
                  // Sign Up button
                  ElevatedButton(
                    onPressed: signUserUp,
                    child: Text('Sign Up', style: TextStyle(fontSize: 18)),
                    style: Theme.of(context).elevatedButtonTheme.style,
                  ),
                  SizedBox(height: 30),
                  // Or continue with
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("Or continue with", style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Google sign-up
                  ElevatedButton.icon(
                    onPressed: () => AuthService().signInWithGoogle(),
                    icon: Image.asset('images/google.png', height: 24),
                    label: Text('Sign up with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: showPhoneDialog,
                    icon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                    label: Text('Sign up with Phone Number'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Login now
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          "Login Now",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
