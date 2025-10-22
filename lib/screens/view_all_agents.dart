import 'package:flutter/material.dart';

class ViewAllAgentsPage extends StatefulWidget {
  const ViewAllAgentsPage({super.key});

  @override
  State<ViewAllAgentsPage> createState() => _ViewAllAgentsPageState();
}

class _ViewAllAgentsPageState extends State<ViewAllAgentsPage> {
  // Nested hierarchy: State → District → City → Area → Booth → List<Agents>
  final Map<String, Map<String, Map<String, Map<String, Map<String, List<String>>>>>> agentData = {
    'Maharashtra': {
      'Mumbai': {
        'CST': {
          'Fort Area': {
            'Booth 1': ['Agent A', 'Agent B'],
            'Booth 2': ['Agent C'],
          },
          'Marine Lines': {
            'Booth 3': ['Agent D'],
          },
        },
        'Thane': {
          'Kopri': {
            'Booth 4': ['Agent E', 'Agent F'],
          },
          'Wagle Estate': {
            'Booth 5': ['Agent G', 'Agent H', 'Agent I'],
          },
        },
      },
      'Pune': {
        'Shivajinagar': {
          'Model Colony': {
            'Booth 6': ['Agent J', 'Agent K'],
          },
          'JM Road': {
            'Booth 7': ['Agent L'],
          },
        },
      },
    },
    'Gujarat': {
      'Ahmedabad': {
        'Navrangpura': {
          'Sector 1': {
            'Booth 8': ['Agent M', 'Agent N'],
          },
          'Paldi': {
            'Booth 9': ['Agent O'],
          },
        },
      },
    },
  };

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStates = agentData.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View All Agents - States'),
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
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStates.length,
              itemBuilder: (context, index) {
                final state = filteredStates[index];
                final totalAgents = state.value.values
                    .map((districts) => districts.values
                    .map((cities) => cities.values
                    .map((areas) => areas.values
                    .map((booths) => booths.length)
                    .fold<int>(0, (sum, b) => sum + b))
                    .fold<int>(0, (sum, a) => sum + a))
                    .fold<int>(0, (sum, c) => sum + c))
                    .fold<int>(0, (sum, d) => sum + d);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(state.key),
                    trailing: Text('$totalAgents agents',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DistrictsPage(
                          stateName: state.key,
                          districts: state.value,
                        ),
                      ),
                    ),
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

// -------------------- DISTRICTS PAGE --------------------
class DistrictsPage extends StatefulWidget {
  final String stateName;
  final Map<String, Map<String, Map<String, Map<String, List<String>>>>> districts;
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
          _searchBar('Search District...'),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDistricts.length,
              itemBuilder: (context, index) {
                final district = filteredDistricts[index];
                final totalAgents = district.value.values
                    .map((cities) => cities.values
                    .map((areas) => areas.values
                    .map((booths) => booths.length)
                    .fold<int>(0, (sum, b) => sum + b))
                    .fold<int>(0, (sum, a) => sum + a))
                    .fold<int>(0, (sum, c) => sum + c);

                return _infoCard(
                  district.key,
                  '$totalAgents agents',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitiesPage(
                        districtName: district.key,
                        cities: district.value.map(
                              (cityName, areasMap) => MapEntry(
                              cityName,
                              areasMap.map((areaName, boothsMap) => MapEntry(areaName, boothsMap.values.expand((b) => b).toList()))
                          ),
                        ),
                      ),
                    ),
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val),
    ),
  );

  Widget _infoCard(String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListTile(
      title: Text(title),
      trailing: Text(subtitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.green)),
      onTap: onTap,
    ),
  );
}

// -------------------- CITIES PAGE --------------------
class CitiesPage extends StatefulWidget {
  final String districtName;
  final Map<String, Map<String, List<String>>> cities;
  const CitiesPage({super.key, required this.districtName, required this.cities});

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
        title: Text('${widget.districtName} - Cities'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _searchBar('Search City...'),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCities.length,
              itemBuilder: (context, index) {
                final city = filteredCities[index];
                final totalAgents = city.value.values
                    .map((booths) => booths.length)
                    .fold<int>(0, (sum, b) => sum + b);

                return _infoCard(
                  city.key,
                  '$totalAgents agents',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AreasPage(
                        cityName: city.key,
                        areas: city.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val),
    ),
  );

  Widget _infoCard(String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListTile(
      title: Text(title),
      trailing: Text(subtitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.green)),
      onTap: onTap,
    ),
  );
}

// -------------------- AREAS PAGE --------------------
class AreasPage extends StatefulWidget {
  final String cityName;
  final Map<String, List<String>> areas;
  const AreasPage({super.key, required this.cityName, required this.areas});

  @override
  State<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends State<AreasPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredAreas = widget.areas.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} - Areas'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _searchBar('Search Area...'),
          Expanded(
            child: ListView.builder(
              itemCount: filteredAreas.length,
              itemBuilder: (context, index) {
                final area = filteredAreas[index];
                final totalAgents = area.value.length;

                return _infoCard(
                  area.key,
                  '$totalAgents agents',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoothsPage(
                        areaName: area.key,
                        booths: {area.key: area.value},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val),
    ),
  );

  Widget _infoCard(String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListTile(
      title: Text(title),
      trailing: Text(subtitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.green)),
      onTap: onTap,
    ),
  );
}

// -------------------- BOOTHS PAGE --------------------
class BoothsPage extends StatefulWidget {
  final String areaName;
  final Map<String, List<String>> booths;
  const BoothsPage({super.key, required this.areaName, required this.booths});

  @override
  State<BoothsPage> createState() => _BoothsPageState();
}

class _BoothsPageState extends State<BoothsPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredBooths = widget.booths.entries
        .where((e) => e.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.areaName} - Booths'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _searchBar('Search Booth...'),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBooths.length,
              itemBuilder: (context, index) {
                final booth = filteredBooths[index];
                final agentCount = booth.value.length;

                return _infoCard(
                  booth.key,
                  '$agentCount agents',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgentListPage(
                        boothName: booth.key,
                        agents: booth.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val),
    ),
  );

  Widget _infoCard(String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListTile(
      title: Text(title),
      trailing: Text(subtitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.green)),
      onTap: onTap,
    ),
  );
}

// -------------------- AGENT LIST PAGE --------------------
class AgentListPage extends StatefulWidget {
  final String boothName;
  final List<String> agents;
  const AgentListPage({super.key, required this.boothName, required this.agents});

  @override
  State<AgentListPage> createState() => _AgentListPageState();
}

class _AgentListPageState extends State<AgentListPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredAgents = widget.agents
        .where((a) => a.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.boothName} - Agents'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _searchBar('Search Agent...'),
          Expanded(
            child: ListView.builder(
              itemCount: filteredAgents.length,
              itemBuilder: (context, index) {
                final agent = filteredAgents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(agent),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected $agent')),
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

  Widget _searchBar(String hint) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      onChanged: (val) => setState(() => searchQuery = val),
    ),
  );
}
