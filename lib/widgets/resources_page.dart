import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color tertiaryColor = const Color.fromARGB(255, 44, 47, 54);
    Color quaternaryColor = const Color(0xFF1E2124);

    return Scaffold(
      backgroundColor: quaternaryColor,
      appBar: AppBar(
        backgroundColor: quaternaryColor,
        title: Text('IPN Resources',
            style: TextStyle(fontSize: 16.h, color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.h),
        child: ListView(
          children: <Widget>[
            ResourceTile(
              color: tertiaryColor,
              title: 'Conferences',
              iconData: Icons.badge,
              description:
                  'Immerse yourself in thought-provoking discussions, connect with leading experts, and expand your professional network. These conferences are ideal for those seeking to deepen their knowledge and foster collaborative opportunities.',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const EventsPage())),
            ),
            ResourceTile(
              color: tertiaryColor,
              title: 'Job Board',
              iconData: Icons.work,
              description:
                  'Connect with your next career opportunity. Our job board features positions from top employers in the industry, tailored to your skills and interests.',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobBoardPage())),
            ),
            ResourceTile(
              color: tertiaryColor,
              title: 'Member Exclusives',
              iconData: FontAwesomeIcons.tags,
              description:
                  'Find all the best deals and discounts from our partners in one place. Get access to special offers on products and services just for our members. Save money and discover new favorites with our exclusive discount codes.',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExclusivesPage())),
            ),
          ],
        ),
      ),
    );
  }
}

class ResourceTile extends StatelessWidget {
  final String title;
  final IconData iconData;
  final String description;
  final VoidCallback onTap;
  final Color color;

  const ResourceTile({
    super.key,
    required this.title,
    required this.iconData,
    required this.description,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.all(8.h),
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Icon(iconData, color: Colors.white, size: 25.h),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.h),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.white70, fontSize: 12.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
