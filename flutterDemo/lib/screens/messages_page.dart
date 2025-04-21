import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
    
    
    //receiverID = widget.receiverID;
    receiverID = 'ounIJ5GiN1aUKc11nIPJfv6TPHE2'; //testing
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
    return Column
    (
      children: 
      [
        Expanded
        (
          child: StreamBuilder
          (
            stream: chatID != null ? _firestore
            .collection('chats')
            .doc(chatID)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots()
            : null,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot)
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
                  final message = messages[index]['text'];
                  final myMessage = messages[index]['senderID'] == user?.uid;
                  return Align
                  (
                    alignment: myMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container
                    (
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration
                      (
                        color: myMessage ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text
                      (
                        message, 
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith
                        (
                          color: myMessage ? Theme.of(context).colorScheme.onPrimary : Colors.black,
                        )
                      )
                    )
                  );
                }
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
                )
              ),
              IconButton
              (
                icon: const Icon(Icons.send),
                onPressed: sendMessage,
              )
            ]
          )
        )
      ]
    );
  }
}


