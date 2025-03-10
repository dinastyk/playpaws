import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../main.dart';

// class TabBarDemo extends StatelessWidget {
//   const TabBarDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//             theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//             seedColor: const Color.fromARGB(255, 55, 90, 180)),
//         useMaterial3: true,
//       ),
//       home: DefaultTabController(
//         length: 3,
//         child: Scaffold(
//           appBar: AppBar(
//             bottom: const TabBar(
//               tabs: [
//                 Tab(icon: Icon(Icons.directions_car)),
//                 Tab(icon: Icon(Icons.directions_transit)),
//                 Tab(icon: Icon(Icons.directions_bike)),
//               ],
//             ),
//             title: const Text('Tabs Demo'),
//           ),
//           body: const TabBarView(
//             children: [
//               MyHomePage(title: 'PlayPaws Demo Home Page'),
//               Icon(Icons.directions_transit),
//               Icon(Icons.directions_bike),
//             ],
//           ),

//         ),
//       ),
//     );
//   }
// } //for top tabs

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(theme: ThemeData(useMaterial3: true), home: const NavigationExample());
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 55, 90, 180)),
          useMaterial3: true,
        ),
        home: const NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // final ThemeData theme =  ThemeData(
    //     colorScheme: ColorScheme.fromSeed(
    //         seedColor: const Color.fromARGB(255, 55, 90, 180)),
    //     useMaterial3: true,
    //   );
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.messenger_sharp)),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.settings_sharp)),
            label: 'Settings'),
        ],
      ),
      body: <Widget>[
        /// Home page
        // Card(
        //   shadowColor: Colors.transparent,
        //   margin: const EdgeInsets.all(8.0),
        //   child: SizedBox.expand(
        //     child: Center(child: Text('Home page', style: theme.textTheme.titleLarge)),
        //   ),
        // ),
        MyHomePage(title: "PlayPaws Demo Home Page"),

        /// Notifications page
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 1'),
                  subtitle: Text('This is a notification'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 2'),
                  subtitle: Text('This is a notification'),
                ),
              ),
            ],
          ),
        ),

        /// Messages page
        MessagesPage(),
        ListView
        (
          children: 
          [
            ListTile
            (
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              subtitle: const Text("Manage your account"),
              trailing: PopupMenuButton<String>
              (
                onSelected: (value) 
                {

                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>
                [
                  const PopupMenuItem<String>
                  (
                    value: 'view',
                    child: Text('View Profile'),
                  )
                ]

              ),
              //onTap: () {},
            )
          ]
        ),


      ][currentPageIndex],
    );
  }
}

class MessagesPage extends StatefulWidget
{
  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage>
{
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  //final List<String> _messages = [];

  @override
  void dispose()
  {
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async
  {
    if (_messageController.text.isNotEmpty)
    {
      await _firestore.collection('chats').doc('chat1').collection('messages').add 
      ({
        'text': _messageController.text,
        'senderID': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

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
            stream: _firestore
            .collection('chats')
            .doc('chat1')
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot)
            {
              if (!snapshot.hasData)
              {
                return const Center(child: CircularProgressIndicator());
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


