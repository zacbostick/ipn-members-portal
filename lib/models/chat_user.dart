
class ChatUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  ChatUser(
      {required this.uid,
      required this.firstName,
      required this.lastName,
      this.avatarUrl});
}
