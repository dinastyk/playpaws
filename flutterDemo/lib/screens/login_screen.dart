import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'navigation_bar.dart';
//import 'profile_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1E4FF),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🐾 LOGO IMAGE
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),

            // 📨 Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            // 🔐 Password Field
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            // ✉️ Login with Email
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Color(0xFFFF9874)),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;
                var user = await authService.signInWithEmailPassword(email, password);

                if (user != null) {
                  debugPrint("Logged in as: ${user.email}");
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => NavigationExample()),
                  );
                } else {
                  debugPrint("Login failed.");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Login failed. Please try again.")),
                  );
                }
              },
              child: const Text("Login with Email"),
            ),

            const SizedBox(height: 10),

            // 🔐 Login with Google
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Color(0xFFFF9874)),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                var user = await authService.signInWithGoogle();

                if (user != null) {
                  debugPrint("Logged in as: ${user.displayName}");
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => NavigationExample()),
                  );
                } else {
                  debugPrint("Google Sign-In failed.");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Google Sign-In failed.")),
                  );
                }
              },
              child: const Text("Login with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
