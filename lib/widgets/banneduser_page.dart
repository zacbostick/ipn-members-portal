import 'package:flutter/material.dart';
import './home_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportButton extends StatelessWidget {
  const ContactSupportButton({super.key});

  void _launchURL() async {
    const url = 'https://www.intercollegiatepsychedelics.net/contact-us/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _launchURL,
      child: const Text('Contact Support'),
    );
  }
}

class BannedUserPage extends StatelessWidget {
  const BannedUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: const Color.fromARGB(255, 30, 33, 36),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the home page
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: const Color.fromARGB(255, 44, 47, 51),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.block,
              size: 100,
              color: Colors.red[700],
            ),
            const SizedBox(height: 20),
            const Text(
              'You have been banned from the chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'If you believe this is a mistake, please contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            const ContactSupportButton(),
          ],
        ),
      ),
    );
  }
}
