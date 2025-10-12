import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';


/// Booth model from backend
class Booth {
  final String id;
  final String name;
  String address;
  final int radiusMeters;
  final double latitude;
  final double longitude;

  Booth({
    required this.id,
    required this.name,
    required this.address,
    required this.radiusMeters,
    required this.latitude,
    required this.longitude,
  });

  factory Booth.fromJson(Map<String, dynamic> json) {
    return Booth(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      address: json['description'] ?? '',
      radiusMeters: (json['radius_meters'] ?? 100).toInt(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  @override
  String toString() => '$name ($id)';
}


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
  Booth? _selectedBooth;
  File? _pickedImage;
  bool _loading = false;

  // Booths
  List<Booth> _booths = [];
  bool _loadingBooths = true;

  @override
  void initState() {
    super.initState();
    _loadBooths();
  }

  Future<void> _loadBooths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('https://voting-backend-6px8.onrender.com/api/admin/booths'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Booths status: ${response.statusCode}');
      print('Booths body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List data = json['booths'] ?? [];

        setState(() {
          _booths = data.map((e) => Booth.fromJson(e)).toList();
          _loadingBooths = false;
        });

        // ✅ Optional: reverse geocode to add human-readable address
        for (var b in _booths) {
          try {
            final placemarks = await placemarkFromCoordinates(
              b.latitude,
              b.longitude,
            );

            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              b.address = [
                p.street,
                p.locality,
                p.postalCode,
                p.country,
              ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
            }
          } catch (e) {
            debugPrint('Geocoding failed for ${b.name}: $e');
          }
        }

      } else {
        throw Exception('Failed to load booths (code: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load booths: $e')),
      );
      setState(() => _loadingBooths = false);
    }
  }

  double get _formCompletion {
    int total = 7;
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
      if (res != null) setState(() => _pickedImage = File(res.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message ?? 'unknown error'}')),
      );
    }
  }

  void _togglePassword() => setState(() => _obscurePassword = !_obscurePassword);

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

  bool _validateEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  bool _validatePhone(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found, please login again')),
      );
      setState(() => _loading = false);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBooth == null) return;

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('https://voting-backend-6px8.onrender.com/api/agent');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['firstName'] = _firstNameCtrl.text.trim();
      request.fields['lastName'] = _lastNameCtrl.text.trim();
      request.fields['agentUuid'] = _uuidCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['password'] = _passwordCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['boothId'] = _selectedBooth!.id;

      if (_pickedImage != null) {
        var pic = await http.MultipartFile.fromPath(
          'profilePhoto',
          _pickedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(pic);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent added successfully')),
        );
        _resetForm();
      } else {
        try {
          final resBody = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${resBody['error'] ?? 'Unknown error'}')),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const primary = Colors.blue;
    final textPrimary = Theme.of(context).colorScheme.onSurface.withOpacity(.9);
    final textSecondary = Theme.of(context).colorScheme.onSurface.withOpacity(.65);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Agent'), backgroundColor: primary, centerTitle: true),
      body: Stack(
          children: [
      SingleChildScrollView(
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
                        // UUID (manual entry only)
                        TextFormField(
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
                            if (v.trim().length != 12 || !RegExp(r'^\d{12}$').hasMatch(v.trim())) {
                              return 'Enter 12 digits';
                            }
                            return null;
                          },
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

            // ===================== Booth Selection + Preview =====================
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Row
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

                    // Dropdown for Booth Selection
                    DropdownButtonFormField<Booth>(
                      value: _selectedBooth,
                      decoration: const InputDecoration(
                        labelText: 'Select a Booth',
                        border: OutlineInputBorder(),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: primary),
                      items: _booths
                          .map(
                            (b) => DropdownMenuItem(
                          value: b,
                          child: Text(
                            '${b.name} • ${b.address.isNotEmpty ? b.address : "Locating..."}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBooth = v),
                      validator: (v) => v == null ? 'Please choose a booth' : null,
                    ),

                    const SizedBox(height: 12),

                    // Booth Preview
                    if (_selectedBooth != null)
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withOpacity(0.25)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
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
                                    _selectedBooth!.address.isNotEmpty
                                        ? _selectedBooth!.address
                                        : "Fetching address...",
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
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(_loading ? 'Adding...' : 'Add Agent'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

            if (_loading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
              ],
            ),
          ),
        ),
      ]
      )
    );
  }
}
