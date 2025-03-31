import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  List<DateTime> playdates = [];

  @override
  void initState() {
    super.initState();
    _loadPlaydates(); // Load playdates when screen opens
  }

  Future<void> _loadPlaydates() async {
    if (user == null) return;

    QuerySnapshot snapshot = await _db
        .collection('users')
        .doc(user!.uid)
        .collection('playdates')
        .orderBy('date', descending: false)
        .get();

    setState(() {
      playdates = snapshot.docs
          .map((doc) => (doc['date'] as Timestamp).toDate())
          .toList();
    });
  }

  Future<void> _addPlaydate(DateTime playdate) async {
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user!.uid)
        .collection('playdates')
        .add({'date': playdate});

    setState(() {
      playdates.add(playdate);
    });

    _addToGoogleCalendar(playdate);
  }

  Future<void> _deletePlaydate(int index) async {
    if (user == null) return;

    QuerySnapshot snapshot = await _db
        .collection('users')
        .doc(user!.uid)
        .collection('playdates')
        .where('date', isEqualTo: playdates[index])
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      playdates.removeAt(index);
    });
  }

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null) return;

    DateTime fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    _addPlaydate(fullDateTime);
  }

  Future<void> _addToGoogleCalendar(DateTime playdate) async {
    final formattedDate = playdate.toUtc().toIso8601String().replaceAll(':', '').replaceAll('-', '');
    final url =
        'https://www.google.com/calendar/render?action=TEMPLATE&text=Dog%20Playdate&dates=${formattedDate}/${formattedDate}';

    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Calendar ❌')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playdate added to Google Calendar! ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📅 Calendar")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Plan & Book Your Playdates!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Choose a date and time for your dog's playdate, then add it to your Google Calendar.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text("Pick Date & Time"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: playdates.length,
                itemBuilder: (context, index) {
                  DateTime playdate = playdates[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(Icons.pets, color: Colors.blue),
                      title: Text(
                        DateFormat('EEE, MMM d, yyyy – hh:mm a').format(playdate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlaydate(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
