import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchPlaydates();
  }

  Future<void> _fetchPlaydates() async {
    final snapshot = await FirebaseFirestore.instance.collection('playdates').get();

    Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var doc in snapshot.docs) {
      if (doc.data().containsKey('date')) {
        final Timestamp timestamp = doc['date'];
        final DateTime date = timestamp.toDate();

        final DateTime eventDay = DateTime(date.year, date.month, date.day);

        final String formattedTime = DateFormat('hh:mm a').format(date);
        final GeoPoint location = doc['location'];
        final String details = '${formattedTime} - Location: ${location.latitude}, ${location.longitude}';

        if (!events.containsKey(eventDay)) {
          events[eventDay] = [];
        }
        events[eventDay]!.add({
          'time': formattedTime,
          'location': location,
          'details': details,
        });
      }
    }

    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _showCreatePlaydateDialog() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    TextEditingController locationLatController = TextEditingController();
    TextEditingController locationLngController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Create Playdate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: Text('Select Date'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: Text('Select Time'),
                ),
                TextField(
                  controller: locationLatController,
                  decoration: InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: locationLngController,
                  decoration: InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final double? lat = double.tryParse(locationLatController.text);
                  final double? lng = double.tryParse(locationLngController.text);

                  if (lat != null && lng != null) {
                    final DateTime finalDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    await FirebaseFirestore.instance.collection('playdates').add({
                      'date': Timestamp.fromDate(finalDateTime),
                      'location': GeoPoint(lat, lng),
                      'status': 'Confirmed',
                      // Add 'dogIDs' and 'confirmedDogOwners' as needed
                    });

                    Navigator.pop(context);
                    _fetchPlaydates();
                  }
                },
                child: Text('Create'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsToday = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreatePlaydateDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: eventsToday.length,
              itemBuilder: (context, index) {
                final event = eventsToday[index];
                return ListTile(
                  leading: Icon(Icons.pets),
                  title: Text(event['details']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
