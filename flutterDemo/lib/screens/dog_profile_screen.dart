
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Future<String> getOwnerName(Map<String, dynamic> dogData) async {
//   try {
//     DocumentSnapshot docSnapshot = await dogDo.get();
//     if (docSnapshot.exists) {
//       return docSnapshot.get('breed');
//     }
//   } catch (e) {
//     print('Error fetching document: $e');
//   }
//   return "";
// } //need to add owner field to dog field
class DogProfileScreen extends StatelessWidget {
  final Map<String, dynamic> dogData;
  const DogProfileScreen({Key? key, required this.dogData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFD1E4FF);
    const buttonColor = Color(0xFFFF9874);
    final dogName = dogData['name'] ?? 'Unknown';
    final breed = dogData['breed'] ?? 'Unknown';
    final age = dogData['age'] ?? 0;
    final weight = dogData['weight']?.toDouble() ?? 0.0;
    final energyLevel = dogData['energyLevel'] ?? 'Unknown';
    final personalityTraits = List<String>.from(dogData['personality'] ?? []);
    final profilePictureURL = dogData['dogPictureURL'] ?? '';
    final dogPictures = List<String>.from(dogData['dogPictures'] ?? []);

    return Scaffold(
      backgroundColor: backgroundColor,
appBar: AppBar(
  backgroundColor: backgroundColor,
  elevation: 0,
  automaticallyImplyLeading: false,
  leading: IconButton(
    icon: const Icon(Icons.close, color: buttonColor),
    onPressed: () {
      Navigator.pop(context); // Or push to SwipePage() if needed
    },
  ),
),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dog Profile Picture + Name
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        image: profilePictureURL.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profilePictureURL),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profilePictureURL.isEmpty
                          ? const Center(child: Text("No Photo"))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        dogName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text("All Photos"),
                dogPictures.isNotEmpty
                    ? CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.5,
                        ),
                        items: dogPictures.map((url) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImageView(
                                        imageUrl: url),
                                  ),
                                ),
                                child: Container(
                                  width: 150,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      )
                    : Row(
                        children: List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.all(4.0),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                const Center(child: Icon(Icons.photo_outlined)),
                          ),
                        ),
                      ),

                const SizedBox(height: 16),
                _buildInfoField(context, "Breed", breed),
                _buildInfoField(context, "Age", "$age years"),
                _buildInfoField(context, "Weight", "${weight.toStringAsFixed(2)} kg"),
                _buildInfoField(context, "Energy Level", energyLevel),
                _buildInfoField(context, "Personality Traits",
                    personalityTraits.join(", ")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Photo"),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}