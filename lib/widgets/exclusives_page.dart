import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ipn_mobile_app/models/exclusive_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExclusivesPage extends StatefulWidget {
  const ExclusivesPage({super.key});

  @override
  _ExclusivesPageState createState() => _ExclusivesPageState();
}

class _ExclusivesPageState extends State<ExclusivesPage> {
  List<Exclusive> _exclusives = [];
  final Random _random = Random();
  @override
  void initState() {
    super.initState();
    _fetchAndSetExclusives();
  }

  Future<void> _fetchAndSetExclusives() async {
    final fetchedExclusives = await _fetchExclusives();
    setState(() {
      _exclusives = fetchedExclusives;
    });
  }

  Future<List<Exclusive>> _fetchExclusives() async {
    String url = dotenv.env['EXCLUSIVES_SPREADSHEET'] ?? 'No Sheet';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = response.body;
      final csvTable = const CsvToListConverter().convert(body);
      final dataRows = csvTable.sublist(1);

      return dataRows.map<Exclusive>((row) {
        return Exclusive(
          offering: row[0],
          organization: row[1],
          website: row[2],
          about: row[3],
          code: row[4],
        );
      }).toList();
    } else {
      throw Exception('Failed to load Exclusives');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member Exclusives',
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        backgroundColor: const Color(0xFF1E2124),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Text(
              'Explore the latest exclusive opportunities for IPN members.',
              style: TextStyle(color: Colors.white, fontSize: 16.h),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: FutureBuilder<List<Exclusive>>(
              future: _fetchExclusives(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final exclusive = snapshot.data![index];
                      return Card(
                        color: const Color(0xFF2D2F33),
                        elevation: 0,
                        child: ListTile(
                          tileColor: const Color.fromARGB(255, 44, 47, 54),
                          leading: CircleAvatar(
                            backgroundColor: _getRandomColor(),
                            child: Icon(
                              FontAwesomeIcons.gem,
                              color: Colors.white,
                              size: 20.h,
                            ),
                          ),
                          title: Text(
                            exclusive.offering,
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.h),
                          ),
                          subtitle: Text(
                            exclusive.organization,
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12.h),
                          ),
                          onTap: () => _openExclusiveDetail(context, exclusive),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
      1,
    );
  }

  void _openExclusiveDetail(BuildContext context, Exclusive exclusive) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ExclusiveDetailScreen(exclusive: exclusive)),
    );
  }
}

class ExclusiveDetailScreen extends StatelessWidget {
  final Exclusive exclusive;

  const ExclusiveDetailScreen({super.key, required this.exclusive});

  void _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw 'Could not launch $urlString';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exclusive.offering,
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1E2124),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.h),
        child: Column(
          children: [
            _buildListTile('Offering', exclusive.offering),
            _buildListTile('Organization', exclusive.organization),
            _buildListTile('Website', exclusive.website,
                onTap: () => _launchURL(exclusive.website)),
            _buildListTile('About', exclusive.about),
            _buildListTile('IPN Member Code', exclusive.code),
          ],
        ),
      ),
    );
  }

  ListTile _buildListTile(String title, String subtitle,
      {VoidCallback? onTap}) {
    return ListTile(
      tileColor: const Color.fromARGB(255, 44, 47, 54),
      contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.h),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16.h)),
      subtitle: InkWell(
        onTap: onTap,
        child: Text(subtitle,
            style: TextStyle(
                color: onTap != null ? Colors.blue : Colors.grey,
                fontSize: 12.h)),
      ),
      textColor: Colors.white,
    );
  }
}
