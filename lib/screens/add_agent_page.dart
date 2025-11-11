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
      address: json['address'] ?? '',
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
  final _voterIdCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // State
  bool _obscurePassword = true;
  Booth? _selectedBooth;
  File? _pickedImage;
  bool _loading = false;

  // Role Selector
  String? _selectedRole;

// keep a master list of all possible creatable roles
  final List<Map<String, String>> _rolesAll = [
    {'label': 'Super Admin', 'value': 'super_admin'},
    {'label': 'Admin', 'value': 'admin'},
    {'label': 'Super Agent', 'value': 'super_agent'},
    {'label': 'Agent', 'value': 'agent'},
  ];

// will hold only the roles allowed for the logged-in creator
  List<Map<String, String>> _rolesAllowed = [];

// logged-in creator's role (from SharedPreferences set at login)
  String? _creatorRole;


  String? _selectedIdType;
  final List<String> _idTypes = [
    'Aadhar Card',
    'Passport',
    'Driving License',
    'PAN Card',
  ];

  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
  locationHierarchy = {};

  List<String> _states = [];
  List<String> _districts = [];
  List<String> _assemblies = [];
  List<Map<String, dynamic>> _parts = [];

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedAssembly;
  String? _selectedPart;

  @override
  void initState() {
    super.initState();
    _fetchLocationHierarchy();
    _loadRoleAndFilter(); // <-- add this
  }

  Future<void> _fetchLocationHierarchy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://13.61.32.111:3000/api/admin/booths/full'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print("Error: ${response.body}");
        return;
      }

      final List data = json.decode(response.body);

      print("API DATA LENGTH: ${data.length}");
      print("First Item: ${data.isNotEmpty ? data[0] : 'No Data'}");

      Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> temp =
      {};

      for (var booth in data) {
        final state = booth['state']?.toString().trim() ?? '';
        final district = booth['district']?.toString().trim() ?? '';
        final assembly =
            booth['assembly_constituency']?.toString().trim() ?? '';
        final part = booth['part_name']?.toString().trim() ?? '';
        final boothId = booth['id']?.toString();
        final boothName = booth['name']?.toString() ?? 'Unknown Booth';

        if (state.isEmpty ||
            district.isEmpty ||
            assembly.isEmpty ||
            part.isEmpty)
          continue;

        temp[state] ??= {};
        temp[state]![district] ??= {};
        temp[state]![district]![assembly] ??= [];

        // Store full booth info
        temp[state]![district]![assembly]!.add({
          "id": boothId,
          "name": boothName,
          "part_name": part,
        });
      }

      setState(() {
        locationHierarchy = temp;
        _states = temp.keys.toList()..sort();
      });
    } catch (e) {
      print("Fetch error => $e");
    }
  }

  double get _formCompletion {
    int total = 15;
    int filled = 0;
    if (_firstNameCtrl.text.trim().isNotEmpty) filled++;
    if (_lastNameCtrl.text.trim().isNotEmpty) filled++;
    if (_selectedIdType != null) filled++;
    if (_idNumberCtrl.text.trim().isNotEmpty) filled++;
    if (_emailCtrl.text.trim().isNotEmpty) filled++;
    if (_passwordCtrl.text.trim().isNotEmpty) filled++;
    if (_phoneCtrl.text.trim().isNotEmpty) filled++;
    if (_selectedRole != null) filled++;
    if (_selectedState != null) filled++;
    if (_selectedDistrict != null) filled++;
    if (_selectedAssembly != null) filled++;
    if (_selectedPart != null) filled++; // ✅ Correct booth selection
    if (_selectedGender != null) filled++;
    if (_dobCtrl.text.trim().isNotEmpty) filled++;
    if (_addressCtrl.text.trim().isNotEmpty) filled++;
    return filled / total;
  }
  Future<void> _loadRoleAndFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('role') ?? '').toLowerCase();

    // must mirror backend permissions
    const Map<String, List<String>> permissions = {
      'master_admin': ['super_admin', 'admin', 'super_agent', 'agent'],
      'super_admin':  ['admin', 'super_agent', 'agent'],
      'admin':        ['super_agent', 'agent'],
      'super_agent':  ['agent'],
      'agent':        [],
    };

    final allowedValues = permissions[role] ?? [];

    setState(() {
      _creatorRole = role;
      _rolesAllowed = _rolesAll
          .where((r) => allowedValues.contains(r['value']))
          .toList();

      // if previously selected role is not allowed anymore, clear it
      if (_selectedRole != null &&
          !_rolesAllowed.any((r) => r['value'] == _selectedRole)) {
        _selectedRole = null;
      }
    });
  }
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final res = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (res != null) setState(() => _pickedImage = File(res.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: ${e.message ?? 'unknown error'}',
          ),
        ),
      );
    }
  }

  void _togglePassword() =>
      setState(() => _obscurePassword = !_obscurePassword);

  void _resetForm() {
    _formKey.currentState?.reset();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _voterIdCtrl.clear();
    _idNumberCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _phoneCtrl.clear();
    _addressCtrl.clear();
    _dobCtrl.clear();
    _pickedImage = null;

    _selectedGender = null;
    _selectedRole = null;
    _selectedIdType = null;

    _selectedState = null;
    _selectedDistrict = null;
    _selectedAssembly = null;
    _selectedPart = null;

    // ✅ DO NOT CLEAR STATE DATA
    setState(() {});
  }

  bool _validateEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  bool _validatePhone(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  bool _validateIdNumber(String v, String idType) {
    final cleaned = v.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    switch (idType) {
      case 'Aadhar Card':
        return cleaned.length == 12 && RegExp(r'^\d{12}$').hasMatch(cleaned);
      case 'Passport':
        return cleaned.length >= 6 && cleaned.length <= 9;
      case 'Driving License':
        return cleaned.length >= 10;
      case 'PAN Card':
        return cleaned.length == 10;
      default:
        return cleaned.isNotEmpty;
    }
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found, please login again')),
      );
      setState(() => _loading = false);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedPart == null ||
        _selectedRole == null ||
        _selectedIdType == null)
      return;

