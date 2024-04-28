import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:profanity_filter/profanity_filter.dart';
import '../widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? birthDate;
  final TextEditingController affiliationController = TextEditingController();
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
  String howDidYouHearAboutUs = "";
  final TextEditingController locationController = TextEditingController();
  String? race;
  List<String> races = [
    'Asian',
    'Black',
    'Hispanic',
    'White',
    'Native American/Alaskan Native',
    'Native Hawaiian/Pacific Islander',
    'Other',
    'Prefer not to say'
  ];
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

  String? countryValue = "";
  String? stateValue = "";
  String? cityValue = "";
  bool isCountrySelected = false;
  bool isStateSelected = false;
  bool isCitySelected = false;

  void _signup(BuildContext context) async {
    try {
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
      if (containsProfanity(howDidYouHearAboutUs)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Answer to "How did you hear about us?" contains inappropriate language.')),
        );
        return;
      }

      if (passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password should be at least 6 characters.')),
        );
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password and confirm password do not match.')),
        );
        return;
      }

      if (emailController.text.length < 5 ||
          !emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Enter a valid email address.')),
        );
        return;
      }
      if (affiliationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please Enter an Affiliation or put N/A.')),
        );
        return;
      }
      if (firstNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Enter your First Name.')),
        );
        return;
      }
      if (lastNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please Enter a Last Name.')),
        );
        return;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        DocumentReference users =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        users.set({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'email': emailController.text.trim(),
          'birthdate': birthDate?.toIso8601String(),
          'affiliation': affiliationController.text,
          'description': description,
          'field': field,
          'gender': gender,
          'how': howDidYouHearAboutUs,
          'location':
              '${cityValue ?? 'N/A'}, ${stateValue ?? 'N/A'}, ${countryValue ?? 'N/A'}',
          'race': race,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This email is already in use. Please log in.'),
            action: SnackBarAction(
              label: "Go to Login",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginForm()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 102, 79, 161),
                Color.fromARGB(255, 102, 79, 161),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0),
                        child: Container(
                          margin: const EdgeInsets.only(top: 50.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Join IPN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Fill out the form below to join the IPN community!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Image(
                                  image:
                                      AssetImage('images/Whte Logo Icon.png'),
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color.fromARGB(
                                        255, 255, 255, 255),
                                  ),
                                  child: const Text('Go Back'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: firstNameController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'First Name',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  validator: (value) =>
                                      validateInput(value, 'First Name'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: lastNameController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Last Name',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  validator: (value) =>
                                      validateInput(value, 'Last Name'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Email',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  validator: (value) =>
                                      validateInput(value, 'Email'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: passwordController,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Password',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Confirm Password',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  obscureText: true,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: affiliationController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'University/Company',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  validator: (value) => validateInput(
                                      value, 'University/Company'),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField(
                                  isExpanded: true,
                                  value: description,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Which best describes you?',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      description = newValue;
                                    });
                                  },
                                  items: descriptions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      validateInput(value, 'Description'),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField(
                                  isExpanded: true,
                                  value: field,
                                  decoration: const InputDecoration(
                                    labelText: 'What field are you in?',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      field = newValue;
                                    });
                                  },
                                  items: fields.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      validateInput(value, 'Field'),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField(
                                  isExpanded: true,
                                  value: gender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      gender = newValue;
                                    });
                                  },
                                  items: genders.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      validateInput(value, 'Gender'),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField(
                                  isExpanded: true,
                                  value: race,
                                  decoration: const InputDecoration(
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'Race/Ethnicity',
                                    fillColor:
                                        Color.fromARGB(255, 255, 255, 255),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      race = newValue;
                                    });
                                  },
                                  items: races.map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      validateInput(value, 'Race/Ethnicity'),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Where are you from?',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: 'RaleWay',
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                CSCPicker(
                                  showStates: true,
                                  showCities: true,
                                  dropdownDecoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                  disabledDropdownDecoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    color: Colors.grey.shade300,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                  countrySearchPlaceholder: "Country",
                                  stateSearchPlaceholder: "State",
                                  citySearchPlaceholder: "City",
                                  countryDropdownLabel: "*Country",
                                  stateDropdownLabel: "*State",
                                  cityDropdownLabel: "*City",
                                  selectedItemStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  dropdownHeadingStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  dropdownItemStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  dropdownDialogRadius: 10.0,
                                  searchBarRadius: 10.0,
                                  onCountryChanged: (value) {
                                    setState(() {
                                      countryValue = value;
                                      isCountrySelected = value.isNotEmpty;
                                    });
                                  },
                                  onStateChanged: (value) {
                                    setState(() {
                                      stateValue = value;
                                      isStateSelected =
                                          value != null && value.isNotEmpty;
                                    });
                                  },
                                  onCityChanged: (value) {
                                    setState(() {
                                      cityValue = value;
                                      isCitySelected =
                                          value != null && value.isNotEmpty;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Card(
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.cake),
                                        title: birthDate == null
                                            ? const Text(
                                                "Select your birth date")
                                            : Text(
                                                "Birth Date: ${DateFormat('MM/dd/yyyy').format(birthDate!)}"),
                                        onTap: () async {
                                          final DateTime? pickedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime.now(),
                                          );
                                          if (pickedDate != null &&
                                              pickedDate != birthDate) {
                                            setState(() {
                                              birthDate = pickedDate;
                                            });
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading:
                                            const Icon(Icons.question_answer),
                                        title: Text(
                                          howDidYouHearAboutUs.isEmpty
                                              ? "How did you hear about us?"
                                              : howDidYouHearAboutUs,
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SimpleDialog(
                                                title: const Text(
                                                    'How did you hear about us?'),
                                                children: <Widget>[
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          'Social Media');
                                                    },
                                                    child: const Text(
                                                        'Social Media'),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          'A Friend/Colleague');
                                                    },
                                                    child: const Text(
                                                        'A Friend/Colleague'),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(context,
                                                          'Google/Search Engine');
                                                    },
                                                    child: const Text(
                                                        'Google/Search Engine'),
                                                  ),
                                                  SimpleDialogOption(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          context, 'Other');
                                                    },
                                                    child: const Text('Other'),
                                                  ),
                                                ],
                                              );
                                            },
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                howDidYouHearAboutUs = value;
                                              });
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _signup(context),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:
                                        const Color.fromARGB(255, 101, 79, 161),
                                    backgroundColor: const Color.fromARGB(
                                        255, 255, 255, 255),
                                  ),
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
