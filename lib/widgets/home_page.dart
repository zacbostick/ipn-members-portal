import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets.dart';
import './chat_widget.dart';
import 'dart:math';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:ipn_mobile_app/providers/user_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  _HomeContentPageState createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  void _removeBadge() {
    if (!kIsWeb) {
      FlutterAppBadger.removeBadge();
    } else {
      return;
    }
  }

  String getGreetingMessage(String firstName) {
    var hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    greeting += ',  $firstName';
    return greeting;
  }

  Map<String, WidgetBuilder> routes = {
    'Events': (context) => const EventsPage(),
    'Donate': (context) => const DonatePage(),
  };
  void launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  Widget buildGreetingSection(BuildContext context) {
    Color quaternaryColor = const Color(0xFF1E2124);
    Color tertiaryColor = const Color.fromARGB(255, 35, 37, 42);
    double baseWidth = 500.0;
    double baseHeight = 800.0;
    Size screenSize = MediaQuery.of(context).size;
    double widthScaleFactor = screenSize.width / baseWidth;
    double heightScaleFactor = screenSize.height / baseHeight;
    double scaleFactor = min(widthScaleFactor, heightScaleFactor);
    double avatarRadius = 32 * scaleFactor;
    double greetingFontSize = 26 * scaleFactor;
    double welcomeFontSize = 24 * scaleFactor;
    double hubFontSize = 18 * scaleFactor;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        String firstName = userProvider.getFirstName() ?? 'User';
        String? avatarUrl = userProvider.getAvatarUrl();
        String greetingMessage = getGreetingMessage(firstName);

        return ClipRRect(
          borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(50)),
          child: Container(
            width: baseWidth.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [quaternaryColor, tertiaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: baseWidth.w),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Icon(Icons.person, size: avatarRadius)
                                : null,
                          ),
                          SizedBox(width: 8.h),
                          Expanded(
                            child: Text(
                              greetingMessage,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: greetingFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to IPN!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: welcomeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your hub for connecting with peers, discovering events, and building your network. Let’s get started!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: hubFontSize,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Color quaternaryColor = const Color(0xFF1E2124);
    List<Map<String, dynamic>> quickAccessItems = [
      {
        'icon': Icons.event,
        'label': 'Events',
        'color': Colors.orange,
      },
      {
        'icon': Icons.volunteer_activism,
        'label': 'Donate',
        'color': Colors.red,
      },
      {
        'icon': Icons.folder,
        'label': 'Resources',
        'color': Colors.blue,
      },
      {
        'icon': Icons.badge,
        'label': 'Conferences',
        'color': Colors.green,
      },
      {
        'icon': Icons.cases_outlined,
        'label': 'Jobs',
        'color': Colors.purple,
      },
      {
        'icon': FontAwesomeIcons.tags,
        'label': 'Exclusives',
        'color': Colors.cyan,
      },
      {
        'icon': Icons.privacy_tip,
        'label': 'Privacy',
        'color': Colors.amber,
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': Colors.blueGrey,
      },
    ];
    Widget quickAccessButton(BuildContext context, Map<String, dynamic> item) {
      double baseWidth = 500.0;
      double baseHeight = 800.0;

      Size screenSize = MediaQuery.of(context).size;

      double widthScaleFactor = screenSize.width / baseWidth;
      double heightScaleFactor = screenSize.height / baseHeight;

      const double maxScaleFactor = 1.5;
      const double minScaleFactor = 0.5;

      double scaleFactor = min(widthScaleFactor, heightScaleFactor);
      scaleFactor = min(scaleFactor, maxScaleFactor);
      scaleFactor = max(scaleFactor, minScaleFactor);

      double radius = 35 * scaleFactor;
      double fontSize = 13 * scaleFactor;
      double iconSize = 34 * scaleFactor;

      return GestureDetector(
        onTap: () {
          switch (item['label']) {
            case 'Events':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarPage()));
              break;
            case 'Donate':
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const DonatePage()));
              break;

            case 'Settings':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()));

              break;
            case 'Privacy':
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PrivacyPage()));
              break;
            case 'Resources':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ResourcesPage()));
              break;
            case 'Conferences':
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const EventsPage()));
              break;
            case 'Jobs':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobBoardPage()));
              break;
            case 'Exclusives':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExclusivesPage()));
              break;
            default:
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: item['color'],
              radius: radius,
              child: Icon(item['icon'], color: Colors.white, size: iconSize),
            ),
            const SizedBox(height: 6),
            Text(
              item['label'],
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget buildSocialMediaSection() {
      List<Map<String, dynamic>> socialLinks = [
        {
          'platform': 'Instagram',
          'icon': FontAwesomeIcons.instagram,
          'url': 'https://www.instagram.com/intercollegiatepsychedelics/',
          'gradient': const LinearGradient(
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        },
        {
          'platform': 'Facebook',
          'icon': Icons.facebook,
          'url': 'https://www.facebook.com/ipnpsychedelics/',
          'color': const Color(0xFF1877F2),
        },
        {
          'platform': 'Linkedin',
          'icon': FontAwesomeIcons.linkedin,
          'url':
              'https://www.linkedin.com/company/intercollegiate-psychedelics-network',
          'color': const Color(0xFF0A66C2),
        },
        {
          'platform': 'Twitter',
          'icon': FontAwesomeIcons.xTwitter,
          'url': 'https://twitter.com/ipnpsychedelics',
          'color': Colors.black,
        },
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12),
            child: Text(
              "Connect with us",
              style: TextStyle(
                fontSize: 16.h,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            child: SizedBox(
              height: 75.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: socialLinks.map((link) {
                  return Expanded(
                    child: Card(
                      elevation: 4,
                      color: link.containsKey('color') ? link['color'] : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          launchURL(link['url']);
                        },
                        child: Container(
                          decoration: link.containsKey('gradient')
                              ? BoxDecoration(
                                  gradient: link['gradient'],
                                  borderRadius: BorderRadius.circular(10),
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                link['icon'],
                                color: Colors.white,
                                size: 30.h,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                link['platform'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.h,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: quaternaryColor,
        child: Column(
          children: [
            buildGreetingSection(context),
            SizedBox(height: 20.h),
            Center(
              child: SizedBox(
                width: min(MediaQuery.of(context).size.width, 1920),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: quickAccessItems.sublist(0, 4).map((item) {
                        return quickAccessButton(context, item);
                      }).toList(),
                    ),
                    SizedBox(height: 10.w),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: quickAccessItems.sublist(4).map((item) {
                        return quickAccessButton(context, item);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            buildSocialMediaSection(),
            SizedBox(height: 10.w),
          ],
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  List<Widget> _widgetOptions = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InitialPage(),
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-out failed: $e'),
        ),
      );
    }
  }

  bool _isBanned = false;
  Future<void> checkUserBanStatus() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userSnapshot.data() as Map<String, dynamic>?;
      if (userData != null && userData.containsKey('banned')) {
        _isBanned = userData['banned'] == true;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    user = _auth.currentUser;

    if (user != null && !user!.emailVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const EmailVerificationPage(),
        ),
      );
    } else {
      _checkAndShowWalkthrough();
    }

    _widgetOptions = <Widget>[
      PlaylistsPage(),
      const CalendarPage(key: PageStorageKey('CalendarPage')),
      const HomeContentPage(key: PageStorageKey('HomeContentPage')),
      const ChatPage(key: PageStorageKey('ChatPage')),
      const ResourcesPage(key: PageStorageKey('ResourcesPage')),
    ];
  }

  Future<void> _checkAndShowWalkthrough() async {
    bool shouldShow = await WalkthroughHelper.shouldShowWalkthrough();
    if (shouldShow) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VideoWalkthroughScreen(
            onFinished: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      await checkUserBanStatus();
      if (_isBanned) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BannedUserPage(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  double _scaleFactor(BuildContext context) {
    double baseWidth = 500.0;
    double baseHeight = 800.0;

    Size screenSize = MediaQuery.of(context).size;

    double widthScaleFactor = screenSize.width / baseWidth;
    double heightScaleFactor = screenSize.height / baseHeight;

    double scaleFactor = min(widthScaleFactor, heightScaleFactor);

    double scaleFactorCap = 2.0;
    return min(scaleFactor, scaleFactorCap);
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required double scaleFactor,
    required double scaleFactorCap,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0 * scaleFactor),
        child: Icon(icon, size: 18.h),
      ),
      label: label,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    double scaleFactor = _scaleFactor(context);
    double logoSize = 50.0 * scaleFactor;
    double iconSize = 25.0 * scaleFactor;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0 * scaleFactor),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color.fromARGB(255, 30, 33, 36),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      FontAwesomeIcons.userAstronaut,
                      size: iconSize,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Image.asset(
                'images/IPN logo Icon.png',
                height: logoSize,
                width: logoSize,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      FontAwesomeIcons.rightFromBracket,
                      size: iconSize,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  color: Colors.transparent,
                                ),
                              ),
                              WillPopScope(
                                onWillPop: () async => false,
                                child: AlertDialog(
                                  backgroundColor:
                                      const Color.fromARGB(255, 30, 33, 36),
                                  title: const Text('Logout',
                                      style: TextStyle(color: Colors.white)),
                                  content: const Text(
                                      'Are you sure you want to logout?',
                                      style: TextStyle(
                                          color: Color.fromARGB(
                                              255, 225, 225, 225))),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Yes',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        _signOut().then((_) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const InitialPage()),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context)
              .textTheme
              .copyWith(bodySmall: TextStyle(fontSize: 20.h)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color.fromARGB(255, 30, 33, 36),
          items: <BottomNavigationBarItem>[
            _buildBottomNavigationBarItem(
              icon: FontAwesomeIcons.youtube,
              label: 'Videos',
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              scaleFactor: scaleFactor,
              scaleFactorCap: 2.0,
            ),
            _buildBottomNavigationBarItem(
              icon: FontAwesomeIcons.solidCalendar,
              label: 'Calendar',
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              scaleFactor: scaleFactor,
              scaleFactorCap: 2.0,
            ),
            _buildBottomNavigationBarItem(
              icon: FontAwesomeIcons.house,
              label: 'Home',
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              scaleFactor: scaleFactor,
              scaleFactorCap: 2.0,
            ),
            _buildBottomNavigationBarItem(
              icon: FontAwesomeIcons.solidMessage,
              label: 'Chat',
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              scaleFactor: scaleFactor,
              scaleFactorCap: 2.0,
            ),
            _buildBottomNavigationBarItem(
              icon: FontAwesomeIcons.solidFolder,
              label: 'Resources',
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              scaleFactor: scaleFactor,
              scaleFactorCap: 2.0,
            ),
          ],
          selectedLabelStyle: TextStyle(
            fontSize: 8.h,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 8.h,
            fontWeight: FontWeight.w500,
          ),
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedItemColor:
              const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
