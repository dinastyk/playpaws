import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'new_profile_setup.dart'; // Import correctly

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> registerAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return; // Safety check

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NewProfileSetup()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Safety check

      String errorMessage = "Error creating account";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password should be at least 6 characters.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return; // Safety check

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown error: $e')),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {  // <--- FIXED: build method added
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter your email' : null,
                ),
                SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: (value) =>
                      value == null || value.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                ),
                SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Create Account Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: registerAndProceed,
                        child: Text('Next'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
