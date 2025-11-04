import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditCandidatePage extends StatefulWidget {
  final Map<String, dynamic> candidate;

  const EditCandidatePage({Key? key, required this.candidate}) : super(key: key);

  @override
  State<EditCandidatePage> createState() => _EditCandidatePageState();
}

class _EditCandidatePageState extends State<EditCandidatePage> {
  late TextEditingController nameController;
  late TextEditingController partyController;
  late TextEditingController descriptionController;
  late TextEditingController ageController;
  late TextEditingController constituencyController;
  late TextEditingController voterIdController;
  late TextEditingController aadhaarController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  String? gender;
  File? candidatePhoto;
  File? symbolPhoto;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    nameController = TextEditingController(text: widget.candidate['name']);
    partyController = TextEditingController(text: widget.candidate['party']);
    descriptionController =
        TextEditingController(text: widget.candidate['description']);
    ageController = TextEditingController(text: widget.candidate['age'] ?? '');
    constituencyController =
        TextEditingController(text: widget.candidate['constituency'] ?? '');
    voterIdController =
        TextEditingController(text: widget.candidate['voterId'] ?? '');
    aadhaarController =
        TextEditingController(text: widget.candidate['aadhaar'] ?? '');
    phoneController = TextEditingController(text: widget.candidate['phone'] ?? '');
    emailController = TextEditingController(text: widget.candidate['email'] ?? '');
    gender = widget.candidate['gender'];

    final controllers = [
      nameController,
      partyController,
      descriptionController,
      ageController,
      constituencyController,
      voterIdController,
      aadhaarController,
      phoneController,
      emailController,
    ];
    for (var controller in controllers) {
      controller.addListener(() => setState(() => _hasChanges = true));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    partyController.dispose();
    descriptionController.dispose();
    ageController.dispose();
    constituencyController.dispose();
    voterIdController.dispose();
    aadhaarController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCandidatePhoto) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (isCandidatePhoto) {
            candidatePhoto = File(pickedFile.path);
          } else {
            symbolPhoto = File(pickedFile.path);
          }
          _hasChanges = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error selecting image'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter candidate name');
      return false;
    }
    if (partyController.text.trim().isEmpty) {
      _showError('Please enter party name');
      return false;
    }
    if (ageController.text.trim().isNotEmpty &&
        int.tryParse(ageController.text.trim()) == null) {
      _showError('Please enter valid age (numbers only)');
      return false;
    }
    if (phoneController.text.trim().isNotEmpty &&
        !RegExp(r'^[0-9]{10}$').hasMatch(phoneController.text.trim())) {
      _showError('Please enter valid 10-digit phone number');
      return false;
    }
    if (emailController.text.trim().isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
            .hasMatch(emailController.text.trim())) {
      _showError('Please enter valid email address');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateCandidate() {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      String? candidateBase64 = widget.candidate['image'];
      String? symbolBase64 = widget.candidate['symbol'];

      if (candidatePhoto != null) {
        candidateBase64 = base64Encode(candidatePhoto!.readAsBytesSync());
      }

      if (symbolPhoto != null) {
        symbolBase64 = base64Encode(symbolPhoto!.readAsBytesSync());
      }

      Navigator.pop(context, {
        'name': nameController.text.trim(),
        'party': partyController.text.trim(),
        'description': descriptionController.text.trim(),
        'age': ageController.text.trim(),
        'gender': gender,
        'constituency': constituencyController.text.trim(),
        'voterId': voterIdController.text,
        'aadhaar': aadhaarController.text,
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'image': candidateBase64,
        'symbol': symbolBase64,
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('Error updating candidate: $e');
      _showError('Error updating candidate');
    }
  }

  Widget _buildPhotoSelector({
    required String title,
    required IconData icon,
    required File? selectedFile,
    required String? base64Data,
    required VoidCallback onTap,
    required bool isCircle,
  }) {
    ImageProvider? displayImage;
    if (selectedFile != null) {
      displayImage = FileImage(selectedFile);
    } else if (base64Data != null && base64Data.isNotEmpty) {
      try {
        displayImage = MemoryImage(base64Decode(base64Data));
      } catch (e) {
        debugPrint('Error decoding image: $e');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(16),
                color: Colors.blue.shade50,
                border: Border.all(
                  color: Colors.blue.shade700,
                  width: 2,
                ),
                image: displayImage != null
                    ? DecorationImage(image: displayImage, fit: BoxFit.cover)
                    : null,
              ),
              child: displayImage == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() => _hasChanges = true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.blue.shade50,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.blue.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue.shade700;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Unsaved Changes'),
              content: const Text('Do you want to discard your changes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep Editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Discard',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Candidate',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: themeColor,
          elevation: 3,
        ),
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 5,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPhotoSelector(
                    title: "Candidate Photo",
                    icon: Icons.person,
                    selectedFile: candidatePhoto,
                    base64Data: widget.candidate['image'],
                    onTap: () => _pickImage(true),
                    isCircle: true,
                  ),
                  const SizedBox(height: 25),
                  _buildPhotoSelector(
                    title: "Party Symbol",
                    icon: Icons.flag,
                    selectedFile: symbolPhoto,
                    base64Data: widget.candidate['symbol'],
                    onTap: () => _pickImage(false),
                    isCircle: false,
                  ),
                  const SizedBox(height: 30),

                  // Personal Information
                  _buildSectionHeader("Personal Information"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: nameController,
                    label: 'Candidate Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: ageController,
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      gender = value;
                      _hasChanges = true;
                    }),
                    decoration: _inputDecoration('Gender', Icons.wc),
                  ),
                  const SizedBox(height: 24),

                  // Government IDs
                  _buildSectionHeader("Government IDs"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: voterIdController,
                    label: 'Voter ID',
                    icon: Icons.how_to_vote,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: aadhaarController,
                    label: 'Aadhaar Card',
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionHeader("Contact Information"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),

                  // Political Information
                  _buildSectionHeader("Political Information"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: partyController,
                    label: 'Party Name',
                    icon: Icons.flag,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: constituencyController,
                    label: 'Constituency',
                    icon: Icons.location_city,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 30),

                  // Update Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'Updating...' : 'Update Candidate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _isSubmitting ? null : _updateCandidate,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade700,
        letterSpacing: 0.5,
      ),
    );
  }
}
