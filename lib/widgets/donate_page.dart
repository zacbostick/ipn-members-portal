import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  void _launchURL() async {
    const url = 'https://donorbox.org/support-ipn';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donate',
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        backgroundColor: const Color(0xFF1E2124),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.h, 0.0, 24.h, 24.h),
          child: Column(
            children: <Widget>[
              Image.asset(
                'images/Whte Logo Variation 2.png',
                height: 200.h,
                width: 200.w,
              ),
              Text(
                'Support IPN With a Donation!',
                style: TextStyle(
                  fontSize: 18.h,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'As a fully volunteer-led and student-run organization, we rely entirely on donations from our community to support our programming and operations. Your generosity enables us to make careers in psychedelics more accessible to students and young professionals.',
                style: TextStyle(
                  fontSize: 14.h,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFa064f4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 8.h),
                ),
                onPressed: _launchURL,
                child: Text(
                  'Donate Now',
                  style: TextStyle(
                    fontSize: 18.h,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
