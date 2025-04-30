
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:playpaws_test/screens/calendar_screen.dart';
import 'package:playpaws_test/screens/chats_page.dart';
import 'package:playpaws_test/screens/debug_screen.dart';
import '../firebase_options.dart';
import '../main.dart';
import 'SwipeCard.dart';
import 'CardSwipe.dart';
import 'settings_page.dart';
import 'notifications_page.dart';
import 'messages_page.dart';
import 'login_screen.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
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

  final List<Widget> pages = [
    const HomePage(),
    // const NotificationsPage(),
    const MessagesPage(receiverID: 'f0kBZmUBUFR3ef8zVZwcTiDetB22'),
    const ChatsPage(),
    const CalendarScreen(), // Added new Calendar Page
    const SettingsPage(),
    // const DebugScreen(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPageIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white), 
          ),
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: Colors.white),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF1A69C6),
          indicatorColor: Colors.orange,
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
        // backgroundColor: const Color(0xFF1A69C6), 
        
        // indicatorColor: Colors.orange,
        // selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          // NavigationDestination(
          //   icon: Badge(child: Icon(Icons.notifications_sharp)),
          //   label: 'Notifications',
          // ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.messenger_sharp)),
            label: 'Messages',
          ),
          NavigationDestination
          (
            icon: Icon(Icons.chat_bubble), label: 'Chats',
          ),
                    NavigationDestination(
            icon: Icon(Icons.calendar_today), // Calendar icon
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.settings_sharp)),
            label: 'Settings',
          ),

          // NavigationDestination(
          //   icon: Icon(Icons.bug_report),
          //   label: 'Debug',
          // ),
        ],
      ),
      )
    );
    
  }
}

/*
// 📅 New Calendar Page with "Add to Google Calendar" Button
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  void _addToGoogleCalendar(DateTime playdate) async {
    final formattedDate = playdate.toUtc().toIso8601String().replaceAll(':', '').replaceAll('-', '');
    final url =
        'https://www.google.com/calendar/render?action=TEMPLATE&text=Dog%20Playdate&dates=${formattedDate}/${formattedDate}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calendar")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _addToGoogleCalendar(DateTime.now().add(Duration(days: 1))); // Example: Adds a playdate for tomorrow
          },
          child: Text("Add to Google Calendar"),
        ),
      ),
    );
  }
}
*/


