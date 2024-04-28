import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ipn_mobile_app/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:ipn_mobile_app/models/chat_room.dart';
import 'package:ipn_mobile_app/models/time_stamp.dart';
import 'package:ipn_mobile_app/models/message_data.dart';
import 'package:ipn_mobile_app/providers/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _selectedChatRoomId = 'ciHADdxF7xyWcbJ6DoMb';
  String? _replyToMessageId;
  String? _replyToMessageText;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _replyToMessageUser;
  String? _replyToMessageAvatarUrl;
  late FirebaseChatService _chatService;
  void _setReplyToMessageId(String? messageId) {
    setState(() {
      _replyToMessageId = messageId;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToMessageText = null;
      _replyToMessageAvatarUrl = null;
      _replyToMessageUser = null;
    });
  }

  void _setReplyTo(String messageId, String messageText, String avatarUrl,
      String userFirstName, String userLastName) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToMessageText = messageText;
      _replyToMessageAvatarUrl = avatarUrl;
      _replyToMessageUser = '$userFirstName $userLastName';
    });
  }

  void _handleReplyPressed(String messageId, String messageText,
      String avatarUrl, String userFirstName, String userLastName) {
    _setReplyTo(messageId, messageText, avatarUrl, userFirstName, userLastName);
  }

  String _selectedChatRoomName = '🌎General';
  void launchURL(String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  int getCrossAxisCount(BuildContext context) {
    if (MediaQuery.of(context).size.width > 600) {
      return 4;
    } else {
      return 2;
    }
  }

  @override
  void initState() {
    super.initState();
    _chatService = FirebaseChatService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 30, 33, 36),
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          key: _scaffoldKey,
          appBar: AppBar(
            centerTitle: false,
            elevation: 0,
            backgroundColor: const Color.fromARGB(255, 30, 33, 36),
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '  # $_selectedChatRoomName',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.h,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          drawer: Drawer(
            width: 320.w,
            child: Drawer(
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 30, 33, 36),
              child: FutureBuilder<List<ChatRoom>>(
                future: _chatService.fetchChatRooms(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final chatRooms = snapshot.data!;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      Container(
                        height: 100.h,
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 30, 33, 36),
                          border: Border(
                            bottom: BorderSide(
                              color: Color.fromARGB(255, 61, 61, 61),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              'images/Whte Logo Icon.png',
                              width: 60.w,
                              height: 60.h,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'IPN Community',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.h,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Pick a channel to start chatting',
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 179, 176, 176),
                                      fontSize: 14.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...chatRooms.map((chatRoom) => ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 2.w, horizontal: 8.h),
                            shape: Border(
                                bottom: BorderSide(
                              color: const Color.fromARGB(255, 61, 61, 61),
                              width: 1.h,
                            )),
                            title: Text(
                              chatRoom.name,
                              style: TextStyle(
                                  fontSize: 14.h,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _selectedChatRoomId = chatRoom.id;
                                _selectedChatRoomName = chatRoom.name;
                              });
                            },
                          )),
                    ],
                  );
                },
              ),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 30, 33, 36),
          body: Column(
            children: <Widget>[
              Expanded(
                child: MessagesList(
                  key: ValueKey(_selectedChatRoomId),
                  chatRoomId: _selectedChatRoomId,
                  setReplyToMessage: _setReplyToMessageId,
                ),
              ),
              NewMessage(
                chatRoomId: _selectedChatRoomId,
                replyToMessage: _replyToMessageId,
                replyToMessageText: _replyToMessageText,
                replyToMessageUser: _replyToMessageUser,
                replyToMessageAvatarUrl: _replyToMessageAvatarUrl,
                onMessageSent: () {
                  setState(() {
                    _replyToMessageId = null;
                    _replyToMessageText = null;
                  });
                },
                onCancelReply: _cancelReply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesList extends StatefulWidget {
  final String chatRoomId;
  final Function(String? messageId) setReplyToMessage;
  final String searchQuery;

  const MessagesList({
    super.key,
    required this.chatRoomId,
    required this.setReplyToMessage,
    this.searchQuery = '',
  });

  @override
  _MessagesListState createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  List<MessageData> messageData = [];
  StreamSubscription? _messagesSubscription;
  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  bool isLiking = false;

  void handleLikePressed(
      String docId, List<String> likes, BuildContext context) {
    if (isLiking) return;
    isLiking = true;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      final updatedLikes = Set<String>.from(likes);

      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
      } else {
        updatedLikes.add(userId);
      }

      FirebaseFirestore.instance
          .collection('chats/${widget.chatRoomId}/messages')
          .doc(docId)
          .update({
        'likes': updatedLikes.toList(),
      }).then((_) {
        isLiking = false;
      }).catchError((error) {
        isLiking = false;

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating likes: $error")));
      });
    }
  }

  void fetchInitialData() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chats/${widget.chatRoomId}/messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        List<MessageData> fetchedMessagesData =
            await fetchAllMessageData(snapshot.docs);
        if (mounted) {
          setState(() {
            messageData = fetchedMessagesData;
          });
        }
      },
      onError: (error) {},
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<List<MessageData>> fetchAllMessageData(
      List<DocumentSnapshot> messageDocs) async {
    Set<String> userIds = {};
    Set<String> replyMessageIds = {};
    for (var doc in messageDocs) {
      if (!doc.exists) {
        continue;
      }
      userIds.add(doc['userId']);
      if (doc['replyToMessageId'] != null) {
        replyMessageIds.add(doc['replyToMessageId']);
      }
    }

    Map<String, dynamic> usersData = {};
    Map<String, bool> userBannedStatus = {};
    for (String userId in userIds) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      usersData[userId] = userDoc.data();
      userBannedStatus[userId] = userDoc.data()?['banned'] == true;
    }

    Map<String, String?> replyMessagesText = {};
    for (String messageId in replyMessageIds) {
      var messageDoc = await FirebaseFirestore.instance
          .collection('chats/${widget.chatRoomId}/messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists &&
          (messageDoc.data()?.containsKey('text') ?? false)) {
        replyMessagesText[messageId] = messageDoc['text'];
      } else {
        replyMessagesText[messageId] = null;
      }
    }

    List<MessageData> messagesData = [];
    for (var doc in messageDocs) {
      if (!userBannedStatus[doc['userId']]!) {
        messagesData.add(MessageData(
          messageSnapshot: doc,
          userData: usersData[doc['userId']],
          replyToMessageText: replyMessagesText[doc['replyToMessageId']],
        ));
      } else {}
    }

    return messagesData;
  }

  Future<String?> fetchReplyToMessageText(String? replyToMessageId) async {
    if (replyToMessageId == null) {
      return null;
    }
    try {
      DocumentSnapshot replyMessageSnapshot = await FirebaseFirestore.instance
          .collection('chats/${widget.chatRoomId}/messages')
          .doc(replyToMessageId)
          .get();
      return replyMessageSnapshot['text'];
    } catch (e) {
      return "Error fetching message";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: const Color.fromARGB(255, 40, 43, 48),
        child: messageData.isEmpty
            ? const Center(
                child: Text("No messages yet",
                    style: TextStyle(color: Colors.white)))
            : ListView.builder(
                reverse: true,
                itemCount: messageData.length,
                itemBuilder: (ctx, index) {
                  var msgData = messageData[index];
                  var docData =
                      msgData.messageSnapshot.data() as Map<String, dynamic>;
                  var messageText = docData['text'] ?? "";
                  bool shouldHighlight = widget.searchQuery.isNotEmpty &&
                      messageText.contains(widget.searchQuery);
                  if (widget.searchQuery.isNotEmpty &&
                      !messageText.contains(widget.searchQuery)) {
                    return const SizedBox.shrink();
                  }

                  return MessageBubble(
                    docId: msgData.messageSnapshot.id,
                    highlight: shouldHighlight,
                    isLiked: docData['likes']?.contains(
                            FirebaseAuth.instance.currentUser?.uid) ??
                        false,
                    key: ValueKey(msgData.messageSnapshot.id),
                    userId: docData['userId'],
                    message: docData['text'] ?? "Missing message",
                    firstName: msgData.userData?['first_name'] ?? 'Unknown',
                    lastName: msgData.userData?['last_name'] ?? 'User',
                    chatRoomId: widget.chatRoomId,
                    timestamp: (docData['timestamp'] as Timestamp).toDate(),
                    avatarUrl: msgData.userData?['avatarUrl'],
                    replyToMessageText: msgData.replyToMessageText,
                    onReplyPressed: (String messageId, String messageText) {
                      widget.setReplyToMessage(messageId);
                    },
                    likes: List<String>.from(docData['likes'] ?? []),
                    onLikePressed: (String docId, bool isLiked) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        final userId = currentUser.uid;
                        final newLikes =
                            Set<String>.from(docData['likes'] ?? []);
                        if (isLiked) {
                          newLikes.add(userId);
                        } else {
                          newLikes.remove(userId);
                        }
                        FirebaseFirestore.instance
                            .collection('chats/${widget.chatRoomId}/messages')
                            .doc(docId)
                            .update({'likes': newLikes.toList()});
                      }
                    },
                  );
                },
              ));
  }
}

