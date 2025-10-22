import 'package:flutter/material.dart';

class ViewAllBoothsPage extends StatefulWidget {
  const ViewAllBoothsPage({super.key});

  @override
  State<ViewAllBoothsPage> createState() => _ViewAllBoothsPageState();
}

class _ViewAllBoothsPageState extends State<ViewAllBoothsPage> {
  final Map<String, Map<String, Map<String, Map<String, int>>>> pollingData = {
    'Maharashtra': {
      'Mumbai': {
        'CST': {'Ward 1': 5, 'Ward 2': 5},
        'Mulund': {'Sector 1': 7, 'Sector 2': 8},
        'Thane': {'Zone A': 8, 'Zone B': 7},
      },
      'Pune': {
        'Shivajinagar': {'Block 1': 5, 'Block 2': 5},
        'Kothrud': {'Block 1': 5, 'Block 2': 5},
      },
    },
    'Gujarat': {
      'Ahmedabad': {
        'Navrangpura': {'Area 1': 5, 'Area 2': 5},
        'Paldi': {'Area 1': 6, 'Area 2': 6},
      },
    },
  };

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStates = pollingData.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polling Booths - States'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search State...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredStates.length,
              itemBuilder: (context, index) {
                final stateEntry = filteredStates[index];
                final stateName = stateEntry.key;
                final totalBooths = stateEntry.value.values
                    .map((city) => city.values
                    .map((subCity) => subCity.values
                    .fold<int>(0, (a, b) => a + b))
                    .fold<int>(0, (a, b) => a + b))
                    .fold<int>(0, (a, b) => a + b);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(stateName),
                    trailing: Text(
                      '$totalBooths booths',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CitiesPage(
                            stateName: stateName,
                            cities: stateEntry.value,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Cities Page -----------------
class CitiesPage extends StatefulWidget {
  final String stateName;
  final Map<String, Map<String, Map<String, int>>> cities;
  const CitiesPage({super.key, required this.stateName, required this.cities});

  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCities = widget.cities.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stateName} - Cities'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search City...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredCities.length,
              itemBuilder: (context, index) {
                final cityEntry = filteredCities[index];
                final cityName = cityEntry.key;
                final totalBooths = cityEntry.value.values
                    .map((subCity) => subCity.values.fold<int>(0, (a, b) => a + b))
                    .fold<int>(0, (a, b) => a + b);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(cityName),
                    trailing: Text(
                      '$totalBooths booths',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubCitiesPage(
                            cityName: cityName,
                            subCities: cityEntry.value,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Sub-cities Page -----------------
class SubCitiesPage extends StatefulWidget {
  final String cityName;
  final Map<String, Map<String, int>> subCities;
  const SubCitiesPage({super.key, required this.cityName, required this.subCities});

  @override
  State<SubCitiesPage> createState() => _SubCitiesPageState();
}

class _SubCitiesPageState extends State<SubCitiesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSubCities = widget.subCities.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} - Localities'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Locality...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredSubCities.length,
              itemBuilder: (context, index) {
                final subCityEntry = filteredSubCities[index];
                final subCityName = subCityEntry.key;
                final totalBooths = subCityEntry.value.values.fold<int>(0, (a, b) => a + b);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(subCityName),
                    trailing: Text(
                      '$totalBooths booths',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubSubCitiesPage(
                            subCityName: subCityName,
                            subSubCities: subCityEntry.value,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Sub-Sub-cities Page -----------------
class SubSubCitiesPage extends StatefulWidget {
  final String subCityName;
  final Map<String, int> subSubCities;
  const SubSubCitiesPage({super.key, required this.subCityName, required this.subSubCities});

  @override
  State<SubSubCitiesPage> createState() => _SubSubCitiesPageState();
}

class _SubSubCitiesPageState extends State<SubSubCitiesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSubSubCities = widget.subSubCities.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subCityName} - Sub Localities'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Sub-locality...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredSubSubCities.length,
              itemBuilder: (context, index) {
                final subSubCityName = filteredSubSubCities[index].key;
                final booths = filteredSubSubCities[index].value;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(subSubCityName),
                    trailing: Text(
                      '$booths booths',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Clicked $subSubCityName in ${widget.subCityName}')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
