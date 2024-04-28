import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JobBoardPage extends StatefulWidget {
  const JobBoardPage({super.key});

  @override
  _JobBoardPageState createState() => _JobBoardPageState();
}

class _JobBoardPageState extends State<JobBoardPage> {
  String? selectedGid;
  Map<String, String> gidNames = {
    '0': 'Administrative & Customer Service',
    '1430838150': 'Business',
    '2131605753': 'Clinical Research',
    '1747429614': 'Education',
    '1785627337': 'Harm Reduction',
    '2011903143': 'Law & Policy',
    '129594954': 'Media & Communications',
    '524713279': 'Medical Care',
    '484211763': 'Operations',
    '635796911': 'Preclinical Research',
    '744852603': 'Software Engineering & Data Science',
    '1680426037': 'Volunteer Opportunities'
  };
  Map<String, IconData> gidIcons = {
    '0': FontAwesomeIcons.userTie,
    '1430838150': FontAwesomeIcons.briefcase,
    '2131605753': FontAwesomeIcons.flask,
    '1747429614': FontAwesomeIcons.graduationCap,
    '1785627337': FontAwesomeIcons.scaleBalanced,
    '2011903143': FontAwesomeIcons.gavel,
    '129594954': FontAwesomeIcons.comments,
    '524713279': FontAwesomeIcons.stethoscope,
    '484211763': FontAwesomeIcons.gears,
    '635796911': FontAwesomeIcons.vial,
    '744852603': FontAwesomeIcons.laptopCode,
    '1680426037': FontAwesomeIcons.handshakeAngle
  };

  Future<List<List<dynamic>>> fetchJobs(
      BuildContext context, String gid) async {
    try {
      final response = dotenv.env['JOBBOARD_SPREADSHEET'] != null
          ? await http.get(Uri.parse(dotenv.env['JOBBOARD_SPREADSHEET']!))
          : throw Exception('No jobs spreadsheet URL found in .env file');

      if (response.statusCode == 200) {
        String body = response.body;
        var csvTable = const CsvToListConverter().convert(body);
        csvTable.removeAt(0);
        return csvTable;
      } else {
        throw Exception(
            'Failed to load jobs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar(context, "Error fetching jobs: $e");
      return [];
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void navigateToJobList(String gid, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobListPage(gid: gid, categoryName: categoryName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Psychedelic Job Board',
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        backgroundColor: const Color(0xFF1E2124),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: Padding(
        padding: EdgeInsets.all(8.h),
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.h),
            Text(
              "Select a category to view available jobs in the psychedelic space:",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16.h),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: gidNames.length,
                itemBuilder: (context, index) {
                  String gid = gidNames.keys.elementAt(index);
                  String categoryName = gidNames[gid] ?? 'Unknown GID';
                  IconData categoryIcon =
                      gidIcons[gid] ?? FontAwesomeIcons.question;

                  return Card(
                    elevation: 0,
                    color: const Color.fromARGB(255, 44, 47, 54),
                    child: ListTile(
                      leading: Icon(categoryIcon,
                          color: const Color.fromARGB(255, 255, 255, 255)),
                      title: Text(
                        categoryName,
                        style: TextStyle(fontSize: 14.h),
                      ),
                      textColor: Colors.white,
                      onTap: () => navigateToJobList(gid, categoryName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobListPage extends StatefulWidget {
  final String gid;
  final String categoryName;

  const JobListPage({
    required this.gid,
    required this.categoryName,
    super.key,
  });

  @override
  _JobListPageState createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  late Future<List<List<dynamic>>> _fetchJobsFuture;

  @override
  void initState() {
    super.initState();
    _fetchJobsFuture = fetchJobs(context, widget.gid);
  }

  Future<List<List<dynamic>>> fetchJobs(
      BuildContext context, String gid) async {
    try {
      final response = dotenv.env['JOBBOARD_SPREADSHEET'] != null
          ? await http.get(Uri.parse(dotenv.env['JOBBOARD_SPREADSHEET']!))
          : throw Exception('No jobs spreadsheet URL found in .env file');

      if (response.statusCode == 200) {
        String body = response.body;
        var csvTable = const CsvToListConverter().convert(body);
        csvTable.removeAt(0);
        return csvTable;
      } else {
        throw Exception(
            'Failed to load jobs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar(context, "Error fetching jobs: $e");
      return [];
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        backgroundColor: const Color(0xFF1E2124),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<List<dynamic>>>(
          future: _fetchJobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LinearProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _fetchJobsFuture = fetchJobs(context, widget.gid);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else {
              var jobs = snapshot.data ?? [];
              if (jobs.isEmpty) {
                return const Center(
                  child: Text('No jobs available at the moment.'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Click on a job to view more details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.h,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        var job = jobs[index];

                        return Card(
                          elevation: 0,
                          color: const Color.fromARGB(255, 44, 47, 54),
                          child: ListTile(
                            title: Text(job[0] ?? 'Unknown Title',
                                style: TextStyle(fontSize: 14.h)),
                            textColor: Colors.white,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job[1] ?? 'Unknown Company',
                                    style: TextStyle(fontSize: 12.h)),
                                Text(job[2] ?? 'Unknown Location',
                                    style: TextStyle(fontSize: 12.h)),
                              ],
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    elevation: 0,
                                    backgroundColor:
                                        const Color.fromARGB(255, 37, 39, 44),
                                    title: Text(
                                      job[0] ?? 'Unknown Title',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.h,
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              text: 'Company: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14.h,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: job[1] ??
                                                      'Unknown Company',
                                                  style: TextStyle(
                                                    fontSize: 14.h,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: const Color.fromARGB(
                                                        255, 196, 196, 196),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Location: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.h,
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: job[2] ??
                                                      'Unknown Location',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 14.h,
                                                    color: const Color.fromARGB(
                                                        255, 204, 204, 204),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Description: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.h,
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: job[4] ??
                                                      'Unknown Description',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 14.h,
                                                    color: const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          TextButton(
                                            onPressed: () => launchURL(
                                                job[5] ?? 'Unknown Link'),
                                            child: Text(
                                              'Apply Now',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 14.h,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Close',
                                            style:
                                                TextStyle(color: Colors.white),
                                          )),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
