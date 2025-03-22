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
            await testDataService.createUsers();
            await testDataService.createDogs();
            await testDataService.createPlaydates();
            await testDataService.createMatches();
            await testDataService.createMessages(); // Call createMessages here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Test data created successfully!')),
            );
          },
          child: Text('Generate Test Data'),
        ),
      ),
    );
  }
}
