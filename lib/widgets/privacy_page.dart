import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  _PrivacyPageState createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  Future<String> getPolicyText() async {
    return await rootBundle.loadString('assets/privacy_policy.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 33, 36),
        titleTextStyle: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255),
          fontSize: 18.h,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 30, 33, 36),
      body: FutureBuilder(
        future: getPolicyText(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Html(data: snapshot.data!),
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading privacy policy."));
          }
          return const Center(child: LinearProgressIndicator());
        },
      ),
    );
  }
}
