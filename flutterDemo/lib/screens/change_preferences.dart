import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:playpaws_test/services/send_data_service.dart';
import 'navigation_bar.dart';

class ChangePreferences extends StatefulWidget {
  const ChangePreferences({super.key});

  @override
  _ChangePreferencesState createState() => _ChangePreferencesState();
}

class _ChangePreferencesState extends State<ChangePreferences> {
  final List<String> energyLevels = ['Low', 'Medium', 'High'];

  double minAge = 0;
  double maxAge = 15;
  double maxWeight = 100;

  String? selectedEnergyLevel;
  List<String> selectedPersonalities = [];

  final List<String> personalities = [
    'Friendly', 'Playful', 'Shy', 'Aggressive', 'Protective',
    'Curious', 'Exciteable', 'Calm', 'Anxious', 'Clever',
    'Goofy', 'Laidback', 'Social', 'Active', 'Sensitive', 'Stuborn'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userData = userQuery.docs.first.data();
    final prefs = userData['preferences'] ?? {};

    setState(() {
      selectedEnergyLevel = prefs['energyLevel'];
      minAge = (prefs['minAge'] ?? 0).toDouble();
      maxAge = (prefs['maxAge'] ?? 15).toDouble();
      maxWeight = (prefs['maxWeight'] ?? 100).toDouble();
      selectedPersonalities = List<String>.from(prefs['preferredPersonalities'] ?? []);
    });
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final preferences = {
      'energyLevel': selectedEnergyLevel,
      'minAge': minAge.round(),
      'maxAge': maxAge.round(),
      'maxWeight': maxWeight.round(),
      'preferredPersonalities': selectedPersonalities.toList(),
    };

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userDocId = userQuery.docs.first.id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .update({'preferences': preferences});

    await sendEmbeddingRequest();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences updated!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NavigationExample()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Playdate Preferences')),
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
                          if (!selectedPersonalities.contains(trait)) {
                            selectedPersonalities.add(trait);
                          }
                        } else {
                          selectedPersonalities = selectedPersonalities.where((t) => t != trait).toList();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _savePreferences,
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
