import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ViewAllBoothsPage extends StatefulWidget {
  const ViewAllBoothsPage({super.key});

  @override
  State<ViewAllBoothsPage> createState() => _ViewAllBoothsPageState();
}

class _ViewAllBoothsPageState extends State<ViewAllBoothsPage> {
  Map<String, Map<String, Map<String, Map<String, int>>>> pollingData = {};
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBooths();
  }

  Future<void> fetchBooths() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1️⃣ Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("No token found. Please login again.");
      }
      final response = await http.get(
        Uri.parse('http://13.61.32.111:3000/api/admin/booths'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 🔹 Debug logs
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ensure the API returned a List
        if (data is! List) {
          throw Exception('Unexpected response format. Expected a List.');
        }

        // Transform API response into nested map structure
        final Map<String, Map<String, Map<String, Map<String, int>>>> transformed = {};

        for (var booth in data) {
          String state = booth['state']?.toString() ?? 'Unknown';
          String district = booth['district']?.toString() ?? 'Unknown';
          String assembly = booth['assembly_constituency']?.toString() ?? 'Unknown';
          String part = booth['part_name']?.toString() ?? 'Unknown';
          int booths = (booth['booths'] is int) ? booth['booths'] : 1;

          transformed[state] ??= {};
          transformed[state]![district] ??= {};
          transformed[state]![district]![assembly] ??= {};
          transformed[state]![district]![assembly]![part] = booths;
        }

        setState(() {
          pollingData = transformed;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load booths: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching booths: $e')),
      );

      // Also print for debug console
      print('Error fetching booths: $e');
    }
  }

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                    .map((district) => district.values
                    .map((assembly) =>
                    assembly.values.fold<int>(0, (a, b) => a + b))
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
                          builder: (_) => DistrictsPage(
                            stateName: stateName,
                            districts: stateEntry.value,
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

// ----------------- Districts Page -----------------
class DistrictsPage extends StatefulWidget {
  final String stateName;
  final Map<String, Map<String, Map<String, int>>> districts;
  const DistrictsPage({super.key, required this.stateName, required this.districts});

  @override
  State<DistrictsPage> createState() => _DistrictsPageState();
}

class _DistrictsPageState extends State<DistrictsPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredDistricts = widget.districts.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stateName} - Districts'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search District...',
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
              itemCount: filteredDistricts.length,
              itemBuilder: (context, index) {
                final districtEntry = filteredDistricts[index];
                final districtName = districtEntry.key;
                final totalBooths = districtEntry.value.values
                    .map((assembly) => assembly.values.fold<int>(0, (a, b) => a + b))
                    .fold<int>(0, (a, b) => a + b);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(districtName),
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
                          builder: (_) => AssemblyPage(
                            districtName: districtName,
                            assemblies: districtEntry.value,
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

// ----------------- Assembly Constituencies Page -----------------
class AssemblyPage extends StatefulWidget {
  final String districtName;
  final Map<String, Map<String, int>> assemblies;
  const AssemblyPage({super.key, required this.districtName, required this.assemblies});

  @override
  State<AssemblyPage> createState() => _AssemblyPageState();
}

class _AssemblyPageState extends State<AssemblyPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredAssemblies = widget.assemblies.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.districtName} - Assembly Constituencies'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Assembly...',
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
              itemCount: filteredAssemblies.length,
              itemBuilder: (context, index) {
                final assemblyEntry = filteredAssemblies[index];
                final assemblyName = assemblyEntry.key;
                final totalBooths = assemblyEntry.value.values.fold<int>(0, (a, b) => a + b);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(assemblyName),
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
                          builder: (_) => PartPage(
                            assemblyName: assemblyName,
                            parts: assemblyEntry.value,
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

// ----------------- Part Names Page -----------------
class PartPage extends StatefulWidget {
  final String assemblyName;
  final Map<String, int> parts;
  const PartPage({super.key, required this.assemblyName, required this.parts});

  @override
  State<PartPage> createState() => _PartPageState();
}

class _PartPageState extends State<PartPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredParts = widget.parts.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.assemblyName} - Part Names'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search Part...',
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
              itemCount: filteredParts.length,
              itemBuilder: (context, index) {
                final partName = filteredParts[index].key;
                final booths = filteredParts[index].value;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(partName),
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
                        SnackBar(content: Text('Clicked $partName in ${widget.assemblyName}')),
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
