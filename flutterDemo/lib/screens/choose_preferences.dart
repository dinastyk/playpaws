import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpaws_test/services/send_data_service.dart';
import 'navigation_bar.dart';

class ChoosePreferences extends StatefulWidget {
  final String userDocId;
  const ChoosePreferences({Key? key, required this.userDocId})
      : super(key: key);

  @override
  _ChoosePreferencesState createState() => _ChoosePreferencesState();
}

class _ChoosePreferencesState extends State<ChoosePreferences> {
  // Preferences
  String? selectedEnergyLevel;
  final List<String> energyLevels = ['Low', 'Medium', 'High'];

  double minAge = 0;
  double maxAge = 15;
  double maxWeight = 100;

  final List<String> personalities = [
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
    'Stuborn'
  ]; //Make sure this ist is the same as those listed in new_profile_setup.dart
  List<String> selectedPersonalities = [];

  Future<void> savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final preferences = {
      'energyLevel': selectedEnergyLevel,
      'minAge': minAge.round(),
      'maxAge': maxAge.round(),
      'maxWeight': maxWeight.round(),
      'preferredPersonalities': selectedPersonalities,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userDocId)
        .update({
      'preferences': preferences,
    });
await sendEmbeddingRequest();;
    // Navigate to next page or show confirmation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NavigationExample()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What Would You Prefer In a Playdate?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Energy Level', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: selectedEnergyLevel,
                hint: const Text('Select energy level'),
                items: energyLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedEnergyLevel = value);
                },
              ),
              const SizedBox(height: 20),
              const Text('Age Range', style: TextStyle(fontSize: 16)),
              RangeSlider(
                values: RangeValues(minAge, maxAge),
                min: 0,
                max: 20,
                divisions: 20,
                labels: RangeLabels('${minAge.round()}', '${maxAge.round()}'),
                onChanged: (values) {
                  setState(() {
                    minAge = values.start;
                    maxAge = values.end;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('Maximum Weight', style: TextStyle(fontSize: 16)),
              Slider(
                value: maxWeight,
                min: 0,
                max: 150,
                divisions: 30,
                label: '${maxWeight.round()} lbs',
                onChanged: (value) {
                  setState(() => maxWeight = value);
                },
              ),
              const SizedBox(height: 20),
              const Text('Personality Traits', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8,
                children: personalities.map((trait) {
                  final isSelected = selectedPersonalities.contains(trait);
                  return FilterChip(
                    label: Text(trait),
                    selected: isSelected,
                    onSelected: (bool selected) {
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
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: savePreferences,
                  child: const Text('Save Preferences'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
