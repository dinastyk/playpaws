import 'package:flutter/material.dart';
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
  Map<DateTime, List<String>> _events = {}; // Store events for each day

  @override
  void initState() {
    super.initState();
    _events = {
      DateTime.now(): ["Morning Walk", "Evening Playdate"],
      DateTime.now().add(Duration(days: 1)): ["Vet Appointment"],
    };
  }

  void _addPlaydate() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController eventController = TextEditingController();
        return AlertDialog(
          title: Text("Add Playdate"),
          content: TextField(
            controller: eventController,
            decoration: InputDecoration(hintText: "Enter event name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _events[_selectedDay] = (_events[_selectedDay] ?? [])..add(eventController.text);
                });
                Navigator.pop(context);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          SizedBox(height: 10),
          Text("Playdates on ${_selectedDay.toLocal().toString().split(' ')[0]}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              children: (_events[_selectedDay] ?? []).map((event) {
                return ListTile(
                  title: Text(event),
                  leading: Icon(Icons.event),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlaydate,
        child: Icon(Icons.add),
      ),
    );
  }
}