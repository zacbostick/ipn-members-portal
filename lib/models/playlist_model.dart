class Playlist {
  final String id;
  final String title;
  final String thumbnailUrl;

  Playlist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      title: json['snippet']['title'],
      thumbnailUrl: json['snippet']['thumbnails']['high']['url'],
    );
  }
}
