import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:playpaws_test/screens/login_screen.dart';
import 'settings_page.dart';
import '../main.dart';

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

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
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
    _fetchProfileData(); // ✅ Ensure profile fetches on first screen push
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _fetchProfileData();
  }

  @override
  void didPopNext() {
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
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
      profilePictureURL = userData['profilePictureURL'] ?? "";
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: buttonColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                const Text("Photos"),
                dogPictures.isNotEmpty
                    ? CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.5,
                        ),
                        items: dogPictures.map((url) {
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(url),
                            child: Container(
                              width: 150,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : const Text("No dog photos available."),
                const SizedBox(height: 16),
                _buildInfoField("Breed", breed),
                _buildInfoField("Age", "$age years"),
                _buildInfoField("Weight", "${weight.toStringAsFixed(2)} kg"),
                _buildInfoField("Energy Level", energyLevel),
                _buildInfoField(
                    "Personality Traits", personalityTraits.join(", ")),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      ownerName: ownerName,
                      dogName: dogName,
                      breed: breed,
                      age: age,
                      weight: weight,
                      energyLevel: energyLevel,
                      personalityTraits: personalityTraits,
                    ),
                  ),
                );
              },
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
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

class EditProfileScreen extends StatefulWidget {
  final String ownerName, dogName, breed, energyLevel;
  final int age;
  final double weight;
  final List<String> personalityTraits;

  const EditProfileScreen({
    super.key,
    required this.ownerName,
    required this.dogName,
    required this.breed,
    required this.age,
    required this.weight,
    required this.energyLevel,
    required this.personalityTraits,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController ownerController;
  late TextEditingController dogController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController weightController;

  final List<String> energyLevels = ['Low', 'Medium', 'High'];
  String? selectedEnergyLevel;

  final List<String> availablePersonalities = [
    'Friendly',
    'Playful',
    'Shy',
    'Aggressive',
    'Protective',
    'Curious',
    'Exciteable',
    'Calm',
    'Anxious',
    'Clever',
    'Goofy',
    'Laidback',
    'Social',
    'Active',
    'Sensitive',
    'Stubborn'
  ];
  late List<String> selectedPersonalities;

  @override
  void initState() {
    super.initState();
    ownerController = TextEditingController(text: widget.ownerName);
    dogController = TextEditingController(text: widget.dogName);
    breedController = TextEditingController(text: widget.breed);
    ageController = TextEditingController(text: widget.age.toString());
    weightController = TextEditingController(text: widget.weight.toString());
    selectedEnergyLevel = widget.energyLevel;
    selectedPersonalities = List<String>.from(widget.personalityTraits);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userSnapshot = userQuery.docs.first;
    final DocumentReference dogRef = userSnapshot['dog'];

    await userSnapshot.reference.update({
      'name': ownerController.text.trim(),
    });

    await dogRef.update({
      'name': dogController.text.trim(),
      'breed': breedController.text.trim(),
      'age': int.tryParse(ageController.text.trim()) ?? widget.age,
      'weight': double.tryParse(weightController.text.trim()) ?? widget.weight,
      'energyLevel': selectedEnergyLevel,
      'personality': selectedPersonalities,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Owner Name', ownerController),
              _buildTextField('Dog Name', dogController),
              _buildTextField('Breed', breedController),
              _buildTextField('Age', ageController, isNumber: true),
              _buildTextField('Weight (kg)', weightController, isDecimal: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedEnergyLevel,
                decoration: const InputDecoration(
                  labelText: 'Dog\'s Energy Level',
                  border: OutlineInputBorder(),
                ),
                items: energyLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEnergyLevel = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select dog\'s energy level' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Dog\'s Personality Traits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: availablePersonalities.map((trait) {
                  final isSelected = selectedPersonalities.contains(trait);
                  return ChoiceChip(
                    label: Text(trait),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedPersonalities.add(trait);
                        } else {
                          selectedPersonalities.remove(trait);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool isDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required field';
          return null;
        },
      ),
    );
  }
}
