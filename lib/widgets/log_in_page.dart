import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = await _storage.read(key: 'userEmail');
    final savedPassword = await _storage.read(key: 'userPassword');

    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe && savedEmail != null) {
        emailController.text = savedEmail;
      }
      if (rememberMe && savedPassword != null) {
        passwordController.text = savedPassword;
      }
    });
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);

    if (rememberMe) {
      await _storage.write(
          key: 'userEmail', value: emailController.text.trim());
      await _storage.write(key: 'userPassword', value: passwordController.text);
    } else {
      await _storage.delete(key: 'userEmail');
      await _storage.delete(key: 'userPassword');
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'userEmail', value: email);
    await _storage.write(key: 'userPassword', value: password);
  }

  Future<Map<String, String>> getSavedCredentials() async {
    String? email = await _storage.read(key: 'userEmail');
    String? password = await _storage.read(key: 'userPassword');
    return {
      'email': email ?? '',
      'password': password ?? '',
    };
  }

  Future<void> _login({String? email, String? password}) async {
    String loginEmail = email ?? emailController.text.trim();
    String loginPassword = password ?? passwordController.text;

    try {
      await _auth.signInWithEmailAndPassword(
          email: loginEmail, password: loginPassword);

      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Email Verification Required'),
            content: const Text('Please verify your email before proceeding.'),
            actions: [
              TextButton(
                child: const Text('Resend Email'),
                onPressed: () async {
                  await user.sendEmailVerification();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e);
      _showErrorDialog(context, message);
    } catch (e) {
      _showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided for this user.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  final LocalAuthentication auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 102, 79, 161),
                Color.fromARGB(255, 102, 79, 161),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: buildForm(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildForm(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200.h,
                  width: 200.h,
                  child: const Image(
                    image: AssetImage('images/Whte Logo Icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.h,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Enter your Email and Password Below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.h,
                    letterSpacing: 0.5,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 101, 79, 161),
                    ),
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 101, 79, 161),
                  ),
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 101, 79, 161),
                    ),
                    fillColor: const Color.fromARGB(255, 255, 255, 255),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 101, 79, 161),
                  ),
                  obscureText: true,
                ),
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8.h,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                    ),
                    Text(
                      'Remember Me',
                      style: TextStyle(color: Colors.white, fontSize: 14.h),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () async {
                    savePreferences();
                    await _login();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text('Login',
                      style: TextStyle(color: Colors.black, fontSize: 14.h)),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () => _showPasswordResetDialog(context),
                  child: Text('Forgot Password?',
                      style: TextStyle(color: Colors.white, fontSize: 14.h)),
                ),
                TextButton(
                  onPressed: () => _goBack(context),
                  child: Text('Go Back',
                      style: TextStyle(color: Colors.white, fontSize: 14.h)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController resetEmailController = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                    'Enter your email address. We will send a password reset link to this email.'),
                TextFormField(
                  controller: resetEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                resetPassword(resetEmailController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Reset password link has been sent to your email'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InitialPage()),
      );
    }
  }
}
