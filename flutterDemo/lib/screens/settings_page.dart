import 'package:flutter/material.dart';
import 'profile_ui.dart';

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
              onTap: () 
              {
                Navigator.push
                (
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          
          const Divider(),
          
          ListTile 
          (
            leading: const Icon(Icons.pets),
            title: const Text("Your Pets"),
            subtitle: const Text("See what pets you have, add or remove pets"),
            onTap: () {},
          ),

          const Divider(),
          
          ListTile 
          (
            leading: const Icon(Icons.help),
            title: const Text("Customer Support"),
            subtitle: const Text("Get help"),
            onTap: () {},
          ),

          
        ]
      ),
    );
  }
}