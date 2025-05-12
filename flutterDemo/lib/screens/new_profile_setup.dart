import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:playpaws_test/services/send_data_service.dart';
import 'choose_preferences.dart';
class NewProfileSetup extends StatefulWidget {
  const NewProfileSetup({Key? key}) : super(key: key);

  @override
  _NewProfileSetupState createState() => _NewProfileSetupState();
}

class _NewProfileSetupState extends State<NewProfileSetup> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dogNameController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
 final dogBreeds=["Affenpinscher","Afghan Hound","Airedale Terrier","Akita","Alaskan Malamute","American Bulldog","American English Coonhound","American Eskimo Dog","American Foxhound","American Hairless Terrier","American Leopard Hound","American Staffordshire Terrier","American Water Spaniel","Anatolian Shepherd Dog","Appenzeller Sennenhund","Australian Cattle Dog","Australian Kelpie","Australian Shepherd","Australian Stumpy Tail Cattle Dog","Australian Terrier","Azawakh","Barbet","Basenji","Basset Fauve de Bretagne","Basset Hound","Bavarian Mountain Scent Hound","Beagle","Bearded Collie","Beauceron","Bedlington Terrier","Belgian Laekenois","Belgian Malinois","Belgian Sheepdog","Belgian Tervuren","Bergamasco Sheepdog","Berger Picard","Bernese Mountain Dog","Bichon Frise","Biewer Terrier","Black and Tan Coonhound","Black Russian Terrier","Bloodhound","Bluetick Coonhound","Boerboel","Bohemian Shepherd","Bolognese","Border Collie","Border Terrier","Borzoi","Boston Terrier","Bouvier des Flandres","Boxer","Boykin Spaniel","Bracco Italiano","Braque du Bourbonnais","Braque Francais Pyrenean","Briard","Brittany","Broholmer","Brussels Griffon","Bull Terrier","Bulldog","Bullmastiff","Cairn Terrier","Canaan Dog","Cane Corso","Cardigan Welsh Corgi","Carolina Dog","Catahoula Leopard Dog","Caucasian Shepherd Dog","Cavalier King Charles Spaniel","Central Asian Shepherd Dog","Cesky Terrier","Chesapeake Bay Retriever","Chihuahua","Chinese Crested","Chinese Shar-Pei","Chinook","Chow Chow","Cirneco dell’Etna","Clumber Spaniel","Cocker Spaniel","Collie","Coton de Tulear","Croatian Sheepdog","Curly-Coated Retriever","Czechoslovakian Vlcak","Dachshund","Dalmatian","Dandie Dinmont Terrier","Danish-Swedish Farmdog","Deutscher Wachtelhund","Doberman Pinscher","Dogo Argentino","Dogue de Bordeaux","Drentsche Patrijshond","Drever","Dutch Shepherd","English Cocker Spaniel","English Foxhound","English Setter","English Springer Spaniel","English Toy Spaniel","Entlebucher Mountain Dog","Estrela Mountain Dog","Eurasier","Field Spaniel","Finnish Lapphund","Finnish Spitz","Flat-Coated Retriever","French Bulldog","French Spaniel","German Longhaired Pointer","German Pinscher","German Shepherd Dog","German Shorthaired Pointer","German Spitz","German Wirehaired Pointer","Giant Schnauzer","Glen of Imaal Terrier","Golden Retriever","Gordon Setter","Grand Basset Griffon Vendéen","Great Dane","Great Pyrenees","Greater Swiss Mountain Dog","Greyhound","Hamiltonstovare","Hanoverian Scenthound","Harrier","Havanese","Hokkaido","Hovawart","Ibizan Hound","Icelandic Sheepdog","Irish Red and White Setter","Irish Setter","Irish Terrier","Irish Water Spaniel","Irish Wolfhound","Italian Greyhound","Jagdterrier","Japanese Chin","Japanese Spitz","Jindo","Kai Ken","Karelian Bear Dog","Keeshond","Kerry Blue Terrier","Kishu Ken","Komondor","Kromfohrlander","Kuvasz","Labrador Retriever","Lagotto Romagnolo","Lakeland Terrier","Lancashire Heeler","Lapponian Herder","Leonberger","Lhasa Apso","Löwchen","Maltese","Manchester Terrier (Standard)","Manchester Terrier (Toy)","Mastiff","Miniature American Shepherd","Miniature Bull Terrier","Miniature Pinscher","Miniature Schnauzer","Mountain Cur","Mudi","Neapolitan Mastiff","Nederlandse Kooikerhondje","Newfoundland","Norfolk Terrier","Norrbottenspets","Norwegian Buhund","Norwegian Elkhound","Norwegian Lundehund","Norwich Terrier","Nova Scotia Duck Tolling Retriever","Old English Sheepdog","Otterhound","Papillon","Parson Russell Terrier","Pekingese","Pembroke Welsh Corgi","Perro de Presa Canario","Peruvian Inca Orchid","Petit Basset Griffon Vendéen","Pharaoh Hound","Plott Hound","Pointer","Polish Lowland Sheepdog","Pomeranian","Poodle (Miniature)","Poodle (Standard)","Poodle (Toy)","Porcelaine","Portuguese Podengo","Portuguese Podengo Pequeno","Portuguese Pointer","Portuguese Sheepdog","Portuguese Water Dog","Pudelpointer","Pug","Puli","Pumi","Pyrenean Mastiff","Pyrenean Shepherd","Rafeiro do Alentejo","Rat Terrier","Redbone Coonhound","Rhodesian Ridgeback","Romanian Mioritic Shepherd Dog","Rottweiler","Russell Terrier","Russian Toy","Russian Tsvetnaya Bolonka","Saint Bernard","Saluki","Samoyed","Schapendoes","Schipperke","Scottish Deerhound","Scottish Terrier","Sealyham Terrier","Segugio Italiano","Shetland Sheepdog","Shiba Inu","Shih Tzu","Shikoku","Siberian Husky","Silky Terrier","Skye Terrier","Sloughi","Slovakian Wirehaired Pointer","Slovensky Cuvac","Slovensky Kopov","Small Munsterlander Pointer","Smooth Fox Terrier","Soft Coated Wheaten Terrier","Spanish Mastiff","Spanish Water Dog","Spinone Italiano","Stabyhoun","Staffordshire Bull Terrier","Standard Schnauzer","Sussex Spaniel","Swedish Lapphund","Swedish Vallhund","Taiwan Dog","Teddy Roosevelt Terrier","Thai Ridgeback","Tibetan Mastiff","Tibetan Spaniel","Tibetan Terrier","Tornjak","Tosa","Toy Fox Terrier","Transylvanian Hound","Treeing Tennessee Brindle","Treeing Walker Coonhound","Vizsla","Weimaraner","Welsh Springer Spaniel","Welsh Terrier","West Highland White Terrier","Wetterhoun","Whippet","Wire Fox Terrier","Wirehaired Pointing Griffon","Wirehaired Vizsla","Working Kelpie","Xoloitzcuintli","Yakutian Laika","Yorkshire Terrier"];
  // Default dog age (slider)
  double dogAge = 1;

  // Energy level
  String? selectedEnergyLevel;
  final List<String> energyLevels = ['Low', 'Medium', 'High'];

  // Dog personality selection
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
  ]; //Make sure this ist is the same as those listed in new_profile_setup.dart
  List<String> selectedPersonalities = []; // Stores what user selects

  final _formKey = GlobalKey<FormState>();

  Future<void> createAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No authenticated user found.')));
      return;
    }

    try {
      // 1. Get number of existing users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final existingUserCount = usersSnapshot.docs.length;

      int newUserNumber = existingUserCount + 1;
      if (newUserNumber <= 50) {
        newUserNumber = 51; // Force starting at userId51 if users < 50
      }

      final newUserId = 'userId$newUserNumber';
      final newDogId = 'dogId$newUserNumber';

      // 2. Create Dog document manually with ID
      final dogDocRef =
          FirebaseFirestore.instance.collection('dogs').doc(newDogId);
      await dogDocRef.set({
        'name': dogNameController.text.trim(),
        'breed': breedController.text.trim(),
        'age': dogAge,
        'weight': double.parse(weightController.text.trim()),
        'energyLevel': selectedEnergyLevel,
        'personality': selectedPersonalities, // <-- SAVE selected traits
        'dogPictures': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Create User document manually with ID
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'name': nameController.text.trim(),
        'email': user.email,
        'uid': user.uid, // Firebase Authentication UID
        'dog': dogDocRef,
        'profilePictureURL': '',  // <-- ADD THIS line to avoid null crash
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'preferences': {}, 
        'preferredPersonalities': [],
      });

await sendDogEmbeddingRequest();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account successfully created!')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChoosePreferences(userDocId: newUserId),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Up Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Your Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Name
                TextFormField(
                  controller: dogNameController,
                  decoration: InputDecoration(labelText: "Dog's Name"),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your dog\'s name'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Breed
                // TextFormField(
                //   controller: breedController,
                //   decoration: InputDecoration(labelText: "Dog's Breed"),
                //   validator: (value) => value == null || value.isEmpty
                //       ? 'Please enter your dog\'s breed'
                //       : null,
                // ),
                // SizedBox(height: 16),
                DropdownSearch<String>(
  items: dogBreeds, // This should be your final list of breeds
  selectedItem: breedController.text.isNotEmpty ? breedController.text : null,
  onChanged: (value) {
    breedController.text = value ?? '';
  },
  validator: (value) =>
      value == null || value.isEmpty ? 'Please select your dog\'s breed' : null,
  dropdownDecoratorProps: DropDownDecoratorProps(
    dropdownSearchDecoration: InputDecoration(
      labelText: "Dog's Breed",
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
  ),
  popupProps: PopupProps.menu(
    showSearchBox: true,
    searchFieldProps: TextFieldProps(
      decoration: InputDecoration(
        hintText: "Search breed...",
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    ),
  ),
),


                // Dog Weight
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Dog's Weight (lbs)"),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your dog\'s weight'
                      : null,
                ),
                SizedBox(height: 16),

                // Dog Age
                Text('Dog\'s Age: ${dogAge.round()} years'),
                Slider(
                  value: dogAge,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: dogAge.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      dogAge = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Dog Energy Level
                DropdownButtonFormField<String>(
                  value: selectedEnergyLevel,
                  decoration: InputDecoration(labelText: 'Dog\'s Energy Level'),
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
                  validator: (value) => value == null
                      ? 'Please select dog\'s energy level'
                      : null,
                ),
                SizedBox(height: 24),

                // Personality Traits
                Text(
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
                SizedBox(height: 24),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        createAccount();
                      }
                    },
                    child: Text('Create Account'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
