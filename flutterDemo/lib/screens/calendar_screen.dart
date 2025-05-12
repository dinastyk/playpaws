import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
Future<void> cleanUpPlaydates() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('playdate')
      .where('status', whereIn: ['cancelled', 'declined'])
      .get();

  for (var doc in snapshot.docs) {
    await doc.reference.delete();
  }
}

Future<String> getUserName(String receiverId) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Query the 'users' collection to get the user's name based on receiverId
  QuerySnapshot userSnapshot = await db
      .collection('users')
      .where('uid', isEqualTo: receiverId)
      .get();

  if (userSnapshot.docs.isNotEmpty) {
    final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
    return userData['name'] ?? 'Unnamed User';  // Return the name, or fallback to 'Unnamed User'
  }

  return 'User not found';  // Return a default message if no user is found
}

Future<DocumentReference?> getDogID() async {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final userData = database.collection("users");
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  QuerySnapshot userSnapshot =
      await userData.where("uid", isEqualTo: user.uid).get();

  if (userSnapshot.docs.isNotEmpty) {
    var doc = userSnapshot.docs.first;
    var data = doc.data() as Map<String, dynamic>;
    return data.containsKey("dog") ? data["dog"] as DocumentReference : null;
  }

  return null;
}
Future<List<Map<String, dynamic>>> fetchMatchedUsers() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  DocumentReference? dogRef = await getDogID();
  if (dogRef == null) return [];

  final matchData = db.collection("matches");

  // Get both directions of accepted matches
  QuerySnapshot matchSnapshot1 = await matchData
      .where("dog1", isEqualTo: dogRef)
      .where("status", isEqualTo: "Accepted")
      .get();

  QuerySnapshot matchSnapshot2 = await matchData
      .where("dog2", isEqualTo: dogRef)
      .where("status", isEqualTo: "Accepted")
      .get();

  Set<DocumentReference> matchedDogRefs = {};

  for (var doc in matchSnapshot1.docs) {
    final data = doc.data() as Map<String, dynamic>;
    matchedDogRefs.add(data["dog2"]);
  }

  for (var doc in matchSnapshot2.docs) {
    final data = doc.data() as Map<String, dynamic>;
    matchedDogRefs.add(data["dog1"]);
  }

  // Retrieve matched users
  List<Map<String, dynamic>> matchedUsers = [];

  for (DocumentReference dog in matchedDogRefs) {
    QuerySnapshot userSnapshot = await db
        .collection("users")
        .where("dog", isEqualTo: dog)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

      // Filter out users with missing or empty uid
      if (userData.containsKey("uid") && (userData["uid"] as String).trim().isNotEmpty) {
        matchedUsers.add({
          "userId": userData["uid"],
          "name": userData["name"] ?? "Unnamed User",
        });
      }
    }
  }

  return matchedUsers;
}



