class DebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug/Testing Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final testDataService = TestDataService();
            testDataService.createUsers();
            testDataService.createDogs();
            testDataService.createPlaydates();
            testDataService.createMatches();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test data created successfully!')));
          },
          child: Text('Generate Test Data'),
        ),
      ),
    );
  }
}
