import 'package:flutter/material.dart';
import 'package:playpaws_test/screens/login_screen.dart';
import 'profile_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SettingsPage extends StatelessWidget
{
  const SettingsPage({super.key});

  @override 
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: Stack 
      (
        children: 
        [
          ListView
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
                /*
              
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
              */
            ],
          ),
          Align
          (
            alignment: Alignment.bottomRight,
            child: Padding
            (
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton
              (
                onPressed: () async
                {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted)
                  {
                    Navigator.of(context).pushReplacement
                    (
                      MaterialPageRoute(builder: (context) => LoginScreen())
                    );
                  }
                },
                child: Text("Logout"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}