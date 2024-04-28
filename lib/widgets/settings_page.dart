import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:url_launcher/url_launcher.dart';
import '/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  void openAppSettings() async {
    if (Platform.isAndroid) {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final AndroidIntent intent = AndroidIntent(
        action: 'action_application_details_settings',
        data: 'package:${packageInfo.packageName}',
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      String iosAppSettings = 'app-settings:';
      if (await canLaunch(iosAppSettings)) {
        await launch(iosAppSettings);
      } else {}
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<Map<String, dynamic>> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data() as Map<String, dynamic>;
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final XFile? selectedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (selectedImage == null) {
      return;
    }

    Uint8List? compressedImageData;
    if (kIsWeb) {
      compressedImageData = await selectedImage.readAsBytes();
      compressedImageData = await compressImageWeb(compressedImageData);
    } else {
      compressedImageData = await compressImageMobile(selectedImage.path);
    }

    if (compressedImageData == null) {
      return;
    }
    String storagePath = 'userAvatars/${user.uid}.jpg';
    try {
      Reference storageReference =
          FirebaseStorage.instance.ref().child(storagePath);
      await storageReference.putData(compressedImageData);
      String imageUrl = await storageReference.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'avatarUrl': imageUrl,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
        ),
      );
    }
  }

  Future<Uint8List?> compressImageWeb(Uint8List imageData) async {
    return imageData;
  }

  Future<Uint8List?> compressImageMobile(String imagePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: 1024,
      minHeight: 768,
      quality: 50,
    );
    return result;
  }

  Future<void> _deleteAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 30, 33, 36),
              title: const Text('Confirm Account Deletion',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              content: const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Delete',
                      style: TextStyle(color: Color.fromARGB(255, 255, 0, 0))),
                  onPressed: () async {
                    DocumentReference users = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid);

                    await users.delete();

                    await user.delete();

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Account deleted successfully.')),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InitialPage()),
                    );
                  },
                ),
              ],
            );
          });
    } else {
      throw Exception('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              ModalRoute.withName('/'),
            );
          },
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 33, 36),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 30, 33, 36),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 30, 33, 36),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: LayoutBuilder(builder: (context, constraints) {
            final cardWidth =
                constraints.maxWidth > 400.0 ? 400.0 : constraints.maxWidth;
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: cardWidth, minHeight: 250.h),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: LinearProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          Map<String, dynamic> userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          return Card(
                            color: const Color.fromARGB(255, 40, 43, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        await pickAndUploadImage();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SettingsPage()),
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: 50.h,
                                        backgroundColor: const Color.fromARGB(
                                            255, 174, 174, 174),
                                        backgroundImage: NetworkImage(
                                            userData['avatarUrl'] ??
                                                'default_image_url_here'),
                                        child: userData['avatarUrl'] == null
                                            ? Icon(Icons.account_circle_rounded,
                                                size: 60.h,
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255))
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Text('Click to change profile picture',
                                      style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 225, 225, 225),
                                          fontSize: 12.h)),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    '${userData['first_name'] ?? 'First Name'} ${userData['last_name'] ?? 'Last Name'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16.h,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    userData['affiliation'] ?? 'Affiliation',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14.h,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    userData['description'] ?? 'Description',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.h,
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    userData['field'] ?? 'Field',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.h,
                                      color: const Color.fromARGB(
                                          255, 255, 255, 255),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: cardWidth.h),
                      child: Card(
                        color: const Color(0xFF282b30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: EdgeInsets.all(14.h),
                          child: ListView(
                            shrinkWrap: true,
                            children: <Widget>[
                              Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 109, 76, 193),
                                      Color.fromARGB(255, 128, 43, 226),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const UpdateProfilePage()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(FontAwesomeIcons.userEdit,
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                            size: 14.h),
                                        SizedBox(width: 10.h),
                                        Text(
                                          'Update Profile',
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: 12.h,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 109, 76, 193),
                                      Color.fromARGB(255, 128, 43, 226),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const UpdatePasswordPage()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(FontAwesomeIcons.lock,
                                            color: const Color.fromARGB(
                                                255, 255, 255, 255),
                                            size: 12.h),
                                        SizedBox(width: 4.h),
                                        Text(
                                          'Update Password',
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: 12.h,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Visibility(
                                visible: !kIsWeb,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4.h, horizontal: 4.h),
                                      backgroundColor: const Color.fromARGB(
                                          255, 18, 25, 237)),
                                  icon: Icon(Icons.notifications,
                                      color: const Color(0xFFFFFFFF),
                                      size: 12.h),
                                  label: Text('Enable Push Notifications',
                                      style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 11.h)),
                                  onPressed: openAppSettings,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              ElevatedButton(
                                onPressed: _deleteAccount,
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.symmetric(
                                          vertical: 4.h, horizontal: 4.h)),
                                  backgroundColor: MaterialStateProperty.all(
                                      const Color.fromARGB(255, 247, 56, 56)),
                                ),
                                child: Text('Delete Account',
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 11.h)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPage()),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12.h,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                        255, 215, 215, 215),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  UpdateProfilePageState createState() => UpdateProfilePageState();
}

