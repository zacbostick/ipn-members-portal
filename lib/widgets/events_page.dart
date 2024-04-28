import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ipn_mobile_app/models/event_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // ignore: unused_field
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchAndSetEvents();
  }

  void _fetchAndSetEvents() async {
    final fetchedEvents = await _fetchEvents();
    setState(() {
      _events = fetchedEvents;
    });
  }

  void launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  Future<List<Event>> _fetchEvents() async {
    final response =
        await http.get(Uri.parse(dotenv.env['EVENT_SPREADSHEET']!));

    if (response.statusCode == 200) {
      String body = response.body;
      var csvTable = const CsvToListConverter().convert(body);

      final List<List<dynamic>> dataRows = csvTable.sublist(1);

      List<Event> events = dataRows.map<Event>((row) {
        return Event(
          name: row[0],
          when: row[1],
          website: row[2],
          location: row[3],
          sponsoringOrganization: row[4],
          ipnBooth: row[5],
          boothMap: row[6],
          ipnEvents: row[7],
          speakerSubmission: row[8],
          posterSubmission: row[9],
          scholarshipApplication: row[10],
          travelGrantApplication: row[11],
          volunteerApplication: row[12],
          ipnMemberDiscountCode: row[13],
        );
      }).toList();

      return events;
    } else {
      throw Exception('Failed to load Events');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conference Tracker',
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: const Color(0xFF1E2124),
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 14.h),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Text(
                'Explore the latest events and conferences happening in the psychedelic space. Tap on an event to view more details.',
                style: TextStyle(
                    color: const Color.fromARGB(255, 196, 196, 196),
                    fontSize: 14.h),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.globe,
                    color: const Color.fromARGB(255, 65, 116, 199), size: 20.h),
                Text(" = Virtual Event",
                    style: TextStyle(fontSize: 14.h, color: Colors.white)),
                const SizedBox(width: 20),
                Icon(FontAwesomeIcons.users,
                    color: const Color.fromARGB(255, 68, 160, 76), size: 20.h),
                Text("   = In-person Event",
                    style: TextStyle(fontSize: 14.h, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _fetchEvents(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LinearProgressIndicator());
                } else {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final event = snapshot.data![index];
                        return Padding(
                            padding: EdgeInsets.all(4.h),
                            child: Card(
                              elevation: 0,
                              color: const Color.fromARGB(255, 44, 47, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.h),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 6.h, horizontal: 14.h),
                                leading:
                                    event.location.toLowerCase() == "virtual"
                                        ? Icon(FontAwesomeIcons.globe,
                                            color: const Color.fromARGB(
                                                255, 65, 116, 199),
                                            size: 24.h)
                                        : Icon(FontAwesomeIcons.users,
                                            color: const Color.fromARGB(
                                                255, 68, 160, 76),
                                            size: 24.h),
                                title: Text(event.name,
                                    style: TextStyle(fontSize: 14.h)),
                                textColor: Colors.white,
                                subtitle: Text(event.when,
                                    style: TextStyle(fontSize: 12.h)),
                                onTap: () => _openEventDetail(event),
                              ),
                            ));
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Event event;
  void launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name,
            style: TextStyle(fontSize: 14.h, color: Colors.white)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E2124),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14.h,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.h),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text('Event',
                  style:
                      TextStyle(fontSize: 14.h, fontWeight: FontWeight.bold)),
              textColor: Colors.white,
              subtitle: Text(event.name, style: TextStyle(fontSize: 12.h)),
            ),
            const Divider(),
            ListTile(
              title: Text('When',
                  style:
                      TextStyle(fontSize: 14.h, fontWeight: FontWeight.bold)),
              textColor: Colors.white,
              subtitle: Text(event.when, style: TextStyle(fontSize: 12.h)),
            ),
            const Divider(),
            ListTile(
              title: Text('Website', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.website,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.website),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('Location', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: Text(event.location, style: TextStyle(fontSize: 14.h)),
            ),
            const Divider(),
            ListTile(
              title: Text('Sponsoring Organization',
                  style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: Text(event.sponsoringOrganization,
                  style: TextStyle(fontSize: 14.h)),
            ),
            const Divider(),
            ListTile(
              title: Text('IPN Booth', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: Text(event.ipnBooth, style: TextStyle(fontSize: 14.h)),
            ),
            const Divider(),
            ListTile(
              title: Text('Booth Map', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.boothMap,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.boothMap),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('IPN Events', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.ipnEvents,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.ipnEvents),
              ),
            ),
            const Divider(),
            ListTile(
              title:
                  Text('Speaker Submission', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.speakerSubmission,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.speakerSubmission),
              ),
            ),
            const Divider(),
            ListTile(
              title:
                  Text('Poster Submission', style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.posterSubmission,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.posterSubmission),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('Scholarship Application',
                  style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.scholarshipApplication,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.scholarshipApplication),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('Travel Grant Application',
                  style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.travelGrantApplication,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.travelGrantApplication),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('Volunteer Application',
                  style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: InkWell(
                child: Text(event.volunteerApplication,
                    style: TextStyle(color: Colors.blue, fontSize: 14.h)),
                onTap: () => launchURL(event.volunteerApplication),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text('IPN Member Discount Code',
                  style: TextStyle(fontSize: 14.h)),
              textColor: Colors.white,
              subtitle: Text(event.ipnMemberDiscountCode,
                  style: TextStyle(fontSize: 14.h)),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
