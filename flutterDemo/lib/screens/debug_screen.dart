import 'package:flutter/material.dart';
import 'package:playpaws_test/services/data_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug/Testing Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final testDataService = TestDataService();
            
            try {
              // Call the methods to generate the test data
              await testDataService.createFakeUsers();
              await testDataService.createFakeDogs();
              await testDataService.createFakePlaydates();
              await testDataService.createFakeMatches();

              // Show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Test data created successfully!')),
              );
            } catch (e) {
              // Handle any errors and show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating test data: $e')),
              );
            }
          },
          child: Text('Generate Test Data'),
        ),
      ),
    );
  }
}
