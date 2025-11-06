import 'package:flutter/material.dart';
import 'super_admin_message_detail.dart';

class SuperAdminMessageList extends StatefulWidget {
  const SuperAdminMessageList({Key? key}) : super(key: key);

  @override
  State<SuperAdminMessageList> createState() => _SuperAdminMessageListState();
}

class _SuperAdminMessageListState extends State<SuperAdminMessageList> {
  // Dropdown Data (Later API controlled)
  List<String> states = ["Maharashtra", "Gujarat"];

  Map<String, List<String>> stateDistrictMap = {
    "Maharashtra": ["Nashik", "Pune"],
    "Gujarat": ["Ahmedabad", "Surat"]
  };

  Map<String, List<String>> districtAssemblyMap = {
    "Nashik": ["AC-11"],
    "Pune": ["AC-03"],
    "Ahmedabad": ["AC-09"],
    "Surat": ["AC-05"]
  };

  Map<String, List<String>> assemblySuperAgentMap = {
    "AC-11": ["Rajesh Sharma"],
    "AC-03": ["Mohan Patil"],
    "AC-09": ["Ramesh Chauhan"],
    "AC-05": ["Paresh Patel"]
  };

  String? selectedState;
  String? selectedDistrict;
  String? selectedAssembly;
  String? selectedSuperAgent;

  // Dummy Messages Data
  List<Map<String, String>> messages = [
    {
      "name": "Rajesh Sharma",
      "constituency": "AC-11",
      "state": "Maharashtra",
      "district": "Nashik",
      "date": "2025-11-05",
      "message": "Need campaign banners urgently."
    },
    {
      "name": "Mohan Patil",
      "constituency": "AC-03",
      "state": "Maharashtra",
      "district": "Pune",
      "date": "2025-11-04",
      "message": "Meeting scheduled with local committee."
    }
  ];

  List<Map<String, String>> filteredMessages = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMessages = List.from(messages);
  }

  void applyFilters() {
    setState(() {
      filteredMessages = messages.where((msg) {
        bool stateMatch = selectedState == null || msg["state"] == selectedState;
        bool districtMatch = selectedDistrict == null || msg["district"] == selectedDistrict;
        bool assemblyMatch = selectedAssembly == null || msg["constituency"] == selectedAssembly;
        bool agentMatch = selectedSuperAgent == null || msg["name"] == selectedSuperAgent;
        return stateMatch && districtMatch && assemblyMatch && agentMatch;
      }).toList();
    });
  }

  void searchMessages(String query) {
    setState(() {
      filteredMessages = messages.where((msg) =>
      msg["name"]!.toLowerCase().contains(query.toLowerCase()) ||
          msg["constituency"]!.toLowerCase().contains(query.toLowerCase()) ||
          msg["message"]!.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Agent Messages"),
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: searchMessages,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search messages...",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // STATE DROPDOWN
                  DropdownButtonFormField(
                    value: selectedState,
                    items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    decoration: const InputDecoration(labelText: "State", border: OutlineInputBorder()),
                    onChanged: (value) {
                      setState(() {
                        selectedState = value.toString();
                        selectedDistrict = null;
                        selectedAssembly = null;
                        selectedSuperAgent = null;
                      });
                      applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),

                  // DISTRICT DROPDOWN
                  if (selectedState != null)
                    DropdownButtonFormField(
                      value: selectedDistrict,
                      items: stateDistrictMap[selectedState]!
                          .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      decoration: const InputDecoration(labelText: "District", border: OutlineInputBorder()),
                      onChanged: (value) {
                        setState(() {
                          selectedDistrict = value.toString();
                          selectedAssembly = null;
                          selectedSuperAgent = null;
                        });
                        applyFilters();
                      },
                    ),
                  const SizedBox(height: 12),

                  // ASSEMBLY DROPDOWN
                  if (selectedDistrict != null)
                    DropdownButtonFormField(
                      value: selectedAssembly,
                      items: districtAssemblyMap[selectedDistrict]!
                          .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      decoration: const InputDecoration(labelText: "Assembly", border: OutlineInputBorder()),
                      onChanged: (value) {
                        setState(() {
                          selectedAssembly = value.toString();
                          selectedSuperAgent = null;
                        });
                        applyFilters();
                      },
                    ),
                  const SizedBox(height: 12),

                  // SUPER AGENT DROPDOWN
                  if (selectedAssembly != null)
                    DropdownButtonFormField(
                      value: selectedSuperAgent,
                      items: assemblySuperAgentMap[selectedAssembly]!
                          .map((sa) => DropdownMenuItem(value: sa, child: Text(sa))).toList(),
                      decoration: const InputDecoration(labelText: "Super Agent", border: OutlineInputBorder()),
                      onChanged: (value) {
                        setState(() => selectedSuperAgent = value.toString());
                        applyFilters();
                      },
                    ),

                  const SizedBox(height: 20),
                  const Text("Messages", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      var msg = filteredMessages[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(msg["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${msg["constituency"]}\n${msg["message"]}",
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chat, color: Colors.blue),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SuperAdminMessageDetail(
                                  name: msg["name"]!,
                                  constituency: msg["constituency"]!,
                                  messageText: msg["message"]!,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