// Validate required dropdowns
    if (_selectedPart == null || _selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

// ensure role is selected and allowed
    if (_rolesAllowed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your role ($_creatorRole) cannot create users')),
      );
      return;
    }

    if (_selectedRole == null ||
        !_rolesAllowed.any((r) => r['value'] == _selectedRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid role')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uri = Uri.parse(
        'http://13.61.32.111:3000/api/agent',
      ); // ✅ UPDATED URL

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['firstName'] = _firstNameCtrl.text.trim();
      request.fields['lastName'] = _lastNameCtrl.text.trim();
      request.fields['voterId'] = _voterIdCtrl.text.trim();
      request.fields['idType'] = _selectedIdType!;
      request.fields['idNumber'] = _idNumberCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['password'] = _passwordCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['role'] = _selectedRole!;
      request.fields['state'] = _selectedState ?? '';
      request.fields['district'] = _selectedDistrict ?? '';
      request.fields['assembly_constituency'] = _selectedAssembly ?? '';
      request.fields['boothId'] = _selectedPart!; // ✅ Correct
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['dob'] = _dobCtrl.text.trim();
      request.fields['address'] = _addressCtrl.text.trim();

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

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent added successfully')),
        );
        _resetForm();
      } else {
        try {
          final resBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${resBody['error'] ?? 'Unknown error'}'),
            ),
          );
        } catch (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Colors.blue;
    final textPrimary = Theme.of(context).colorScheme.onSurface.withOpacity(.9);
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(.65);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Add Agent/Admin'),
        backgroundColor: primary,
        centerTitle: true,
      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: primary.withOpacity(.12),
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : null,
                            child: _pickedImage == null
                                ? const Icon(
                              Icons.person,
                              color: primary,
                              size: 36,
                            )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Profile Photo',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.photo_library,
                              color: primary,
                            ),
                            label: const Text(
                              'Choose',
                              style: TextStyle(color: primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: primary,
                                width: 1.25,
                              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Name fields
                          TextFormField(
                            controller: _firstNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.badge, color: primary),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Last name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // ✅ Voter ID Field
                          TextFormField(
                            controller: _voterIdCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Voter ID Number',
                              prefixIcon: Icon(
                                Icons.how_to_vote,
                                color: primary,
                              ),
                              border: OutlineInputBorder(),
                              hintText: 'e.g., XYZ1234567',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Voter ID is required';
                              if (v.trim().length < 10)
                                return 'Invalid Voter ID (min 10 characters)';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ID Type & Number
                          DropdownButtonFormField<String>(
                            value: _selectedIdType,
                            decoration: const InputDecoration(
                              labelText: 'Select ID Type',
                              prefixIcon: Icon(
                                Icons.card_membership,
                                color: primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: primary,
                            ),
                            items: _idTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedIdType = v),
                            validator: (v) =>
                            v == null ? 'Please select an ID type' : null,
                          ),
                          const SizedBox(height: 12),
                          if (_selectedIdType != null)
                            TextFormField(
                              controller: _idNumberCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: '$_selectedIdType Number',
                                prefixIcon: const Icon(
                                  Icons.confirmation_number,
                                  color: primary,
                                ),
                                border: const OutlineInputBorder(),
                                hintText: _getIdHint(_selectedIdType!),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return '${_selectedIdType} number is required';
                                }
                                if (!_validateIdNumber(v, _selectedIdType!)) {
                                  return 'Enter a valid ${_selectedIdType} number';
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
                              if (v == null || v.trim().isEmpty)
                                return 'Email is required';
                              if (!_validateEmail(v))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: primary,
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: _togglePassword,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: primary,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Password is required';
                              if (v.trim().length < 6)
                                return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phoneCtrl,
                            textInputAction: TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone, color: primary),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Phone is required';
                              if (!_validatePhone(v))
                                return 'Enter a valid phone';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          const SizedBox(height: 12),

                          // Gender Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.blue,
                            ),
                            items: _genders
                                .map(
                                  (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ),
                            )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                            validator: (v) =>
                            v == null ? 'Please select gender' : null,
                          ),

                          const SizedBox(height: 12),

                          // DOB Picker
                          TextFormField(
                            controller: _dobCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              border: OutlineInputBorder(),
                              hintText: 'Select Date',
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime(1990, 1, 1),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                _dobCtrl.text =
                                "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                setState(() {});
                              }
                            },
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please select date of birth'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          // Address
                          TextFormField(
                            controller: _addressCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(
                                Icons.location_city,
                                color: Colors.blue,
                              ),
                              border: OutlineInputBorder(),
                              hintText: 'Enter full address',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Address is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Role Dropdown
                          // Role Dropdown (filtered by creator permissions)
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              border: const OutlineInputBorder(),
                              helperText: (_rolesAllowed.isEmpty)
                                  ? 'Your role ($_creatorRole) cannot create any roles'
                                  : null,
                            ),
                            items: _rolesAllowed.map((role) =>
                                DropdownMenuItem<String>(
                                  value: role['value'],
                                  child: Text(role['label']!),
                                )
                            ).toList(),
                            onChanged: _rolesAllowed.isEmpty
                                ? null // disable if no allowed roles
                                : (v) => setState(() => _selectedRole = v),
                            validator: (v) {
                              if (_rolesAllowed.isEmpty) return null; // nothing to choose = no validation
                              return v == null ? 'Please select a role' : null;
                            },
                          ),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // STATE
                          // STATE
                          DropdownButtonFormField<String>(
                            value: _selectedState,
                            items: _states
                                .map(
                                  (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ),
                            )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedState = v;
                                _districts = locationHierarchy[v]!.keys
                                    .toList();
                                _selectedDistrict = null;
                                _assemblies = [];
                                _selectedAssembly = null;
                                _parts = [];
                                _selectedPart = null;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: "Select State",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // DISTRICT
                          if (_selectedState != null)
                            DropdownButtonFormField<String>(
                              value: _selectedDistrict,
                              items: _districts
                                  .map(
                                    (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ),
                              )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedDistrict = v;
                                  _assemblies =
                                      locationHierarchy[_selectedState]![v]!
                                          .keys
                                          .toList();
                                  _selectedAssembly = null;
                                  _parts = [];
                                  _selectedPart = null;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "Select District",
                                border: OutlineInputBorder(),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // ASSEMBLY
                          if (_selectedDistrict != null)
                            DropdownButtonFormField<String>(
                              value: _selectedAssembly,
                              items: _assemblies
                                  .map(
                                    (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a),
                                ),
                              )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedAssembly = v;
                                  _parts = List<Map<String, dynamic>>.from(
                                    locationHierarchy[_selectedState]![_selectedDistrict]![v]!,
                                  );
                                  _selectedPart = null;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "Select Assembly Constituency",
                                border: OutlineInputBorder(),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // BOOTH
                          if (_selectedAssembly != null)
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              itemHeight: null,
                              value: _selectedPart,

                              // ✅ This fixes the selected text overflow
                              selectedItemBuilder: (context) {
                                return _parts.map((p) {
                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "${p["part_name"]} - ${p["name"]}",
                                      maxLines: 3,            // ✅ allow up to 3 lines while selected
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList();
                              },

                              items: _parts.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p["id"].toString(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      "${p["part_name"]} - ${p["name"]}",
                                      softWrap: true,
                                      maxLines: 5,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              }).toList(),

                              onChanged: (v) => setState(() => _selectedPart = v),

                              decoration: const InputDecoration(
                                labelText: "Select Booth",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null ? "Select booth" : null,
                            ),

                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress + Buttons Card
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: primary,
                                  ),
                                  label: const Text(
                                    'Reset',
                                    style: TextStyle(color: primary),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: primary,
                                      width: 1.25,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
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
                                  label: Text(
                                    _loading ? 'Adding...' : 'Add Agent',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIdHint(String idType) {
    switch (idType) {
      case 'Aadhar Card':
        return '12 digits (e.g., 123456789012)';
      case 'Passport':
        return '6-9 characters';
      case 'Voter ID':
        return 'Minimum 10 characters';
      case 'Driving License':
        return 'Minimum 10 characters';
      case 'PAN Card':
        return '10 characters (e.g., ABCDE1234F)';
      default:
        return '';
    }
  }
}