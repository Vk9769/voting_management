import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// A simple demo booth model used locally on this page
class DemoBooth {
  final String id;
  final String name;
  final String address;
  final int radiusMeters;

  const DemoBooth({
    required this.id,
    required this.name,
    required this.address,
    required this.radiusMeters,
  });

  @override
  String toString() => '$name ($id)';
}

// Local demo data since there is no separate demo booth page
const List<DemoBooth> demoBooths = [
  DemoBooth(
    id: 'B001',
    name: 'Booth #1',
    address: 'Ward 1, Community Hall',
    radiusMeters: 100,
  ),
  DemoBooth(
    id: 'B005',
    name: 'Booth #5',
    address: 'Ward 2, City School',
    radiusMeters: 120,
  ),
  DemoBooth(
    id: 'B008',
    name: 'Booth #8',
    address: 'Ward 3, Health Center',
    radiusMeters: 150,
  ),
  DemoBooth(
    id: 'B013',
    name: 'Booth #13',
    address: 'Ward 4, Library Campus',
    radiusMeters: 110,
  ),
];

class AddAgentPage extends StatefulWidget {
  const AddAgentPage({super.key});

  @override
  State<AddAgentPage> createState() => _AddAgentPageState();
}

class _AddAgentPageState extends State<AddAgentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _uuidCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // State
  bool _obscurePassword = true;
  DemoBooth? _selectedBooth;
  File? _pickedImage;

  // For "form completeness" indicator
  double get _formCompletion {
    int total = 7; // first, last, uuid, email, password, phone, booth
    int filled = 0;
    if (_firstNameCtrl.text.trim().isNotEmpty) filled++;
    if (_lastNameCtrl.text.trim().isNotEmpty) filled++;
    if (_uuidCtrl.text.trim().length == 12) filled++;
    if (_emailCtrl.text.trim().isNotEmpty) filled++;
    if (_passwordCtrl.text.trim().isNotEmpty) filled++;
    if (_phoneCtrl.text.trim().isNotEmpty) filled++;
    if (_selectedBooth != null) filled++;
    return filled / total;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final res = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (res != null) {
        setState(() => _pickedImage = File(res.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message ?? 'unknown error'}')),
      );
    }
  }

  void _togglePassword() => setState(() => _obscurePassword = !_obscurePassword);

  void _generateUUID() {
    // Simple 12-digit generator for demo purposes
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final digits = now.replaceAll(RegExp(r'[^0-9]'), '');
    final uuid = (digits + '000000000000').substring(0, 12);
    _uuidCtrl.text = uuid;
    setState(() {});
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _uuidCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    _selectedBooth = null;
    _pickedImage = null;
    setState(() {});
  }

  bool _validateEmail(String v) {
    // Minimal email validation
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
  }

  bool _validatePhone(String v) {
    // Accept 7-15 digits for flexibility
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'uuid': _uuidCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'boothId': _selectedBooth?.id,
      'boothName': _selectedBooth?.name,
      'boothAddress': _selectedBooth?.address,
      'boothRadiusMeters': _selectedBooth?.radiusMeters,
      'hasPhoto': _pickedImage != null,
    };

    // Print collected info (replace with your API/integration)
    // ignore: avoid_print
    print('[AddAgent] Submit data: $data');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agent added successfully')),
    );
    _resetForm();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _uuidCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Strictly use Colors.blue + white + neutrals
    const primary = Colors.blue;
    final textPrimary = Theme.of(context).colorScheme.onSurface.withOpacity(.9);
    final textSecondary = Theme.of(context).colorScheme.onSurface.withOpacity(.65);
    final divider = Theme.of(context).dividerColor.withOpacity(.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Agent'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Photo Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primary.withOpacity(.12),
                          backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                          child: _pickedImage == null
                              ? const Icon(Icons.person, color: primary, size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Profile Photo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library, color: primary),
                          label: const Text('Choose', style: TextStyle(color: primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primary, width: 1.25),
                          ),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Form Fields Card
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // First & Last Name
                        TextFormField(
                          controller: _firstNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.badge, color: primary),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.badge_outlined, color: primary),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                        ),
                        const SizedBox(height: 12),

                        // UUID with generator
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _uuidCtrl,
                                textInputAction: TextInputAction.next,
                                maxLength: 12,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(12),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Agent UUID (12 digits)',
                                  prefixIcon: Icon(Icons.confirmation_number, color: primary),
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'UUID is required';
                                  }
                                  if (v.trim().length != 12 ||
                                      !RegExp(r'^\d{12}$').hasMatch(v.trim())) {
                                    return 'Enter 12 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _generateUUID,
                                icon: const Icon(Icons.auto_awesome, color: primary),
                                label: const Text('Generate', style: TextStyle(color: primary)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: primary, width: 1.25),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: primary),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!_validateEmail(v)) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password with visibility toggle
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock, color: primary),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: _togglePassword,
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: primary,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Password is required';
                            if (v.trim().length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: _phoneCtrl,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone, color: primary),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone is required';
                            if (!_validatePhone(v)) return 'Enter a valid phone';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Booth Selection + Preview
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.how_to_vote, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned Booth',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<DemoBooth>(
                          value: _selectedBooth,
                          decoration: const InputDecoration(
                            labelText: 'Select a Booth',
                            border: OutlineInputBorder(),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: primary),
                          items: demoBooths
                              .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text('${b.name} • ${b.address}'),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedBooth = v),
                          validator: (v) => v == null ? 'Please choose a booth' : null,
                        ),
                        const SizedBox(height: 12),
                        if (_selectedBooth != null)
                          Container(
                            decoration: BoxDecoration(
                              color: primary.withOpacity(.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withOpacity(.25)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: primary.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.place, color: primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedBooth!.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedBooth!.address,
                                        style: TextStyle(color: textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Radius: ${_selectedBooth!.radiusMeters} m',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Completeness and Actions
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.task_alt, color: primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _formCompletion.clamp(0, 1),
                                backgroundColor: primary.withOpacity(.12),
                                color: primary,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(_formCompletion * 100).round()}%',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 220,
                              child: OutlinedButton.icon(
                                onPressed: _resetForm,
                                icon: const Icon(Icons.refresh, color: primary),
                                label: const Text('Reset', style: TextStyle(color: primary)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: primary, width: 1.25),
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add Agent'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  'All actions use a strictly blue and white theme for visual consistency.',
                  style: TextStyle(color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
