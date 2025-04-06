import 'package:flutter/material.dart';
import 'CardSwipe.dart'; // cardswipe has getDogs() and swiping UI+logic
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QueryDocumentSnapshot> dogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDogs(); // Fetch the dog data when the page is loaded
  }

  // Fetch dogs from the database or API
  Future<void> fetchDogs() async {
    setState(() {
      isLoading = true;
    });

    // Call getDogs to fetch the list of dogs from Firestore
    List<QueryDocumentSnapshot> fetchedDogs = await getDogs();
    
    setState(() {
      dogs = fetchedDogs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // Show loading indicator if no dogs are available
                : CardSwipe(dogs: dogs), // Pass the dogs data to your CardSwipe widget
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'SwipeCard.dart';
// import 'CardSwipe.dart';

// class HomePage extends StatelessWidget
// {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context)
//   {
//     return Scaffold
//     (
//       body: Column
//       (
//         children: 
//         [
//           Expanded
//           (
//             child: SwipeCardsDemo(),
//           )
//         ]
//       )
//     );
//   }
// }