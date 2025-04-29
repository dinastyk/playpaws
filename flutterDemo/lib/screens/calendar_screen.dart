import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
          "${DateFormat('MMMM dd, yyyy').format(date)} - ${doc['location']}";

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

    // Show dialog to create playdate
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Playdate'),
          content: Column(
            children: [
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Here, set the playdate date, in this example using the selected date
                  setState(() {
                    selectedDateTime = DateTime.now();
                  });
                },
                child: Text('Select Date'),
              ),
              SizedBox(height: 10),
              Text("Selected Date: ${DateFormat('MMMM dd, yyyy').format(selectedDateTime)}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String location = locationController.text;
                if (location.isNotEmpty) {
                  // Save the playdate to Firestore
                  await FirebaseFirestore.instance.collection('playdates').add({
                    'date': Timestamp.fromDate(selectedDateTime),
                    'location': location,
                  });
                  // Refresh the playdates list
                  _loadPlaydates();
                  Navigator.pop(context);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Screen'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showCreatePlaydateDialog,
            child: Text('Add Playdate'),
          ),
          SizedBox(height: 20),
          _upcomingPlaydates.isNotEmpty
              ? Expanded(
                  child: ListView.builder(
                    itemCount: _upcomingPlaydates.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_upcomingPlaydates[index]),
                      );
                    },
                  ),
                )
              : Center(
                  child: Text('No upcoming playdates'),
                ),
        ],
      ),
    );
  }
}