class MessageBubble extends StatefulWidget {
  final String docId;
  final String userId;
  final String message;
  final bool highlight;
  final String firstName;
  final String lastName;
  final String chatRoomId;
  final DateTime timestamp;
  final String? avatarUrl;
  final String? replyToMessageText;
  List<String> likes;
  final Function(String docId, bool isLiked) onLikePressed;
  final bool isLiked;
  final Function(String messageId, String messageText) onReplyPressed;

  MessageBubble({
    super.key,
    required this.docId,
    required this.userId,
    required this.message,
    required this.firstName,
    required this.lastName,
    required this.timestamp,
    required this.chatRoomId,
    this.highlight = false,
    this.avatarUrl,
    this.replyToMessageText,
    required this.likes,
    required this.onLikePressed,
    required this.isLiked,
    required this.onReplyPressed,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool isLiking = false;
  bool isAdmin = false;

  void handleLikePressed() {
    if (!isLiking) {
      setState(() {
        isLiking = true;
      });

      widget.onLikePressed(widget.docId, !widget.isLiked);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            isLiking = false;
          });
        }
      });
    }
  }

  void _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData['admin'] == true) {
        setState(() {
          isAdmin = true;
        });
      }
    }
  }

  void updateLikes(List<String> newLikes) {
    setState(() {
      widget.likes = newLikes;
    });
  }

  void deleteMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message',
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 29, 29, 29),
          content: const Text('Are you sure you want to delete this message?',
              style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 29, 29, 29),
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                backgroundColor: const Color.fromARGB(255, 29, 29, 29),
              ),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('chats/${widget.chatRoomId}/messages')
                    .doc(widget.docId)
                    .delete()
                    .then((_) => Navigator.of(context).pop())
                    .catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Error deleting message: $error")));
                });
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void banUser(String userId, bool isAdmin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 29, 29, 29),
          title: const Text('Ban User', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to ban this user?',
              style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'banned': true}).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User has been banned.")));
                }).catchError((error) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Error banning user: $error.message")));
                });
              },
              child: const Text('Ban', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime = formatTimestamp(widget.timestamp);
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isCurrentUser = currentUser?.uid == widget.userId;
    bool isLiked = widget.isLiked;
    final bool canBanUser = isAdmin;
    final bool canDeleteMessage = isCurrentUser || isAdmin;
    return Column(children: [
      const Divider(
          height: 1, thickness: 1, color: Color.fromARGB(255, 61, 61, 61)),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 16.h,
                backgroundImage: widget.avatarUrl != null
                    ? CachedNetworkImageProvider(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.replyToMessageText?.isNotEmpty ?? false)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text('Replying to: ${widget.replyToMessageText}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 10.h)),
                      ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: "${widget.firstName} ${widget.lastName}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 12.h)),
                          TextSpan(
                              text: " · $formattedTime",
                              style: TextStyle(
                                  fontSize: 10.h,
                                  color: const Color.fromARGB(
                                      255, 186, 186, 186))),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    SelectableText(widget.message,
                        style: TextStyle(color: Colors.white, fontSize: 12.h)),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: handleLikePressed,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.thumb_up,
                                  color: isLiked
                                      ? Colors.blue
                                      : const Color.fromARGB(
                                          255, 186, 186, 186),
                                  size: 14.h),
                              SizedBox(width: 4.h),
                              Text('${widget.likes.length}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12.h)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chat_rounded,
                              color: const Color.fromARGB(255, 186, 186, 186),
                              size: 14.h),
                          onPressed: () => context
                              .findAncestorStateOfType<_ChatPageState>()
                              ?._handleReplyPressed(
                                  widget.docId,
                                  widget.message,
                                  widget.firstName,
                                  widget.lastName,
                                  widget.avatarUrl ?? 'defaultAvatarUrl'),
                        ),
                        const Spacer(),
                        if (canDeleteMessage)
                          IconButton(
                            icon: Icon(Icons.delete_forever,
                                color: const Color.fromARGB(255, 186, 186, 186),
                                size: 18.h),
                            onPressed: deleteMessage,
                          ),
                        if (canBanUser)
                          IconButton(
                            icon: const Icon(Icons.security,
                                color: Colors.red, size: 20.0),
                            onPressed: () {
                              banUser(widget.userId, isAdmin);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ))
    ]);
  }
}