class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _playdates = {}; // Date -> List of playdate docs
  List<Map<String, dynamic>> matchedUsers = []; // Declare matchedUsers

  @override
  void initState() {
    super.initState();
     cleanUpPlaydates();
    _loadMatchedUsers(); // Load matched users on init
    _loadPlaydates();
  }

  Future<void> _loadMatchedUsers() async {
    List<Map<String, dynamic>> users = await fetchMatchedUsers(); // Fetch matched users
    setState(() {
      matchedUsers = users; // Update the matched users list
    });
  }

  Future<void> _loadPlaydates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('playdate')
        .where('status', isNotEqualTo: 'cancelled')
        .get();

    Map<DateTime, List<Map<String, dynamic>>> playdateMap = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime dateTime = (data['date'] as Timestamp).toDate();
      DateTime dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (!playdateMap.containsKey(dateOnly)) {
        playdateMap[dateOnly] = [];
      }

      data['id'] = doc.id;
      playdateMap[dateOnly]!.add(data);
    }

    setState(() {
      _playdates = playdateMap;
    });
  }

  List<Map<String, dynamic>> _getPlaydatesForDay(DateTime day) {
    return _playdates[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _updatePlaydateStatus(String playdateId, String status) async {
    await FirebaseFirestore.instance.collection('playdate').doc(playdateId).update({'status': status});
    _loadPlaydates();
  }

void _showCreatePlaydateDialog() {
  TextEditingController locationController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  String? selectedUserId;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Create Playdate'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    items: matchedUsers.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['userId'],
                        child: Text(user['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() => selectedUserId = value);
                    },
                    hint: Text("Select a user"),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(labelText: 'Location'),
                  ),
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
  String? creatorId = FirebaseAuth.instance.currentUser?.uid;

  if (location.isNotEmpty && selectedUserId != null && creatorId != null) {
    try {
      // Query for conflicting playdates
      QuerySnapshot conflicts = await FirebaseFirestore.instance
          .collection('playdate')
          .where('date', isEqualTo: Timestamp.fromDate(selectedDateTime))
          .where('status', isEqualTo: 'accepted')
          .where(Filter.or(
            Filter('creatorId', isEqualTo: creatorId),
            Filter('receiverId', isEqualTo: creatorId),
            Filter('creatorId', isEqualTo: selectedUserId),
            Filter('receiverId', isEqualTo: selectedUserId),
          ))
          .get();

      if (conflicts.docs.isNotEmpty) {
        // Conflict found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A user already has an accepted playdate at this time.')),
        );
        return;
      }

      // Create the playdate document
      await FirebaseFirestore.instance.collection('playdate').add({
        'creatorId': creatorId,
        'date': Timestamp.fromDate(selectedDateTime),
        'location': location,
        'receiverId': selectedUserId,
        'status': 'pending',
      });

      // Reload playdates
      _loadPlaydates();

      // Close dialog
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create playdate: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill out all fields')),
    );
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
    DateTime day = _selectedDay ?? DateTime.now();
    List<Map<String, dynamic>> events = _getPlaydatesForDay(day);

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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            eventLoader: _getPlaydatesForDay,
          ),
          Expanded(child: _buildEventList(events)),
        ],
      ),
    );
  }

Widget _buildEventList(List<Map<String, dynamic>> events) {
  if (events.isEmpty) {
    return Center(child: Text('No playdates for this day 🐶'));
  }

  return ListView.builder(
    itemCount: events.length,
    itemBuilder: (context, index) {
      var event = events[index];
      String status = event['status'];

      String time = DateFormat('hh:mm a').format((event['date'] as Timestamp).toDate());
      bool isCreator = event['creatorId'] == FirebaseAuth.instance.currentUser?.uid;
      bool isReceiver = event['receiverId'] == FirebaseAuth.instance.currentUser?.uid;
      String id = isCreator ? event['receiverId'] : event['creatorId'];

      Color cardColor;
      if (status == 'accepted') {
        cardColor = Colors.green.shade100;
      } else if (status == 'pending') {
        cardColor = Colors.yellow.shade100;
      } else {
        cardColor = Colors.grey.shade200;
      }

      return Card(
        color: cardColor,
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: FutureBuilder<String>(
          future: getUserName(id), // Fetch username asynchronously
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListTile(
                leading: Icon(Icons.pets),
                title: Text('$time – ${event['location']}'),
                subtitle: Text('Loading...'),
              );
            }

            if (snapshot.hasError) {
              return ListTile(
                leading: Icon(Icons.pets),
                title: Text('$time – ${event['location']}'),
                subtitle: Text('Error loading name'),
              );
            }

            String? name = snapshot.data;

            return ListTile(
              leading: Icon(Icons.pets),
              title: Text('$time – ${event['location']}'),
              subtitle: Text('$name - Status: $status'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'pending' && isReceiver)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          // onPressed: () => _updatePlaydateStatus(event['id'], 'accepted'),
                          onPressed: () async {
  DateTime eventDate = (event['date'] as Timestamp).toDate();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Query for conflicting accepted playdates
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('playdate')
      .where('status', isEqualTo: 'accepted')
      .where('date', isEqualTo: Timestamp.fromDate(eventDate))
      .where(Filter.or(
        Filter('creatorId', isEqualTo: currentUserId),
        Filter('receiverId', isEqualTo: currentUserId),
      ))
      .get();

  if (snapshot.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You already have an accepted playdate at this time')),
    );
    return;
  }

  _updatePlaydateStatus(event['id'], 'accepted');
},

                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                     
                          onPressed: () => _updatePlaydateStatus(event['id'], 'declined'),
                        ),
                      ],
                    ),
                  if ((status == 'pending' && isCreator) || (status == 'accepted' && (isCreator || isReceiver)))
                    IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _updatePlaydateStatus(event['id'], 'cancelled'),
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
}