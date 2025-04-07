import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("🧪 Firebase UID: $uid");

    if (uid == null) {
      debugPrint("🚨 UID is null — user not logged in?");
      return;
    }

    // Step 1: Query Firestore for the user document with matching UID
    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      debugPrint("🚨 No user found for UID: $uid");
      return;
    }

    final userSnapshot = userQuery.docs.first;
    final userData = userSnapshot.data();
    debugPrint("✅ User data: $userData");

    // 🔥 Updated for DocumentReference
    final DocumentReference dogRef = userData['dog'];
    final dogSnapshot = await dogRef.get();

    if (!dogSnapshot.exists) {
      debugPrint("🚨 Dog document not found at ref: $dogRef");
      return;
    }

    final dogData = dogSnapshot.data() as Map<String, dynamic>;
    debugPrint("✅ Dog data: $dogData");

    setState(() {
      ownerName = userData['name'];
      profilePictureURL = userData['profilePictureURL'];
      dogName = dogData['name'];
      breed = dogData['breed'];
      age = dogData['age'];
      weight = dogData['weight'].toDouble();
      energyLevel = dogData['energyLevel'];
      personalityTraits = List<String>.from(dogData['personality']);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PlayPaws Profile"),
        backgroundColor: const Color(0xFF1A69C6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E4FF),
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
                // 👇 Wrap this in Flexible
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Owner: $ownerName",
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Dog: $dogName",
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text("All Photos"),
            Row(
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.all(4.0),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.photo_outlined)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoField("Breed", breed),
            _buildInfoField("Age", "$age years"),
            _buildInfoField("Weight", "$weight kg"),
            _buildInfoField("Energy Level", energyLevel),
            _buildInfoField("Personality Traits", personalityTraits.join(", ")), 
            
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9874),
              ),
              child: const Text("Edit Profile"),
            ),
          ],
        ),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
