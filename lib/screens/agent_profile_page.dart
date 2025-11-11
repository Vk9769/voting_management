import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:voting_management/screens/agent_messages_page.dart';
import 'package:voting_management/screens/agent_report.dart';
import 'view_allocate_polling_booth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AgentProfilePage extends StatefulWidget {
  const AgentProfilePage({super.key});

  @override
  State<AgentProfilePage> createState() => _AgentProfilePageState();
}

class _AgentProfilePageState extends State<AgentProfilePage> {
  String firstName = '';
  String lastName = '';
  String fatherName = '';
  String voterId = '';
  String agentEmail = '';
  String agentPhone = '';
  String documentType = '';
  String documentNumber = '';

  String? _profileImageUrl; // online profile image
  File? _profileImage; // locally picked profile image


  final ImagePicker _picker = ImagePicker();
  final List<String> _documentTypes = [
    'Aadhaar',
    'Passport',
    'Voter ID',
    'Driving License'
  ];

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }
  Future<void> _loadAgentData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      Fluttertoast.showToast(msg: "Session expired, please login again");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://13.61.32.111:3000/api/agent/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        setState(() {
          firstName = data['first_name'] ?? '';
          lastName = data['last_name'] ?? '';
          fatherName = data['fathers_name'] ?? '';
          voterId = data['voter_id'] ?? '';
          agentEmail = data['email'] ?? '';
          agentPhone = data['phone'] ?? '';
          documentType = _documentTypes.contains(data['gov_id_type'])
              ? data['gov_id_type']
              : 'Aadhaar';
          documentNumber = data['gov_id_number'] ?? '';

          String? photoPath = data['profile_photo'];
          _profileImageUrl = photoPath != null
              ? "http://13.61.32.111:3000$photoPath"
              : null;
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load profile");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }



  //Future<void> _loadAgentData() async {
  //setState(() {
      // Dummy agent profile data for demo
  // firstName = 'Amit';
  //lastName = 'Sharma';
  //fatherName = 'Ramesh Sharma';
  //voterId = 'MH/23/459872';
  //agentEmail = 'amit.sharma@electionteam.in';
  //agentPhone = '+91 9876543210';
  // documentType = 'Aadhaar';
  //documentNumber = '2345-6789-1234';

      // Dummy profile image (you can use an asset or leave null)
//_profileImage = null;
// });
  // }


  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _profileImageUrl = null; // hide network when picking new image
      });
      Fluttertoast.showToast(msg: "Profile picture updated");
    }
  }


  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agent_name', '$firstName $lastName');
    await prefs.setString('father_name', fatherName);
    await prefs.setString('voter_id', voterId);
    await prefs.setString('agent_email', agentEmail);
    await prefs.setString('agent_phone', agentPhone);
    await prefs.setString('agent_doc_type', documentType);
    await prefs.setString('agent_doc_number', documentNumber);
    if (_profileImage != null) {
      await prefs.setString('agent_image_path', _profileImage!.path);
    } else {
      await prefs.remove('agent_image_path');
    }
    Fluttertoast.showToast(msg: "Profile updated successfully");
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    Fluttertoast.showToast(msg: "Logged out successfully");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadAgentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              // Replace this section in your build method:

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/agent_avatar.png') as ImageProvider),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // reduced from 15
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4), // reduced from 6
              Text("Voter ID: $voterId",
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 15), // reduced from 25

              // Editable fields
              _buildEditableField(
                  icon: Icons.person,
                  label: "First Name",
                  value: firstName,
                  onChanged: (v) => firstName = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.person,
                  label: "Last Name",
                  value: lastName,
                  onChanged: (v) => lastName = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.person_outline,
                  label: "Father's Name",
                  value: fatherName,
                  onChanged: (v) => fatherName = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.phone_android,
                  label: "Mobile Number",
                  value: agentPhone,
                  onChanged: (v) => agentPhone = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.email,
                  label: "Email",
                  value: agentEmail,
                  onChanged: (v) => agentEmail = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.badge,
                  label: "Voter ID",
                  value: voterId,
                  onChanged: (v) => voterId = v),
              const SizedBox(height: 10),

              // Document type selector
              Card(
                elevation: 3,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: documentType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _documentTypes
                              .map((type) =>
                              DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                documentType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.format_list_numbered,
                  label: "$documentType Number",
                  value: documentNumber,
                  onChanged: (v) => documentNumber = v),
              const SizedBox(height: 20),

              // Actions: Booths, Messages, Reports
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Column(
                  children: [
                    _buildActionTile(
                      Icons.location_on,
                      "Assigned Booths",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (
                                context) => const ViewAllocatePollingBoothPage(),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _buildActionTile(
                      Icons.message,
                      "Messages",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (
                                context) => const AgentMessagesPage(),
                          ),
                        );
                      },
                    ),
                    _divider(),
                    _buildActionTile(
                      Icons.report,
                      "Reports",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (
                                context) => const AgentReportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),


              // Save + Logout Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(140, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (context) =>
                            AlertDialog(
                              title: const Text("Confirm Logout"),
                              content:
                              const Text("Are you sure you want to logout?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Logout",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) _logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(140, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    final controller = TextEditingController(text: value);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.blue),
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap ??
              () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$title Coming Soon"),
                duration: const Duration(seconds: 1),
              ),
            );
          },
    );
  }

  Widget _divider() {
    return const Divider(
      thickness: 1,
      height: 20,
      color: Colors.grey,
      indent: 16,
      endIndent: 16,
    );
  }
}