import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now(); // Define _focusedDay
  List<String> _upcomingPlaydates = [];

  @override
  void initState() {
    super.initState();
    _loadPlaydates();
  }

  /// Fetch playdates from Firebase
  Future<void> _loadPlaydates() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('playdates').get();

    List<String> upcoming = [];

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String eventDetails =
          "${DateFormat('MMM dd, hh:mm a').format(date)} - ${doc['location']}";

      if (date.isAfter(DateTime.now())) {
        upcoming.add(eventDetails);
      }
    }

    upcoming.sort();
    if (upcoming.length > 5) upcoming = upcoming.sublist(0, 5);

    setState(() {
      _upcomingPlaydates = upcoming;
    });
  }

  void _showCreatePlaydateDialog() async {
    TextEditingController locationController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();
    String? selectedDogId; // Nullable because it starts as unselected

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user's dog ID
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists || userDoc['dogId'] == null) return;

    String userDogId = userDoc['dogId'];

    // Fetch matched dogs
    QuerySnapshot matchSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('status', isEqualTo: 'Accepted')
        .where(Filter.or(
          Filter("dog1", isEqualTo: userDogId),
          Filter("dog2", isEqualTo: userDogId),
        ))
        .get();

    List<Map<String, dynamic>> matchedDogs = [];

    for (var doc in matchSnapshot.docs) {
      String dog1Id = doc['dog1'];
      String dog2Id = doc['dog2'];

      // Fetch dog details
      DocumentSnapshot dog1Doc =
          await FirebaseFirestore.instance.collection('dogs').doc(dog1Id).get();
      DocumentSnapshot dog2Doc =
          await FirebaseFirestore.instance.collection('dogs').doc(dog2Id).get();

      if (dog1Doc.exists && dog2Doc.exists) {
        matchedDogs.add({
          'dog1Id': dog1Id,
          'dog2Id': dog2Id,
          'dog1Name': dog1Doc['name'],
          'dog2Name': dog2Doc['name'],
        });
      }
    }

    // Show dialog for selecting a playdate
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create Playdate"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: Text("Select Matched Dog"),
                value: selectedDogId,
                onChanged: (value) {
                  setState(() {
                    selectedDogId = value!;
                  });
                },
                items: matchedDogs.map((dog) {
                  String dogName =
                      (dog['dog1Id'] == userDogId) ? dog['dog2Name'] : dog['dog1Name'];
                  return DropdownMenuItem(
                    value: (dog['dog1Id'] == userDogId) 
                    ? dog['dog2Id'] as String 
                    : dog['dog1Id'] as String,
                    child: Text(dogName),
                  );
                }).toList(),
              ),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: "Location"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDogId == null || locationController.text.isEmpty) return;

                  await FirebaseFirestore.instance.collection('playdates').add({
                    'date': selectedDateTime,
                    'location': locationController.text,
                    'dog1': userDogId,
                    'dog2': selectedDogId,
                  });

                  Navigator.pop(context);
                  _loadPlaydates(); // Refresh playdates list
                },
                child: Text("Create"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Playdate Calendar")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 01, 01),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _showCreatePlaydateDialog,
            child: Text("Schedule a Playdate"),
          ),
          SizedBox(height: 10),
          Text("Upcoming Playdates:"),
          ..._upcomingPlaydates.map((playdate) => ListTile(title: Text(playdate))),
        ],
      ),
    );
  }
}
