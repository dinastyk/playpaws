import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'navigation_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); //added key param
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  @override //Everything below @override deals with UI design, everything above is functionality and app behavior
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String email = emailController.text;
                String password = passwordController.text;
                var user =
                    await authService.signInWithEmailPassword(email, password);
                if (user != null) {
                  debugPrint("Logged in as: ${user.email}");
                  // ✅ Ensure the widget is still mounted before navigating
                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NavigationExample()),
                  );
                } else {
                  debugPrint("Login failed.");

                  // ✅ Ensure the widget is still mounted before showing a SnackBar
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Login failed. Please try again.")),
                  );
                }
              },
              child: Text("Login with Email"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                var user = await authService.signInWithGoogle();
                if (user != null) {
                  debugPrint("Logged in as: ${user.displayName}");

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NavigationExample()),
                  );
                } else {
                  debugPrint("Google Sign-In failed.");

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Google Sign-In failed.")));
                }
              },
              child: Text("Login with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
