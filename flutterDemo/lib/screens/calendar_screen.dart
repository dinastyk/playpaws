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
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<String>> _playdates = {};
  List<String> _upcomingPlaydates = [];

  @override
  void initState() {
    super.initState();
    _loadPlaydates();
  }

  /// Fetch playdates from Firebase and populate the calendar
  Future<void> _loadPlaydates() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('playdates').get();

    Map<DateTime, List<String>> playdateMap = {};
    List<String> upcoming = [];

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      String location = doc['location'];
      String eventDetails = "${DateFormat('MMM dd, hh:mm a').format(date)} - $location";

      playdateMap.putIfAbsent(date, () => []).add(eventDetails);

      if (date.isAfter(DateTime.now())) {
        upcoming.add(eventDetails);
      }
    }

    upcoming.sort();
    if (upcoming.length > 5) upcoming = upcoming.sublist(0, 5);

    setState(() {
      _playdates = playdateMap;
      _upcomingPlaydates = upcoming;
    });
  }

  /// Show a dialog to create a playdate
  void _showCreatePlaydateDialog() async {
    TextEditingController locationController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();
    String? selectedDogId;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user's dog ID
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists || userDoc['dog'] == null) return;

    String userDogId = userDoc['dog'].id; // Reference to the dog document

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
  items: matchedDogs.map<DropdownMenuItem<String>>((dog) {
    String dogName = (dog['dog1Id'] == userDogId) ? dog['dog2Name'] : dog['dog1Name'];
    return DropdownMenuItem<String>(
      value: (dog['dog1Id'] == userDogId) ? dog['dog2Id'] as String : dog['dog1Id'] as String,
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
                    'date': Timestamp.fromDate(selectedDateTime),
                    'location': locationController.text,
                    'dogs': [FirebaseFirestore.instance.doc('dogs/$userDogId'), FirebaseFirestore.instance.doc('dogs/$selectedDogId')],
                    'status': 'Pending',
                  });

                  Navigator.pop(context);
                  _loadPlaydates();
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
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _playdates[day] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          SizedBox(height: 10),
          Text("Upcoming Playdates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _upcomingPlaydates.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_upcomingPlaydates[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaydateDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
