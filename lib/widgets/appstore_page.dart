import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets.dart';

class AppStoreRedirectPage extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppStoreRedirectPage({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(),
        Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: buildRedirectWidgets(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildRedirectWidgets(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(
            height: 200,
            child: Image(
              image: AssetImage('images/The IPN Logo.png'),
              fit: BoxFit.contain,
            ),
          ),
          const Text(
            'Download our app for the optimal experience!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
              launch('https://apps.apple.com/app/id6450196166');
            },
            child: SizedBox(
              height: 150,
              child: Image.asset(
                'images/app_store.png',
              ),
            ),
          ),
          InkWell(
            onTap: () {
              launch(
                  'https://play.google.com/store/apps/details?id=com.ipn.ipn_mobile_app');
            },
            child: SizedBox(
              height: 120,
              child: Image.asset(
                'images/google_play.png',
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (context) => const InitialPage(),
              ));
            },
            child: const Text('or, continue to web version',
                style: TextStyle(
                    fontSize: 18, color: Color.fromARGB(255, 102, 79, 161))),
          ),
        ],
      ),
    );
  }
}
