import 'package:intl/intl.dart';

String formatTimestamp(DateTime timestamp) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
  final DateTime messageDate =
      DateTime(timestamp.year, timestamp.month, timestamp.day);

  final String time = DateFormat('h:mm a').format(timestamp);

  if (messageDate == today) {
    return 'Today at $time';
  } else if (messageDate == yesterday) {
    return 'Yesterday';
  } else {
    return DateFormat('MMM d').format(timestamp);
  }
}
