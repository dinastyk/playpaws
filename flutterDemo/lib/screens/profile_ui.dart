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

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    DocumentSnapshot userSnapshot = await _firestore.collection('users').doc('userId1').get();
    DocumentSnapshot dogSnapshot = await _firestore.collection('dogs').doc('dogId1').get();

    setState(() {
      ownerName = userSnapshot['name'];
      dogName = dogSnapshot['name'];
      breed = dogSnapshot['size'];
      age = dogSnapshot['updatedAt'].toDate().year - 2020; // Assuming birth year 2020
      weight = dogSnapshot['weight'].toDouble();
      energyLevel = dogSnapshot['energyLevel'];
      personalityTraits = List<String>.from(dogSnapshot['personality']);
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
                  ),
                  child: const Center(child: Text("No Photo")),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Owner: $ownerName", style: Theme.of(context).textTheme.titleMedium),
                    Text("Dog: $dogName", style: Theme.of(context).textTheme.titleMedium),
                  ],
                )
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
