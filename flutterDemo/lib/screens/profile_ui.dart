import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:playpaws_test/screens/login_screen.dart';
import 'settings_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const PlayPawsProfile());
}

class PlayPawsProfile extends StatelessWidget {
  const PlayPawsProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String ownerName = "Loading...";
  String dogName = "Loading...";
  String breed = "Loading...";
  int age = 0;
  double weight = 0.0;
  String energyLevel = "Loading...";
  List<String> personalityTraits = [];
  String profilePictureURL = "";
  List<String> dogPictures = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userSnapshot = userQuery.docs.first;
    final userData = userSnapshot.data();
    final DocumentReference dogRef = userData['dog'];
    final dogSnapshot = await dogRef.get();

    if (!dogSnapshot.exists) return;

    final dogData = dogSnapshot.data() as Map<String, dynamic>;

    setState(() {
      ownerName = userData['name'];
      profilePictureURL = userData['profilePictureURL'];
      dogName = dogData['name'];
      breed = dogData['breed'];
      age = dogData['age'];
      weight = dogData['weight'].toDouble();
      energyLevel = dogData['energyLevel'];
      personalityTraits = List<String>.from(dogData['personality']);
      dogPictures = List<String>.from(dogData['dogPictures'] ?? []);
    });
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFD1E4FF);
    const buttonColor = Color(0xFFFF9874);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: buttonColor),
          onPressed: () 
          {
            Navigator.pop(context);
          }
          /*
          {
            Navigator.push
            (
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          */
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: buttonColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        image: profilePictureURL.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profilePictureURL),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profilePictureURL.isEmpty
                          ? const Center(child: Text("No Photo"))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Owner: $ownerName",
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                          Text("Dog: $dogName",
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("All Photos"),
                dogPictures.isNotEmpty
                    ? CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.5,
                        ),
                        items: dogPictures.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () => _openFullScreenImage(url),
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      )
                    : Row(
                        children: List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.all(4.0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Icon(Icons.photo_outlined)),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                _buildInfoField("Breed", breed),
                _buildInfoField("Age", "$age years"),
                // _buildInfoField("Weight", "$weight kg"),
                 _buildInfoField("Weight", "${weight.toStringAsFixed(2)} kg"),
                _buildInfoField("Energy Level", energyLevel),
                _buildInfoField("Personality Traits", personalityTraits.join(", ")),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
              ),
              child: const Text("Edit Profile"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  backgroundColor: Colors.black,
  automaticallyImplyLeading: false, // disables default back button
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
    onPressed: () {
      Navigator.pop(context); // go back to the previous screen
    },
  ),
  title: const Text("Photo", style: TextStyle(color: Colors.white)),
),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
