import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';

class CandidateProfilePage extends StatelessWidget {
  final Map<String, dynamic> candidate;

  const CandidateProfilePage({Key? key, required this.candidate})
      : super(key: key);

  ImageProvider? _getImageProvider(String? base64String) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding image: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue.shade700;
    final symbolImage = _getImageProvider(candidate['symbol']);
    final profileImage = _getImageProvider(candidate['image']);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildTricolorHeader(
                profileImage,
                symbolImage,
                themeColor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Personal Information"),
                  _buildInfoCard(Icons.person, "Name", candidate['name'], themeColor),
                  _buildInfoCard(Icons.wc, "Gender", candidate['gender'], themeColor),
                  _buildInfoCard(Icons.cake, "Age", candidate['age'], themeColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Government IDs"),
                  _buildInfoCard(Icons.credit_card, "Voter ID", candidate['voterId'], themeColor),
                  _buildInfoCard(Icons.badge, "Aadhaar Card", candidate['aadhaar'], themeColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Contact Information"),
                  _buildInfoCard(Icons.phone_android, "Phone", candidate['phone'], themeColor),
                  _buildInfoCard(Icons.email, "Email", candidate['email'], themeColor),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Political Information"),
                  _buildInfoCard(Icons.flag, "Party", candidate['party'], themeColor),
                  _buildInfoCard(Icons.location_city, "Constituency", candidate['constituency'], themeColor),
                  const SizedBox(height: 20),

                  if (candidate['description'] != null &&
                      candidate['description'].toString().trim().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Description"),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            candidate['description'],
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🇮🇳 Tricolor Header
  Widget _buildTricolorHeader(
      ImageProvider? profileImage,
      ImageProvider? symbolImage,
      Color themeColor,
      ) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/india_flag.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optional dark overlay for readability (you can remove if not needed)
          Container(
            color: Colors.black.withOpacity(0.25),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Candidate photo
                Hero(
                  tag: 'profile_photo_${candidate['name']}',
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Icon(Icons.person, size: 80, color: themeColor)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Candidate name
                Text(
                  candidate['name'] ?? "Candidate Name",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Party symbol
                if (symbolImage != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 3),
                      image: DecorationImage(
                        image: symbolImage,
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.3),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.flag, color: Colors.white, size: 45),
                  ),

                const SizedBox(height: 10),

                // Party name
                Text(
                  candidate['party'] ?? "Party Name",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon,
      String title,
      dynamic value,
      Color themeColor,
      ) {
    final displayValue = value != null && value.toString().trim().isNotEmpty
        ? value.toString()
        : "Not provided";

    return Card(
      elevation: 2,
      shadowColor: themeColor.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withOpacity(0.1),
            ),
            child: Icon(icon, color: themeColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          subtitle: Text(
            displayValue,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
