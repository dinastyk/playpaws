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
    fetchDogs(); // fetch the dog data when the page is loaded
  }

  // fetch dogs from the db
  Future<void> fetchDogs() async {
    setState(() {
      isLoading = true;
    });

    // call getDogs to fetch the list of dogs from Firestore
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
                ? Center(child: CircularProgressIndicator()) // show loading indicator if no dogs are available
                : CardSwipe(dogs: dogs), // pass the dogs data to CardSwipe
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