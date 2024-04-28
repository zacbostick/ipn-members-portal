import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/models/playlist_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaylistProvider with ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  Future<void> fetchPlaylists() async {
    await dotenv.load(fileName: ".env");
    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? "No API Key";
    String channelId = dotenv.env['YOUTUBE_CHANNEL_ID'] ?? "No Channel ID";
    final response = await http.get(Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlists?part=snippet&channelId=$channelId&key=$apiKey'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var items = data['items'] as List;
      _playlists = items.map((json) => Playlist.fromJson(json)).toList();
      print(_playlists);
      notifyListeners();
    } else {
      throw Exception('Failed to load playlists');
    }
  }
}
