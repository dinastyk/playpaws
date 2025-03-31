import 'package:flutter/material.dart';
import 'package:playpaws_test/services/data_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;

  Future<void> _generateTestData() async {
    setState(() {
      _isLoading = true;
    });

    final testDataService = TestDataService();
    try {
      await testDataService.createFakeData(); // Ensure this method is generating all necessary data (users, dogs, etc.)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test data created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug/Testing Screen')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator while generating data
            : ElevatedButton(
                onPressed: _generateTestData,
                child: Text('Generate Test Data'),
              ),
      ),
    );
  }
}
