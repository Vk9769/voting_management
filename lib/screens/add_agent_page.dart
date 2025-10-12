import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'view_all_booth.dart'; // for demo booths

class AddAgentPage extends StatefulWidget {
  const AddAgentPage({super.key});

  @override
  State<AddAgentPage> createState() => _AddAgentPageState();
}

class _AddAgentPageState extends State<AddAgentPage> {
  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _uuidCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  Booth? selectedBooth;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  void _submitAgent() {
    if (_firstNameCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _uuidCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        selectedBooth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_uuidCtrl.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UUID must be 12 digits')),
      );
      return;
    }

    // For now, just print agent info
    print("Agent Info:");
    print("Name: ${_firstNameCtrl.text} ${_lastNameCtrl.text}");
    print("UUID: ${_uuidCtrl.text}");
    print("Email: ${_emailCtrl.text}");
    print("Phone: ${_phoneCtrl.text}");
    print("Booth: ${selectedBooth!.name}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agent Added Successfully (Demo)')),
    );

    // Clear fields
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _uuidCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    setState(() {
      profileImage = null;
      selectedBooth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Agent"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile photo
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                child: profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // First Name
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: "First Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Last Name
            TextField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                labelText: "Last Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // UUID
            TextField(
              controller: _uuidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "UUID (12 digits)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Email
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Password
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Select Booth
            DropdownButtonFormField<Booth>(
              value: selectedBooth,
              hint: const Text("Select Booth"),
              items: demoBooths.map((booth) {
                return DropdownMenuItem<Booth>(
                  value: booth,
                  child: Text(booth.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBooth = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submitAgent,
                child: const Text(
                  "Add Agent",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
