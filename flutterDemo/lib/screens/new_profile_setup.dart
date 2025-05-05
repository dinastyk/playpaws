import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'choose_preferences.dart';

class NewProfileSetup extends StatefulWidget {
  const NewProfileSetup({Key? key}) : super(key: key);

  @override
  _NewProfileSetupState createState() => _NewProfileSetupState();
}

class _NewProfileSetupState extends State<NewProfileSetup> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dogNameController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  // Default dog age (slider)
  double dogAge = 1;

  // Energy level
  String? selectedEnergyLevel;
  final List<String> energyLevels = ['Low', 'Medium', 'High'];

  // Dog personality selection
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
    'Goofy'
  ]; //Make sure this ist is the same as those listed in new_profile_setup.dart
  List<String> selectedPersonalities = []; // Stores what user selects

  final _formKey = GlobalKey<FormState>();

  Future<void> createAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No authenticated user found.')));
      return;
    }

    try {
      // 1. Get number of existing users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final existingUserCount = usersSnapshot.docs.length;

      int newUserNumber = existingUserCount + 1;
      if (newUserNumber <= 50) {
        newUserNumber = 51; // Force starting at userId51 if users < 50
      }

      final newUserId = 'userId$newUserNumber';
      final newDogId = 'dogId$newUserNumber';

      // 2. Create Dog document manually with ID
      final dogDocRef =
          FirebaseFirestore.instance.collection('dogs').doc(newDogId);
      await dogDocRef.set({
        'name': dogNameController.text.trim(),
        'breed': breedController.text.trim(),
        'age': dogAge,
        'weight': double.parse(weightController.text.trim()),
        'energyLevel': selectedEnergyLevel,
        'personality': selectedPersonalities, // <-- SAVE selected traits
        'dogPictures': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Create User document manually with ID
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'name': nameController.text.trim(),
        'email': user.email,
        'uid': user.uid, // Firebase Authentication UID
        'dog': dogDocRef,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'preferences': {}, // Empty for now
        'preferredPersonalities': [], // Empty for now
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account successfully created!')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChoosePreferences(userDocId: newUserId),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Up Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Your Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Name
                TextFormField(
                  controller: dogNameController,
                  decoration: InputDecoration(labelText: "Dog's Name"),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your dog\'s name'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Breed
                TextFormField(
                  controller: breedController,
                  decoration: InputDecoration(labelText: "Dog's Breed"),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your dog\'s breed'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Weight
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Dog's Weight (lbs)"),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your dog\'s weight'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Age
                Text('Dog\'s Age: ${dogAge.round()} years'),
                Slider(
                  value: dogAge,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: dogAge.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      dogAge = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Dog Energy Level
                DropdownButtonFormField<String>(
                  value: selectedEnergyLevel,
                  decoration: InputDecoration(labelText: 'Dog\'s Energy Level'),
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
                  validator: (value) => value == null
                      ? 'Please select dog\'s energy level'
                      : null,
                ),
                SizedBox(height: 24),

                // Personality Traits
                Text(
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
                SizedBox(height: 24),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        createAccount();
                      }
                    },
                    child: Text('Create Account'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
