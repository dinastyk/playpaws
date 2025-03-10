import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); //added key param
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
      backgroundColor: Color(0xFFD1E4FF),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO IMAGE
            Image.asset(
              'assets/logo.png', // Ensure correct path
              height: 150, // Adjust size as needed
              width: 150,
            ),
            SizedBox(height: 0), // Space between logo and text fields

            Text(
              "Welcome to PlayPaws!",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF1A69C6),
              ),
            ),
            SizedBox(height:40),

            TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: "Email",
                    enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A69C6), width: 1.0))
                  ),
              ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A69C6), width: 1.0))
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style:ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9874), // 🔹 Button background color
                foregroundColor: Colors.white, // 🔹 Text color
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Optional: Padding
              ),
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
              style:ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9874), // 🔹 Button background color
                foregroundColor: Colors.white, // 🔹 Text color
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Optional: Padding
              ),
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
