import 'package:flutter/material.dart';


class NotificationsPage extends StatelessWidget
{
  const NotificationsPage({super.key});

  @override 
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: const Padding
      (
        padding: EdgeInsets.all(8.0),
        child: Column
        (
          children: <Widget>
          [
            Card
            (
              child: ListTile
              (
                leading: Icon(Icons.notifications_sharp),
                title: Text('Notification 1'),
                subtitle: Text('This is a notification'),
              ),
            ),
            Card
            (
              child: ListTile
              (
                leading: Icon(Icons.notifications_sharp),
                title: Text('Notification 2'),
                subtitle: Text('This is a notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}