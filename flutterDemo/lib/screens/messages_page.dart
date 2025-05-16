import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../firebase_options.dart';


class MessagesPage extends StatefulWidget
{
  final String receiverID;
  const MessagesPage({super.key, required this.receiverID});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage>
{
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  late String receiverID;
  String ? chatID;
  //final List<String> _messages = [];
  
  @override 
  
  void initState()
  {
    super.initState();
    
    //receiverID = 'f0kBZmUBUFR3ef8zVZwcTiDetB22';
    //chatID = user!.uid.hashCode != receiverID.hashCode 
    //? "${user!.uid}_$receiverID"
    //: "${receiverID}_${user!.uid}";
    
    
    receiverID = widget.receiverID;
    //receiverID = 'ounIJ5GiN1aUKc11nIPJfv6TPHE2'; //testing
    List<String> ids = [user!.uid, receiverID];
    ids.sort();
    chatID = ids.join("_"); 
    //print('UserID: $user');
    print('ChatID: $chatID');   // testing if chat is working properl
    print('ReceiverID: $receiverID');
    /*
    Use reference!!!
    User the “reference” field type to “sync” the recieverID and senderID to appropriate UserIDs
    Corresponding UserID
    */

  } 

  @override
  void dispose()
  {
    _messageController.dispose();
    super.dispose();
  }
void _openPlaydateDialog() {
  final locationController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  final creatorId = FirebaseAuth.instance.currentUser?.uid;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Schedule Playdate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  child: const Text('Select Date & Time'),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
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
                ),
                const SizedBox(height: 8),
               Text(
  "Selected: ${DateFormat('MMMM dd, yyyy – hh:mm a').format(selectedDateTime)}",
  style: TextStyle(fontSize: 14),
),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Schedule'),
                onPressed: () async {
                  final location = locationController.text.trim();
                  if (location.isNotEmpty && creatorId != null && receiverID.isNotEmpty) {
                    try {
                      final conflicts = await FirebaseFirestore.instance
                          .collection('playdate')
                          .where('date', isEqualTo: Timestamp.fromDate(selectedDateTime))
                          .where('status', isEqualTo: 'accepted')
                          .where(Filter.or(
                            Filter('creatorId', isEqualTo: creatorId),
                            Filter('receiverId', isEqualTo: creatorId),
                            Filter('creatorId', isEqualTo: receiverID),
                            Filter('receiverId', isEqualTo: receiverID),
                          ))
                          .get();

                      if (conflicts.docs.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('A user already has an accepted playdate at this time.')),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection('playdate').add({
                        'creatorId': creatorId,
                        'date': Timestamp.fromDate(selectedDateTime),
                        'location': location,
                        'receiverId': receiverID,
                        'status': "pending",
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Playdate scheduled!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create playdate: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill out all fields')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  void sendMessage() async 
  {
    if (user == null) 
    {
      print('User not authenticated!');
      return;
    }

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final chatDocRef = _firestore.collection('chats').doc(chatID);

    final chatSnapshot = await chatDocRef.get();

    if (!chatSnapshot.exists) 
    {
      // Create chat document with participants and timestamp
      final userRef = _firestore.collection('users').doc(user!.uid);
      final receiverRef = _firestore.collection('users').doc(receiverID);
      
      await chatDocRef.set
      ({
        'participants': [userRef, receiverRef],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': messageText,
      });
    } 
    else 
    {
      // Update lastMessage
      await chatDocRef.update
      ({
        'lastMessage': messageText,
      });
    }

    // Add message to messages subcollection
    await chatDocRef.collection('messages').add
    ({
      'receiverID': receiverID,
      'senderID': user!.uid,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    await deleteEmptyChatsWithSameParticipants(user!.uid, receiverID);

  }
  
  /*
  void sendMessage() async
  {
    if (user == null)
    {
      print('User not authenticated!');
      return;
    }
    if (_messageController.text.isNotEmpty)
    {
      await _firestore.collection('chats').doc(chatID).collection('messages').add 
      ({
        'receiverID': receiverID,
        'senderID': user?.uid,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }
  */

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      // appBar: AppBar(title: const Text('Messages'),),
      appBar: AppBar(
  title: const Text('Messages'),
  actions: [
    IconButton(
      icon: const Icon(Icons.calendar_today),
      onPressed: _openPlaydateDialog,
    ),
  ],
),
      body: 
      Column
      (
        children: 
        [
          Expanded
          (
            child: StreamBuilder<QuerySnapshot>
            (
              stream: chatID != null ? _firestore
              .collection('chats')
              .doc(chatID)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .snapshots()
              : null,
              builder: (context, snapshot)
              {
                if (chatID == null)
                {
                  return const Center(child: Text("Unable to load messages. User not authenticated."));
                }
                if(snapshot.hasError)
                {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                {
                  return const Center(child: Text("No Messages Yet!"));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder
                (
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index)
                  {
                    print("senderID: ${messages[index]['senderID']}, current user: ${user?.uid}");
                    final message = messages[index]['text'];
                    final myMessage = messages[index]['senderID'] == user?.uid;

                    final timestamp = messages[index]['timestamp'] as Timestamp?;
                    final Time = timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : 'Sending...';
                    
                    return Align
                    (
                      alignment: myMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container
                      (
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        constraints: BoxConstraints
                        (
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration
                        (
                          color: myMessage ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column
                        (
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: 
                          [
                            Text
                            (
                              message, style: Theme.of(context).textTheme.bodyLarge!.copyWith
                              (
                                color: myMessage ? Theme.of(context).colorScheme.onPrimary : Colors.black,
                              ),
                            ),

                            const SizedBox(height: 4),
                            Text
                            (
                              Time, style: Theme.of(context).textTheme.bodySmall!.copyWith
                              (
                                color: myMessage ? Theme.of(context).colorScheme.onPrimary : Colors.black54, fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding
          (
            padding: const EdgeInsets.all(8.0),
            child: Row
            (
              children: 
              [
                Expanded
                (
                  child: TextField
                  (
                    controller: _messageController,
                    decoration: const InputDecoration
                    (
                      hintText: 'Type a message ...',
                    ),
                  ),
                ),
                IconButton
                (
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}


Future<void> deleteEmptyChatsWithSameParticipants(String uid1, String uid2) async {
  final firestore = FirebaseFirestore.instance;
  final user1Ref = firestore.doc('users/$uid1');
  final user2Ref = firestore.doc('users/$uid2');

  final querySnapshot = await firestore
      .collection('chats')
      .where('participants', arrayContains: user1Ref)
      .get();

  for (final doc in querySnapshot.docs) {
    final data = doc.data();
    final participants = List<DocumentReference>.from(data['participants']);

    final hasBoth = participants.contains(user1Ref) && participants.contains(user2Ref);
    final lastMessage = data['lastMessage'];

    if (hasBoth && (lastMessage == null || lastMessage.toString().trim().isEmpty)) {
      await doc.reference.delete();
    }
  }
}
