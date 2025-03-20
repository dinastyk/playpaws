import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget
{
  const SettingsPage({super.key});

  @override 
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: ListView
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
                if (value == 'view')
                {
                  //go to profile
                }
                else if (value == 'edit')
                {
                  //go to edit profile
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>
              [
                const PopupMenuItem<String>
                (
                  value: 'view',
                  child: Text('View Profile'),
                ),
                const PopupMenuItem<String>
                (
                  value: 'edit',
                  child: Text('Edit Profile'),
                )
              ]  
            ),
          )
        ]
      ),
    );
  }
}