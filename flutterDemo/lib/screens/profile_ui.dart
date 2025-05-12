import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:playpaws_test/screens/login_screen.dart';
import 'settings_page.dart';
import 'login_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';

void main() {
  runApp(const PlayPawsProfile());
}

class PlayPawsProfile extends StatelessWidget {
  const PlayPawsProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String ownerName = "Loading...";
  String dogName = "Loading...";
  String breed = "Loading...";
  int age = 0;
  double weight = 0.0;
  String energyLevel = "Loading...";
  List<String> personalityTraits = [];
  String profilePictureURL = "";
  List<String> dogPictures = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _fetchProfileData();
  }

  @override
  void didPopNext() {
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No user logged in');
      return;
    }

    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      print('No user document found for uid: $uid');
      return;
    }

    final userSnapshot = userQuery.docs.first;
    final userData = userSnapshot.data();

    final dogField = userData['dog'];
    if (dogField is! DocumentReference) {
      print('ERROR: userData[dog] is not a DocumentReference: $dogField');
      return;
    }

    final dogSnapshot = await dogField.get();
    if (!dogSnapshot.exists) {
      print('Dog document does not exist at ${dogField.path}');
      return;
    }

    final dogData = dogSnapshot.data() as Map<String, dynamic>;

    print('✅ Loaded user: ${userData['name']}, dog: ${dogData['name']}');

    setState(() {
      ownerName = userData['name'] ?? 'No Name';
      profilePictureURL = userData['profilePictureURL'] ?? '';
      dogName = dogData['name'] ?? 'No Name';
      breed = dogData['breed'] ?? 'Unknown';
      age = (dogData['age'] as num?)?.toInt() ?? 0;
      weight = (dogData['weight'] as num?)?.toDouble() ?? 0.0;
      energyLevel = dogData['energyLevel'] ?? 'Unknown';
      personalityTraits = List<String>.from(dogData['personality'] ?? []);
      dogPictures = List<String>.from(dogData['dogPictures'] ?? []);
    });
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFD1E4FF);
    const buttonColor = Color(0xFFFF9874);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: buttonColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: buttonColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Owner: $ownerName",
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                          Text("Dog: $dogName",
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Photos"),
                dogPictures.isNotEmpty
                    ? CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          viewportFraction: 0.5,
                        ),
                        items: dogPictures.map((url) {
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(url),
                            child: Container(
                              width: 150,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : const Text("No dog photos available."),
                const SizedBox(height: 16),
                _buildInfoField("Breed", breed),
                _buildInfoField("Age", "$age years"),
                _buildInfoField("Weight", "${weight.toStringAsFixed(2)} kg"),
                _buildInfoField("Energy Level", energyLevel),
                _buildInfoField(
                    "Personality Traits", personalityTraits.join(", ")),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      ownerName: ownerName,
                      dogName: dogName,
                      breed: breed,
                      age: age,
                      weight: weight,
                      energyLevel: energyLevel,
                      personalityTraits: personalityTraits,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
              ),
              child: const Text("Edit Profile"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Photo", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String ownerName, dogName, breed, energyLevel;
  final int age;
  final double weight;
  final List<String> personalityTraits;

  const EditProfileScreen({
    super.key,
    required this.ownerName,
    required this.dogName,
    required this.breed,
    required this.age,
    required this.weight,
    required this.energyLevel,
    required this.personalityTraits,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController ownerController;
  late TextEditingController dogController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController weightController;

  final List<String> energyLevels = ['Low', 'Medium', 'High'];
  String? selectedEnergyLevel;

  final List<String> availablePersonalities = [
    'Friendly',
    'Playful',
    'Shy',
    'Aggressive',
    'Protective',
    'Curious',
    'Exciteable',
    'Calm',
    'Anxious',
    'Clever',
    'Goofy',
    'Laidback',
    'Social',
    'Active',
    'Sensitive',
    'Stubborn'
  ];
  late List<String> selectedPersonalities;

  final List<String> dogBreeds = [
    "Affenpinscher",
    "Afghan Hound",
    "Airedale Terrier",
    "Akita",
    "Alaskan Malamute",
    "American Bulldog",
    "American English Coonhound",
    "American Eskimo Dog",
    "American Foxhound",
    "American Hairless Terrier",
    "American Leopard Hound",
    "American Staffordshire Terrier",
    "American Water Spaniel",
    "Anatolian Shepherd Dog",
    "Appenzeller Sennenhund",
    "Australian Cattle Dog",
    "Australian Kelpie",
    "Australian Shepherd",
    "Australian Stumpy Tail Cattle Dog",
    "Australian Terrier",
    "Azawakh",
    "Barbet",
    "Basenji",
    "Basset Fauve de Bretagne",
    "Basset Hound",
    "Bavarian Mountain Scent Hound",
    "Beagle",
    "Bearded Collie",
    "Beauceron",
    "Bedlington Terrier",
    "Belgian Laekenois",
    "Belgian Malinois",
    "Belgian Sheepdog",
    "Belgian Tervuren",
    "Bergamasco Sheepdog",
    "Berger Picard",
    "Bernese Mountain Dog",
    "Bichon Frise",
    "Biewer Terrier",
    "Black and Tan Coonhound",
    "Black Russian Terrier",
    "Bloodhound",
    "Bluetick Coonhound",
    "Boerboel",
    "Bohemian Shepherd",
    "Bolognese",
    "Border Collie",
    "Border Terrier",
    "Borzoi",
    "Boston Terrier",
    "Bouvier des Flandres",
    "Boxer",
    "Boykin Spaniel",
    "Bracco Italiano",
    "Braque du Bourbonnais",
    "Braque Francais Pyrenean",
    "Briard",
    "Brittany",
    "Broholmer",
    "Brussels Griffon",
    "Bull Terrier",
    "Bulldog",
    "Bullmastiff",
    "Cairn Terrier",
    "Canaan Dog",
    "Cane Corso",
    "Cardigan Welsh Corgi",
    "Carolina Dog",
    "Catahoula Leopard Dog",
    "Caucasian Shepherd Dog",
    "Cavalier King Charles Spaniel",
    "Central Asian Shepherd Dog",
    "Cesky Terrier",
    "Chesapeake Bay Retriever",
    "Chihuahua",
    "Chinese Crested",
    "Chinese Shar-Pei",
    "Chinook",
    "Chow Chow",
    "Cirneco dell’Etna",
    "Clumber Spaniel",
    "Cocker Spaniel",
    "Collie",
    "Coton de Tulear",
    "Croatian Sheepdog",
    "Curly-Coated Retriever",
    "Czechoslovakian Vlcak",
    "Dachshund",
    "Dalmatian",
    "Dandie Dinmont Terrier",
    "Danish-Swedish Farmdog",
    "Deutscher Wachtelhund",
    "Doberman Pinscher",
    "Dogo Argentino",
    "Dogue de Bordeaux",
    "Drentsche Patrijshond",
    "Drever",
    "Dutch Shepherd",
    "English Cocker Spaniel",
    "English Foxhound",
    "English Setter",
    "English Springer Spaniel",
    "English Toy Spaniel",
    "Entlebucher Mountain Dog",
    "Estrela Mountain Dog",
    "Eurasier",
    "Field Spaniel",
    "Finnish Lapphund",
    "Finnish Spitz",
    "Flat-Coated Retriever",
    "French Bulldog",
    "French Spaniel",
    "German Longhaired Pointer",
    "German Pinscher",
    "German Shepherd Dog",
    "German Shorthaired Pointer",
    "German Spitz",
    "German Wirehaired Pointer",
    "Giant Schnauzer",
    "Glen of Imaal Terrier",
    "Golden Retriever",
    "Gordon Setter",
    "Grand Basset Griffon Vendéen",
    "Great Dane",
    "Great Pyrenees",
    "Greater Swiss Mountain Dog",
    "Greyhound",
    "Hamiltonstovare",
    "Hanoverian Scenthound",
    "Harrier",
    "Havanese",
    "Hokkaido",
    "Hovawart",
    "Ibizan Hound",
    "Icelandic Sheepdog",
    "Irish Red and White Setter",
    "Irish Setter",
    "Irish Terrier",
    "Irish Water Spaniel",
    "Irish Wolfhound",
    "Italian Greyhound",
    "Jagdterrier",
    "Japanese Chin",
    "Japanese Spitz",
    "Jindo",
    "Kai Ken",
    "Karelian Bear Dog",
    "Keeshond",
    "Kerry Blue Terrier",
    "Kishu Ken",
    "Komondor",
    "Kromfohrlander",
    "Kuvasz",
    "Labrador Retriever",
    "Lagotto Romagnolo",
    "Lakeland Terrier",
    "Lancashire Heeler",
    "Lapponian Herder",
    "Leonberger",
    "Lhasa Apso",
    "Löwchen",
    "Maltese",
    "Manchester Terrier (Standard)",
    "Manchester Terrier (Toy)",
    "Mastiff",
    "Miniature American Shepherd",
    "Miniature Bull Terrier",
    "Miniature Pinscher",
    "Miniature Schnauzer",
    "Mountain Cur",
    "Mudi",
    "Neapolitan Mastiff",
    "Nederlandse Kooikerhondje",
    "Newfoundland",
    "Norfolk Terrier",
    "Norrbottenspets",
    "Norwegian Buhund",
    "Norwegian Elkhound",
    "Norwegian Lundehund",
    "Norwich Terrier",
    "Nova Scotia Duck Tolling Retriever",
    "Old English Sheepdog",
    "Otterhound",
    "Papillon",
    "Parson Russell Terrier",
    "Pekingese",
    "Pembroke Welsh Corgi",
    "Perro de Presa Canario",
    "Peruvian Inca Orchid",
    "Petit Basset Griffon Vendéen",
    "Pharaoh Hound",
    "Plott Hound",
    "Pointer",
    "Polish Lowland Sheepdog",
    "Pomeranian",
    "Poodle (Miniature)",
    "Poodle (Standard)",
    "Poodle (Toy)",
    "Porcelaine",
    "Portuguese Podengo",
    "Portuguese Podengo Pequeno",
    "Portuguese Pointer",
    "Portuguese Sheepdog",
    "Portuguese Water Dog",
    "Pudelpointer",
    "Pug",
    "Puli",
    "Pumi",
    "Pyrenean Mastiff",
    "Pyrenean Shepherd",
    "Rafeiro do Alentejo",
    "Rat Terrier",
    "Redbone Coonhound",
    "Rhodesian Ridgeback",
    "Romanian Mioritic Shepherd Dog",
    "Rottweiler",
    "Russell Terrier",
    "Russian Toy",
    "Russian Tsvetnaya Bolonka",
    "Saint Bernard",
    "Saluki",
    "Samoyed",
    "Schapendoes",
    "Schipperke",
    "Scottish Deerhound",
    "Scottish Terrier",
    "Sealyham Terrier",
    "Segugio Italiano",
    "Shetland Sheepdog",
    "Shiba Inu",
    "Shih Tzu",
    "Shikoku",
    "Siberian Husky",
    "Silky Terrier",
    "Skye Terrier",
    "Sloughi",
    "Slovakian Wirehaired Pointer",
    "Slovensky Cuvac",
    "Slovensky Kopov",
    "Small Munsterlander Pointer",
    "Smooth Fox Terrier",
    "Soft Coated Wheaten Terrier",
    "Spanish Mastiff",
    "Spanish Water Dog",
    "Spinone Italiano",
    "Stabyhoun",
    "Staffordshire Bull Terrier",
    "Standard Schnauzer",
    "Sussex Spaniel",
    "Swedish Lapphund",
    "Swedish Vallhund",
    "Taiwan Dog",
    "Teddy Roosevelt Terrier",
    "Thai Ridgeback",
    "Tibetan Mastiff",
    "Tibetan Spaniel",
    "Tibetan Terrier",
    "Tornjak",
    "Tosa",
    "Toy Fox Terrier",
    "Transylvanian Hound",
    "Treeing Tennessee Brindle",
    "Treeing Walker Coonhound",
    "Vizsla",
    "Weimaraner",
    "Welsh Springer Spaniel",
    "Welsh Terrier",
    "West Highland White Terrier",
    "Wetterhoun",
    "Whippet",
    "Wire Fox Terrier",
    "Wirehaired Pointing Griffon",
    "Wirehaired Vizsla",
    "Working Kelpie",
    "Xoloitzcuintli",
    "Yakutian Laika",
    "Yorkshire Terrier"
  ];

  @override
  void initState() {
    super.initState();
    ownerController = TextEditingController(text: widget.ownerName);
    dogController = TextEditingController(text: widget.dogName);
    breedController = TextEditingController(text: widget.breed);
    ageController = TextEditingController(text: widget.age.toString());
    weightController = TextEditingController(text: widget.weight.toString());
    selectedEnergyLevel = widget.energyLevel;
    selectedPersonalities = List<String>.from(widget.personalityTraits);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;

    final userSnapshot = userQuery.docs.first;
    final DocumentReference dogRef = userSnapshot['dog'];

    await userSnapshot.reference.update({
      'name': ownerController.text.trim(),
    });

    await dogRef.update({
      'name': dogController.text.trim(),
      'breed': breedController.text.trim(),
      'age': int.tryParse(ageController.text.trim()) ?? widget.age,
      'weight': double.tryParse(weightController.text.trim()) ?? widget.weight,
      'energyLevel': selectedEnergyLevel,
      'personality': selectedPersonalities,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Owner Name', ownerController),
              _buildTextField('Dog Name', dogController),
              DropdownSearch<String>(
                items: dogBreeds,
                selectedItem: breedController.text.isNotEmpty
                    ? breedController.text
                    : null,
                onChanged: (value) {
                  setState(() {
                    breedController.text = value ?? '';
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select your dog\'s breed'
                    : null,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Dog's Breed",
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search breed...",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              _buildTextField('Age', ageController, isNumber: true),
              _buildTextField('Weight (kg)', weightController, isDecimal: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedEnergyLevel,
                decoration: const InputDecoration(
                  labelText: 'Dog\'s Energy Level',
                  border: OutlineInputBorder(),
                ),
                items: energyLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEnergyLevel = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select dog\'s energy level' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Dog\'s Personality Traits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: availablePersonalities.map((trait) {
                  final isSelected = selectedPersonalities.contains(trait);
                  return ChoiceChip(
                    label: Text(trait),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedPersonalities.add(trait);
                        } else {
                          selectedPersonalities.remove(trait);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool isDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required field';
          return null;
        },
      ),
    );
  }
}
