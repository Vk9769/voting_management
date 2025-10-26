import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VoterProfilePage extends StatefulWidget {
  const VoterProfilePage({super.key});

  @override
  State<VoterProfilePage> createState() => _VoterProfilePageState();
}

class _VoterProfilePageState extends State<VoterProfilePage> {
  String firstName = '';
  String lastName = '';
  String fatherName = '';
  String voterEmail = '';
  String voterId = '';
  String phoneNumber = '';
  String documentType = 'Aadhaar'; // Default document type
  String documentNumber = '';
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _documentTypes = ['Aadhaar', 'Passport', 'Voter ID', 'Driving License'];

  @override
  void initState() {
    super.initState();
    _loadVoterData();
  }

  Future<void> _loadVoterData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fullName = prefs.getString('user_name') ?? 'Unknown Voter';
      List<String> names = fullName.split(' ');
      firstName = names.isNotEmpty ? names[0] : '';
      lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      fatherName = prefs.getString('father_name') ?? '';
      voterEmail = prefs.getString('user_email') ?? '';
      voterId = prefs.getString('user_id') ?? '';
      phoneNumber = prefs.getString('user_phone') ?? '';
      documentType = prefs.getString('user_doc_type') ?? 'Aadhaar';
      documentNumber = prefs.getString('user_doc_number') ?? '';
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
    await prefs.setString('user_name', '$firstName $lastName');
    await prefs.setString('father_name', fatherName);
    await prefs.setString('user_phone', phoneNumber);
    await prefs.setString('user_email', voterEmail);
    await prefs.setString('user_doc_type', documentType);
    await prefs.setString('user_doc_number', documentNumber);
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
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadVoterData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/user_avatar.png')
                    as ImageProvider,
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
              const SizedBox(height: 15),
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text("Voter ID: $voterId",
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 25),

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
                  value: phoneNumber,
                  onChanged: (v) => phoneNumber = v),
              const SizedBox(height: 10),
              _buildEditableField(
                  icon: Icons.email,
                  label: "Email",
                  value: voterEmail,
                  onChanged: (v) => voterEmail = v),
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

              // Booth & Voting Info
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoTile(
                          Icons.location_on, "Booth Location", "KanjurMarg, Mumbai"),
                      _divider(),
                      _buildInfoTile(Icons.how_to_vote, "Voting Status", "Pending"),
                    ],
                  ),
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
                          content: const Text("Are you sure you want to logout?"),
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

  Widget _divider() => const Divider(height: 20, color: Colors.grey);

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