class NewMessage extends StatefulWidget {
  final String chatRoomId;
  final String? replyToMessage;
  final VoidCallback? onMessageSent;
  final String? replyToMessageText;
  final String? replyToMessageUser;
  final String? replyToMessageAvatarUrl;
  final VoidCallback? onCancelReply;

  const NewMessage({
    super.key,
    required this.chatRoomId,
    this.replyToMessage,
    this.replyToMessageText,
    this.replyToMessageUser,
    this.replyToMessageAvatarUrl,
    this.onCancelReply,
    this.onMessageSent,
  });
  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage>
    with RestorationMixin, WidgetsBindingObserver {
  final RestorableTextEditingController _controller =
      RestorableTextEditingController();
  String _enteredMessage = '';
  @override
  String get restorationId => 'text_field';
  late FocusNode _focusNode;
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'text_field');
  }

  void _sendMessage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final trimmedMessage = _enteredMessage.trim();
    if (trimmedMessage.isEmpty) return;

    FocusScope.of(context).unfocus();

    FirebaseFirestore.instance
        .collection('chats/${widget.chatRoomId}/messages')
        .add({
      'text': trimmedMessage.substring(0, math.min(300, trimmedMessage.length)),
      'timestamp': Timestamp.now(),
      'userId': user.uid,
      'replyToMessageId': widget.replyToMessage,
    });

    _controller.value.clear();
    setState(() {
      _enteredMessage = '';
    });
    if (widget.onMessageSent != null) {
      widget.onMessageSent!();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      color: const Color.fromARGB(255, 30, 33, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyToMessageText != null)
            GestureDetector(
              onVerticalDragDown: (details) {
                FocusScope.of(context).unfocus();
              },
              onTap: () {},
              child: Container(
                padding: EdgeInsets.all(8.h),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 40, 43, 48),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 8.h),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12.h,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.replyToMessageText!,
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.h),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      onPressed: widget.onCancelReply,
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    TextField(
                      controller: _controller.value,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: Colors.white, fontSize: 14.h),
                      decoration: InputDecoration(
                        labelText: 'Send a message...',
                        labelStyle:
                            TextStyle(color: Colors.white70, fontSize: 14.h),
                        fillColor: const Color.fromARGB(255, 40, 43, 48),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (value) {
                        setState(() {
                          _enteredMessage = value;
                        });
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(300),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${_enteredMessage.length}/300',
                        style: TextStyle(color: Colors.white70, fontSize: 12.h),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                  icon: Icon(Icons.send, size: 20.h),
                  color: _enteredMessage.trim().isEmpty
                      ? Colors.white.withOpacity(0.80)
                      : Colors.white,
                  onPressed: _enteredMessage.trim().isEmpty
                      ? null
                      : () {
                          _sendMessage();
                        }),
            ],
          ),
        ],
      ),
    );
  }
}