class UpdateProfilePageState extends State<UpdateProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController affiliationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController fieldController = TextEditingController();

  bool containsProfanity(String input) {
    var filter = ProfanityFilter();
    return filter.hasProfanity(input);
  }

  String? validateInput(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    } else if (containsProfanity(value)) {
      return '$fieldName contains inappropriate language';
    }
    return null;
  }

  Future<void> _updateProfile() async {
    if (containsProfanity(firstNameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('First name contains inappropriate language.')),
      );
      return;
    }
    if (containsProfanity(lastNameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Last name contains inappropriate language.')),
      );
      return;
    }
    if (containsProfanity(affiliationController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Affiliation contains inappropriate language.')),
      );
      return;
    }
    if (containsProfanity(descriptionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Description contains inappropriate language.')),
      );
      return;
    }
    if (containsProfanity(genderController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gender contains inappropriate language.')),
      );
      return;
    }
    if (containsProfanity(fieldController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field contains inappropriate language.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        DocumentReference users =
            FirebaseFirestore.instance.collection('users').doc(user!.uid);
        users.update({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'affiliation': affiliationController.text,
          'description': descriptionController.text,
          'gender': genderController.text,
          'field': fieldController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    }
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  String? description;
  List<String> descriptions = [
    'Aspiring Student',
    'Undergraduate Student (B.A./B.S.)',
    'Graduate Student (M.A./M.S./Ph.D/MBA)',
    'Professional Student (M.D./J.D./D.O)',
    'Postdoctoral Fellow',
    'Faculty',
    'Aspiring Industry Professional',
    'Current Industry Professional',
    'Other'
  ];
  String? field;
  List<String> fields = [
    'Arts & Humanities',
    'Business',
    'Health & Medicine',
    'Law and Policy',
    'Multi-Disciplinary',
    'Public & Social Services',
    'Science, Technology, Engineering, & Mathematics',
    'Social Sciences',
    'Trade and Personal Services',
    'Other'
  ];
  String? gender;
  List<String> genders = [
    "Woman",
    "Man",
    "Transgender Woman",
    "Transgender Man",
    "Non-Binary",
    "Agender/I do not identify with any gender",
    "Gender not listed here",
    "Prefer not to state",
  ];
  Future<Map<String, dynamic>> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data() as Map<String, dynamic>;
    } else {
      throw Exception('No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserData(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (description == null &&
              descriptions.contains(snapshot.data!['description'])) {
            description = snapshot.data!['description'];
            descriptionController.text = description!;
          }
          if (gender == null && genders.contains(snapshot.data!['gender'])) {
            gender = snapshot.data!['gender'];
            genderController.text = gender!;
          }
          if (field == null && fields.contains(snapshot.data!['field'])) {
            field = snapshot.data!['field'];
            fieldController.text = field!;
          }
          firstNameController.text = snapshot.data!['first_name'];
          lastNameController.text = snapshot.data!['last_name'];
          affiliationController.text = snapshot.data!['affiliation'];
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 30, 33, 36),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 30, 33, 36),
              title: const Text('Update Profile',
                  style: TextStyle(color: Colors.white)),
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            body: SafeArea(
              child: Container(
                color: const Color.fromARGB(255, 30, 33, 36),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: <Widget>[
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 600.h),
                          child: Card(
                            color: const Color(0xFF282b30),
                            elevation: 6,
                            child: Padding(
                              padding: EdgeInsets.all(16.h),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 16.h,
                                      ),
                                      prefixIcon: Icon(
                                          FontAwesomeIcons.userAstronaut,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                    validator: (value) =>
                                        validateInput(value, 'First Name'),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                  ),
                                  SizedBox(height: 16.h),
                                  TextFormField(
                                    controller: lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 16.h),
                                      prefixIcon: Icon(FontAwesomeIcons.user,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                    validator: (value) =>
                                        validateInput(value, 'Last Name'),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                  ),
                                  SizedBox(height: 16.h),
                                  TextFormField(
                                    controller: affiliationController,
                                    decoration: InputDecoration(
                                      labelText: 'Affiliation',
                                      labelStyle: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 16.h),
                                      prefixIcon: Icon(
                                          FontAwesomeIcons.buildingColumns,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                    validator: (value) =>
                                        validateInput(value, 'Affiliation'),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                  ),
                                  SizedBox(height: 16.h),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: description,
                                    dropdownColor:
                                        const Color.fromARGB(255, 30, 33, 36),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                    items:
                                        descriptions.map((String description) {
                                      return DropdownMenuItem(
                                        value: description,
                                        child: Text(description,
                                            style: TextStyle(
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 14.h)),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        description = newValue;
                                        descriptionController.text = newValue!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Description',
                                      labelStyle: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 16.h),
                                      prefixIcon: Icon(FontAwesomeIcons.book,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    dropdownColor:
                                        const Color.fromARGB(255, 30, 33, 36),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                    value: gender,
                                    items: genders.map((String gender) {
                                      return DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender,
                                            style: TextStyle(
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 14.h)),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        gender = newValue;
                                        genderController.text = newValue!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      labelStyle: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 16.h),
                                      prefixIcon: Icon(
                                          FontAwesomeIcons.genderless,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: field,
                                    dropdownColor:
                                        const Color.fromARGB(255, 30, 33, 36),
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 14.h),
                                    items: fields.map((String field) {
                                      return DropdownMenuItem(
                                        value: field,
                                        child: Text(field),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        field = newValue;
                                        fieldController.text = newValue!;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Field',
                                      labelStyle: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 16.h),
                                      prefixIcon: Icon(
                                          FontAwesomeIcons.paperclip,
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          size: 18.h),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  const SizedBox(height: 16.0),
                                  Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 109, 76, 193),
                                          Color.fromARGB(255, 128, 43, 226),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: InkWell(
                                      onTap: _updateProfile,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.h, vertical: 10.h),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(FontAwesomeIcons.userPen,
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                                size: 14.h),
                                            const SizedBox(width: 10.0),
                                            Text(
                                              'Update Profile',
                                              style: TextStyle(
                                                  color: const Color.fromARGB(
                                                      255, 255, 255, 255),
                                                  fontSize: 12.h,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: LinearProgressIndicator(),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: Text('Something went wrong!'),
            ),
          );
        }
      },
    );
  }
}

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  UpdatePasswordPageState createState() => UpdatePasswordPageState();
}

class UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: _oldPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        await user.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred while updating password.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 30, 33, 36),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 30, 33, 36),
      body: Container(
        color: const Color.fromARGB(255, 30, 33, 36),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.h),
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600.h),
                  child: Card(
                    color: const Color(0xFF282b30),
                    elevation: 6,
                    child: Padding(
                      padding: EdgeInsets.all(16.h),
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontSize: 14.h),
                            controller: _oldPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Old password',
                              labelStyle: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 14.h),
                              prefixIcon: Icon(FontAwesomeIcons.unlock,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  size: 14.h),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your old password';
                              }
                              return null;
                            },
                            obscureText: true,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontSize: 14.h),
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              labelStyle: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 14.h),
                              prefixIcon: Icon(FontAwesomeIcons.lock,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  size: 14.h),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              return null;
                            },
                            obscureText: true,
                          ),
                          SizedBox(height: 14.h),
                          TextFormField(
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontSize: 14.h),
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm new password',
                              labelStyle: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 14.h),
                              prefixIcon: Icon(FontAwesomeIcons.userLock,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  size: 14.h),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            obscureText: true,
                          ),
                          SizedBox(height: 16.h),
                          Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 109, 76, 193),
                                  Color.fromARGB(255, 128, 43, 226),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: InkWell(
                              onTap: _changePassword,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.h, vertical: 10.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(FontAwesomeIcons.floppyDisk,
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        size: 14.h),
                                    SizedBox(width: 10.h),
                                    Text(
                                      'Update Password',
                                      style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontSize: 12.h,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
