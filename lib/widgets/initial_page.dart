import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widgets.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  _InitialPageState createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage>
    with SingleTickerProviderStateMixin {
  _launchURL() async {
    const url = 'https://www.intercollegiatepsychedelics.net';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Scrollbar(
                      thickness: 8.0,
                      radius: const Radius.circular(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 500,
                              child:
                                  Image.asset('images/Whte Logo Variation.png'),
                            ),
                            const SizedBox(height: 50),
                            const Text(
                              'Empowering, developing, and connecting the next generation of the psychedelic ecosystem.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              height: 60,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      const Color.fromARGB(255, 101, 79, 161),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: const Text(
                                  'Join now',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 60,
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      const Color.fromARGB(255, 117, 91, 188),
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 101, 79, 161),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _launchURL,
                              child: const Text(
                                'Learn more about IPN',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPage()),
                                );
                              },
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
