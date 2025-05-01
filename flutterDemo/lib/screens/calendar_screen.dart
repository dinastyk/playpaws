import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _playdates = {}; // Date -> List of Events

  @override
  void initState() {
    super.initState();
    _loadPlaydates();
  }

  Future<void> _loadPlaydates() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('playdates').get();

    Map<DateTime, List<String>> playdateMap = {};

    for (var doc in snapshot.docs) {
      DateTime dateTime = (doc['date'] as Timestamp).toDate();
      String location = doc['location'] ?? 'Unknown Location';

      DateTime dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      String eventDetails =
          "${DateFormat('hh:mm a').format(dateTime)} - $location";

      if (!playdateMap.containsKey(dateOnly)) {
        playdateMap[dateOnly] = [];
      }
      playdateMap[dateOnly]!.add(eventDetails);
    }

    setState(() {
      _playdates = playdateMap;
    });
  }

  List<String> _getPlaydatesForDay(DateTime day) {
    return _playdates[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _showCreatePlaydateDialog() {
    TextEditingController locationController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Create Playdate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(labelText: 'Location'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text('Select Date & Time'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Selected: ${DateFormat('MMMM dd, yyyy – hh:mm a').format(selectedDateTime)}",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String location = locationController.text.trim();
                    if (location.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('playdates').add({
                        'date': Timestamp.fromDate(selectedDateTime),
                        'location': location,
                      });
                      await _loadPlaydates();
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text('Playdate Calendar'),
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
            lastDay: DateTime.utc(2100, 12, 31),
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
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) => _getPlaydatesForDay(day),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    DateTime day = _selectedDay ?? DateTime.now();
    List<String> events = _getPlaydatesForDay(day);

    if (events.isEmpty) {
      return Center(
        child: Text('No playdates for this day 🐶'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: ListTile(
            leading: Icon(Icons.pets, color: Colors.deepPurple),
            title: Text(events[index]),
          ),
        );
      },
    );
  }
}
