import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  String documentType = 'Aadhaar';
  String documentNumber = '';
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();
  final List<String> _documentTypes = ['Aadhaar', 'Passport', 'Voter ID', 'Driving License'];

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fullName = prefs.getString('agent_name') ?? '';
      List<String> names = fullName.split(' ');
      firstName = names.isNotEmpty ? names[0] : '';
      lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      fatherName = prefs.getString('father_name') ?? '';
      voterId = prefs.getString('user_id') ?? '';
      agentEmail = prefs.getString('agent_email') ?? '';
      agentPhone = prefs.getString('agent_phone') ?? '';
      documentType = prefs.getString('agent_doc_type') ?? 'Aadhaar';
      documentNumber = prefs.getString('agent_doc_number') ?? '';
      final imagePath = prefs.getString('agent_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
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
                        : const AssetImage('assets/agent_avatar.png') as ImageProvider,
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
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
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
              Text("Voter ID: $voterId", style: const TextStyle(color: Colors.black54)),
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
                              .map((type) => DropdownMenuItem(
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
                    _buildActionTile(Icons.location_on, "Assigned Booths"),
                    _divider(),
                    _buildActionTile(Icons.message, "Messages"),
                    _divider(),
                    _buildActionTile(Icons.report, "Reports"),
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
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Logout"),
                          content:
                          const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
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

  Widget _divider() => const Divider(height: 1, color: Colors.grey);

  Widget _buildActionTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$title Coming Soon"),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
