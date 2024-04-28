import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as plyr;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Video {
  final String playlistId;
  final String videoId;
  final String videoTitle;
  final String playlistTitle;
  final String videoDescription;
  final String videoThumbnailUrl;
  final DateTime videoPublishedAt;

  Video({
    required this.playlistId,
    required this.videoId,
    required this.playlistTitle,
    required this.videoTitle,
    required this.videoDescription,
    required this.videoThumbnailUrl,
    required this.videoPublishedAt,
  });

  static Future<Video> createFromMap(Map<String, dynamic> map) async {
    String thumbnailUrl;
    if (kIsWeb) {
      thumbnailUrl = await getThumbnailUrl(map['videoId']);
    } else {
      thumbnailUrl = map['videoThumbnailUrl'];
    }

    return Video(
      playlistId: map['playlistId'],
      videoId: map['videoId'],
      playlistTitle: map['playlistTitle'],
      videoTitle: map['videoTitle'],
      videoDescription: map['videoDescription'],
      videoThumbnailUrl: thumbnailUrl,
      videoPublishedAt: DateTime.parse(map['videoPublishedAt']),
    );
  }
}

Future<String> getThumbnailUrl(String videoId) async {
  String path = 'thumbnails/$videoId.jpg';
  String downloadUrl = await firebase_storage.FirebaseStorage.instance
      .ref(path)
      .getDownloadURL();
  return downloadUrl;
}

class Playlist {
  final String id;
  final String playlistTitle;
  final List<Video> videos;

  Playlist({
    required this.id,
    required this.playlistTitle,
    required this.videos,
  });

  static Future<Playlist> createFromMap(Map<String, dynamic> map) async {
    List<Video> videos = [];
    if (map['videos'] != null) {
      for (var videoMap in map['videos']) {
        Video video = await Video.createFromMap(videoMap);
        videos.add(video);
      }
    }

    return Playlist(
      id: map['playlistId'],
      playlistTitle: map['playlistTitle'],
      videos: videos,
    );
  }
}

class DataService {
  Future<List<Map<String, dynamic>>> fetchPlaylistData() async {
    var url = dotenv.env['VIDEO_SPREADSHEET'] ?? 'No Spreadsheet URL Provided';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var rows = const CsvToListConverter().convert(response.body);

      if (rows.isEmpty) {
        throw Exception('CSV data is empty');
      }

      var headers = rows.first.cast<String>();
      var dataRows = rows.skip(1).toList();

      return dataRows.map((row) {
        var rowData = <String, dynamic>{};
        for (var i = 0; i < headers.length; i++) {
          rowData[headers[i]] = row[i];
        }
        return rowData;
      }).toList();
    } else {
      throw Exception('Failed to load playlist data');
    }
  }

  Future<List<Playlist>> fetchPlaylists() async {
    List<Map<String, dynamic>> jsonResponse = await fetchPlaylistData();

    List<Future<Video>> futureVideos =
        jsonResponse.map((item) => Video.createFromMap(item)).toList();

    List<Video> videos = await Future.wait(futureVideos);

    Map<String, List<Video>> videoGroups = {};
    Map<String, String> playlistTitles = {};

    for (var video in videos) {
      if (!videoGroups.containsKey(video.playlistId)) {
        videoGroups[video.playlistId] = [];
      }
      videoGroups[video.playlistId]!.add(video);
      playlistTitles[video.playlistId] = video.playlistTitle;
    }

    List<Playlist> playlists = [];
    for (var entry in videoGroups.entries) {
      var playlistId = entry.key;
      var playlistVideos = entry.value;
      var playlistTitle = playlistTitles[playlistId] ?? "Unknown Title";
      playlists.add(Playlist(
        id: playlistId,
        playlistTitle: playlistTitle,
        videos: playlistVideos,
      ));
    }

    return playlists;
  }
}

class PlaylistsPage extends StatelessWidget {
  final DataService dataService = DataService();

  PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E2124),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 0, 4, 16),
                child: Text(
                  'Explore curated playlists full of insightful content. Updated regularly with the latest videos.',
                  style: TextStyle(
                    fontSize: 16.h,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              FutureBuilder<List<Playlist>>(
                future: dataService.fetchPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70));
                  } else if (snapshot.hasData) {
                    var playlists = snapshot.data!;
                    return Column(
                      children: playlists.map((playlist) {
                        var firstVideoThumbnailUrl = playlist.videos.isNotEmpty
                            ? playlist.videos.first.videoThumbnailUrl
                            : 'default_thumbnail_url';
                        return buildPlaylistCard(
                            context, playlist, firstVideoThumbnailUrl);
                      }).toList(),
                    );
                  } else {
                    return const Text('No data',
                        style: TextStyle(color: Colors.white70));
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlaylistCard(
      BuildContext context, Playlist playlist, String thumbnailUrl) {
    double screenWidth = MediaQuery.of(context).size.width;

    double maxCardWidth = 600;

    bool isWeb = kIsWeb;

    double cardWidth =
        isWeb && screenWidth > maxCardWidth ? maxCardWidth : screenWidth;

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Card(
          color: const Color(0xFF282b30),
          elevation: 6,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailsPage(
                  playlist: playlist,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    playlist.playlistTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14.h,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 20.0),
                  child: Text(
                    '${playlist.videos.length} videos',
                    style: TextStyle(color: Colors.white70, fontSize: 12.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaylistDetailsPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailsPage({super.key, required this.playlist});

  @override
  _PlaylistDetailsPageState createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  late List<Video> videos;
  late List<Video> filteredVideos;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    videos = widget.playlist.videos;

    videos.sort((a, b) => b.videoPublishedAt.compareTo(a.videoPublishedAt));

    filteredVideos = videos;
  }

  void filterVideos(String query) {
    setState(() {
      searchQuery = query;
      if (query.isNotEmpty) {
        filteredVideos = videos
            .where((video) =>
                video.videoTitle.toLowerCase().contains(query.toLowerCase()))
            .toList();

        filteredVideos
            .sort((a, b) => b.videoPublishedAt.compareTo(a.videoPublishedAt));
      } else {
        filteredVideos = List.from(videos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.playlistTitle,
            style: TextStyle(fontSize: 14.h)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E2124),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: VideoSearch(
                  videos: videos,
                  onQueryChanged: filterVideos,
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E2124),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.h),
              child: ListView.builder(
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  var video = videos[index];

                  return Card(
                    color: const Color(0xFF282b30),
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.symmetric(vertical: 12.0),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(video: video),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image(
                              fit: BoxFit.cover,
                              image: NetworkImage(video.videoThumbnailUrl),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  video.videoTitle,
                                  style: TextStyle(
                                    fontSize: 14.h,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  DateFormat.yMd()
                                      .format(video.videoPublishedAt),
                                  style: TextStyle(
                                      fontSize: 14.h, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoSearch extends SearchDelegate<void> {
  final List<Video> videos;
  final ValueChanged<String> onQueryChanged;

  VideoSearch({required this.videos, required this.onQueryChanged});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        color: Color(0xFF282b30),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = videos.where((video) {
      return video.videoTitle.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Container(
      color: const Color(0xFF282b30),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          var video = suggestions[index];
          return ListTile(
            leading: Image.network(
              video.videoThumbnailUrl,
              width: 100.h,
              height: 56.h,
              fit: BoxFit.cover,
            ),
            title: Text(
              video.videoTitle,
              style: TextStyle(
                fontSize: 14.h,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              DateFormat.yMd().format(video.videoPublishedAt),
              style: TextStyle(
                fontSize: 14.h,
                color: Colors.white70,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(video: video),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final Video video;
  const VideoPlayerPage({super.key, required this.video});
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final ValueNotifier<bool> _isFullScreen = ValueNotifier(false);
  late dynamic playerController;

  @override
  void initState() {
    super.initState();
    _initializePlayerController();
  }

  @override
  void dispose() {
    _disposePlayerController();
    super.dispose();
  }

  void _initializePlayerController() {
    if (kIsWeb) {
      playerController = plyr.YoutubePlayerController.fromVideoId(
        videoId: widget.video.videoId,
        autoPlay: false,
        params: const plyr.YoutubePlayerParams(showFullscreenButton: true),
      );
    } else {
      playerController = YoutubePlayerController(
        initialVideoId: widget.video.videoId,
        flags: const YoutubePlayerFlags(
          enableCaption: true,
          isLive: false,
          autoPlay: true,
          mute: false,
        ),
      );
      (playerController as YoutubePlayerController).addListener(() {
        _isFullScreen.value = playerController.value.isFullScreen;
      });
    }
  }

  void _disposePlayerController() {
    if (kIsWeb) {
      (playerController as plyr.YoutubePlayerController).close();
    } else {
      (playerController as YoutubePlayerController).dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFullScreen,
      builder: (context, isFullScreen, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF1E2124),
          appBar: _buildAppBar(isFullScreen),
          body: isFullScreen ? _buildPlayer() : _buildContent(),
        );
      },
    );
  }

  AppBar? _buildAppBar(bool isFullScreen) {
    return isFullScreen
        ? null
        : AppBar(
            title:
                Text(widget.video.videoTitle, style: TextStyle(fontSize: 14.h)),
            elevation: 0,
            backgroundColor: const Color(0xFF1E2124),
          );
  }

  Widget? _playerWidget;
  Widget _buildPlayer() {
    if (_playerWidget == null) {
      if (kIsWeb) {
        _playerWidget = plyr.YoutubePlayer(controller: playerController);
      } else {
        _playerWidget = YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: playerController,
            showVideoProgressIndicator: true,
          ),
          builder: (context, player) => player,
        );
      }
    }
    return _playerWidget!;
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900.h),
                child: Card(
                  color: const Color(0xFF282b30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildPlayer(),
                        ),
                      ),
                      _buildVideoDetails(),
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

  Widget _buildVideoDetails() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.video.videoTitle,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.h,
                  color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Published on ${DateFormat.yMd().format(widget.video.videoPublishedAt)}',
              style: TextStyle(
                  color: const Color.fromARGB(255, 209, 207, 207),
                  fontSize: 12.h),
            ),
            const SizedBox(height: 8.0),
            Linkify(
              onOpen: (link) => _launchURL(link.url),
              text: widget.video.videoDescription,
              style: TextStyle(fontSize: 12.h, color: Colors.white),
              linkStyle: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String? url) async {
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
