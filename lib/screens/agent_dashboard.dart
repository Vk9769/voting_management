import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'view_allocate_polling_booth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agent_profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'agent_report.dart';
import 'agent_messages_page.dart';
import 'agent_news_page.dart';


class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override

  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final ValueNotifier<Duration> onShiftNotifier = ValueNotifier(Duration.zero);

  String agentName = '';
  String boothName = '';
  String boothWard = '';
  String boothCode = '';

  int _selectedIndex = 0;

  // Shift tracking
  final DateTime shiftStart = DateTime.now().subtract(const Duration(minutes: 37));
  late Timer _timer;

  bool isSyncing = false;
  bool isOffline = false;

  late List<Voter> voters;
  final TextEditingController _searchCtrl = TextEditingController();
  VoterFilter _filter = VoterFilter.all;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
    voters = []; // temporarily empty, will generate after boothCode is loaded

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      onShiftNotifier.value = DateTime.now().difference(shiftStart);
    });
  }

  //emergency service
  Widget _buildEmergencyCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double width = 150,
    double height = 140,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,       // fixed width
        height: 160,      // fixed height
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps(String query) async {
    final Uri googleMapsUrl =
    Uri.parse('https://www.google.com/maps/search/$query+near+me');
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  Future<void> _loadAgentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      agentName = prefs.getString('agent_name') ?? 'Unknown Agent';
      boothName = prefs.getString('booth_name') ?? 'Booth N/A';
      boothWard = prefs.getString('booth_ward') ?? 'Ward N/A';
      boothCode = prefs.getString('booth_code') ?? 'BTH-N/A';

      // Generate voters dynamically for this booth
      voters = generateDemoVoters(120, assignedBoothCode: boothCode, seedMarkedEvery: 9);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    onShiftNotifier.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  int get totalVoters => voters.length;
  int get markedCount => voters.where((v) => v.isMarked).length;
  int get remainingCount => totalVoters - markedCount;

  List<Voter> get filteredVoters {
    final query = _searchCtrl.text.trim().toLowerCase();
    Iterable<Voter> data = voters;

    if (_filter == VoterFilter.pending) {
      data = data.where((v) => !v.isMarked);
    } else if (_filter == VoterFilter.marked) {
      data = data.where((v) => v.isMarked);
    }

    if (query.isNotEmpty) {
      data = data.where((v) =>
      v.name.toLowerCase().contains(query) ||
          v.id.toString().contains(query) ||
          v.govId.toLowerCase().contains(query));
    }
    return data.toList();
  }

  Future<void> _confirmMark(Voter voter) async {
    if (voter.isMarked) {
      // Already marked → allow undo immediately
      _undoMark(voter);
      return;
    }

    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark voter as voted?'),
        content: Text('Name: ${voter.name}\nGov ID: ${voter.govId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        voter.isMarked = true;
        voter.markedAt = DateTime.now();
      });

      // SnackBar with Undo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${voter.name} as voted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _undoMark(voter),
          ),
        ),
      );
    }
  }

  void _undoMark(Voter voter) {
    setState(() {
      voter.isMarked = false;
      voter.markedAt = null;
    });
  }

  Future<void> _simulateScan() async {
    // Simulate scanning a voter ID and marking them
    final theme = Theme.of(context);
    final scanned = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Scan / Enter Voter ID'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'e.g., 1042 or GOV-1042',
              prefixIcon: Icon(Icons.qr_code_scanner),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (scanned == null || scanned.isEmpty) return;

    final byId = int.tryParse(scanned);
    final voter = voters.firstWhere(
          (v) => v.id == byId || v.govId.toLowerCase() == scanned.toLowerCase(),
      orElse: () => Voter.notFound,
    );

    if (voter == Voter.notFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voter not found in your assigned booth')),
      );
      return;
    }

    await _confirmMark(voter);
  }

  Future<void> _reportIssue() async {
    final theme = Theme.of(context);
    final issue = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Report an Issue'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Describe the issue briefly...',
              prefixIcon: Icon(Icons.report_gmailerrorred),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (issue != null && issue.isNotEmpty) {
      setState(() {
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted')),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isSyncing = false;
      isOffline = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync complete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use agentName, boothName, boothWard, boothCode dynamically in UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateScan,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan ID'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.withOpacity(0.12),
                            child: Icon(Icons.person, color: Colors.blue, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome, $agentName',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    )),
                                const SizedBox(height: 2),
                                Text('Allocated: $boothName • $boothWard • $boothCode',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // KPI Grid
                  _KpiGrid(
                    total: totalVoters,
                    marked: markedCount,
                    remaining: remainingCount,
                    primary: Colors.blue,
                    bg: Colors.white,
                    textPrimary: Colors.black87,
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions Row (removed Sync button)
                  _QuickActionsRow(
                    primary: Colors.blue,
                    onScan: _simulateScan,
                    onReport: _reportIssue,
                  ),

                  const SizedBox(height: 16),

                  // Emergency Services Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Emergency Services',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Centered 2x2 grid
                          Center(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              runAlignment: WrapAlignment.center,
                              children: [
                                _buildEmergencyCard(
                                  title: 'Nearest\nPolice Station',
                                  icon: Icons.local_police,
                                  color: Colors.blue,
                                  onTap: () => _openMaps('police station'),
                                ),
                                _buildEmergencyCard(
                                  title: 'Nearest\nFire Brigade',
                                  icon: Icons.local_fire_department,
                                  color: Colors.red,
                                  onTap: () => _openMaps('fire station'),
                                ),
                                _buildEmergencyCard(
                                  title: 'Nearest\nHospital',
                                  icon: Icons.local_hospital,
                                  color: Colors.green,
                                  onTap: () => _openMaps('hospital'),
                                ),
                                _buildEmergencyCard(
                                  title: 'Food & Tiffin',
                                  icon: Icons.fastfood,
                                  color: Colors.orange,
                                  onTap: () => _openMaps('food tiffin near me'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Voters list and Recent Activity
                  if (!wide) ...[
                    _VoterPanel(
                      voters: filteredVoters,
                      total: totalVoters,
                      marked: markedCount,
                      remaining: remainingCount,
                      primary: Colors.blue,
                      textPrimary: Colors.black87,
                      textSecondary: Colors.black54,
                      dividerColor: Colors.grey.shade300,
                      searchCtrl: _searchCtrl,
                      filter: _filter,
                      onFilterChange: (f) => setState(() => _filter = f),
                      onMarkTap: _confirmMark,
                    ),
                    const SizedBox(height: 16),

                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _VoterPanel(
                            voters: filteredVoters,
                            total: totalVoters,
                            marked: markedCount,
                            remaining: remainingCount,
                            primary: Colors.blue,
                            textPrimary: Colors.black87,
                            textSecondary: Colors.black54,
                            dividerColor: Colors.grey.shade300,
                            searchCtrl: _searchCtrl,
                            filter: _filter,
                            onFilterChange: (f) => setState(() => _filter = f),
                            onMarkTap: _confirmMark,
                          ),
                        ),
                        const SizedBox(width: 16),

                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),

      // Bottom Footer
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: 'Voting'),
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: 'Travel'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AgentProfilePage()),
            );
          }
        },
      ),
    );
  }
}

/* ========== Models & Helpers ========== */

class Voter {
  Voter({
    required this.id,
    required this.name,
    required this.govId,
    required this.assignedBoothCode,
    this.isMarked = false,
    this.markedAt,
  });

  final int id;
  final String name;
  final String govId;
  final String assignedBoothCode;
  bool isMarked;
  DateTime? markedAt;

  static Voter notFound = Voter(
    id: -1,
    name: 'Not Found',
    govId: 'N/A',
    assignedBoothCode: 'N/A',
  );
}

List<Voter> generateDemoVoters(
    int count, {
      required String assignedBoothCode,
      int seedMarkedEvery = 10,
    }) {
  return List.generate(count, (i) {
    final id = 1000 + i;
    final name = 'Voter ${i + 1}';
    final govId = 'GOV-$id';
    final marked = (i % seedMarkedEvery == 0);
    return Voter(
      id: id,
      name: name,
      govId: govId,
      assignedBoothCode: assignedBoothCode,
      isMarked: marked,
      markedAt: marked ? DateTime.now().subtract(Duration(minutes: (i % 45))) : null,
    );
  });
}

enum VoterFilter { all, pending, marked }

/* ========== UI Widgets ========== */

class _ShiftTimer extends StatelessWidget {
  const _ShiftTimer({required this.onShift, required this.primary, required this.textPrimary});

  final Duration onShift;
  final Color primary;
  final Color textPrimary;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('On shift', style: TextStyle(fontSize: 12, color: textPrimary.withOpacity(0.8))),
              Text(
                _fmt(onShift),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.total,
    required this.marked,
    required this.remaining,
    required this.primary,
    required this.bg,
    required this.textPrimary,
  });

  final int total;
  final int marked;
  final int remaining;
  final Color primary;
  final Color bg;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cross = width >= 1000 ? 3 : 2;

    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 180,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: 'Total Voters',
          value: total.toString(),
          icon: Icons.people,
          iconBgColor: Colors.blue.withOpacity(0.2),
          textColor: Colors.blue,
          bg: bg,
        ),
        _StatCard(
          title: 'Marked by You',
          value: marked.toString(),
          icon: Icons.verified_user,
          iconBgColor: Colors.green.withOpacity(0.2),
          textColor: Colors.green,
          bg: bg,
        ),
        _StatCard(
          title: 'Remaining',
          value: remaining.toString(),
          icon: Icons.pending_actions,
          iconBgColor: Colors.orange.withOpacity(0.2),
          textColor: Colors.orange,
          bg: bg,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.textColor,
    required this.bg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color textColor;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: bg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.primary,
    required this.onScan,
    required this.onReport,
  });

  final Color primary;
  final VoidCallback onScan;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 720;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // --- View Allocated Booth ---
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewAllocatePollingBoothPage()),
              );
            },
            icon: const Icon(Icons.location_on),
            label: const Text('View Allocated Booth'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // --- Report Issue ---
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentReportPage()),
              );
            },
            icon: Icon(Icons.report_gmailerrorred, color: primary),
            label: Text(
              'Report Issue',
              style: TextStyle(color: primary, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        // --- Campaign ---
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.campaign),
            label: const Text('Campaign'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // --- Messages (Outlined) ---
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentMessagesPage()),
              );
            },
            icon: Icon(Icons.message, color: primary),
            label: Text(
              'Messages',
              style: TextStyle(color: primary, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        // --- Daily News ---
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentNewsPage()),
              );
            },
            icon: const Icon(Icons.newspaper),
            label: const Text('Daily News'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoterPanel extends StatelessWidget {
  const _VoterPanel({
    required this.voters,
    required this.total,
    required this.marked,
    required this.remaining,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.searchCtrl,
    required this.filter,
    required this.onFilterChange,
    required this.onMarkTap,
  });

  final List<Voter> voters;
  final int total;
  final int marked;
  final int remaining;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final TextEditingController searchCtrl;
  final VoterFilter filter;
  final ValueChanged<VoterFilter> onFilterChange;
  final Future<void> Function(Voter voter) onMarkTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.list_alt, color: primary),
                const SizedBox(width: 8),
                Text('Voters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
                const Spacer(),
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      // If values are dynamic, keep as is. But for static text:
                      const _CountPill(label: 'Total', value: 0, primary: Colors.blue),
                      _CountPill(label: 'Marked', value: marked, primary: primary),
                      _CountPill(label: 'Remaining', value: remaining, primary: primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: searchCtrl,
              onChanged: (_) => (context as Element).markNeedsBuild(),
              decoration: InputDecoration(
                hintText: 'Search by name / ID / Gov ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // Filter chips
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter == VoterFilter.all,
                  onSelected: (_) => onFilterChange(VoterFilter.all),
                  selectedColor: primary.withOpacity(.12),
                  checkmarkColor: primary,
                  side: BorderSide(color: primary.withOpacity(filter == VoterFilter.all ? .4 : .2)),
                ),
                FilterChip(
                  label: const Text('Pending'),
                  selected: filter == VoterFilter.pending,
                  onSelected: (_) => onFilterChange(VoterFilter.pending),
                  selectedColor: primary.withOpacity(.12),
                  checkmarkColor: primary,
                  side: BorderSide(color: primary.withOpacity(filter == VoterFilter.pending ? .4 : .2)),
                ),
                FilterChip(
                  label: const Text('Marked'),
                  selected: filter == VoterFilter.marked,
                  onSelected: (_) => onFilterChange(VoterFilter.marked),
                  selectedColor: primary.withOpacity(.12),
                  checkmarkColor: primary,
                  side: BorderSide(color: primary.withOpacity(filter == VoterFilter.marked ? .4 : .2)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: dividerColor),

            // List
            const SizedBox(height: 8),
            if (voters.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No voters match your criteria', style: TextStyle(color: textSecondary)),
                ),
              )
            else
            // Wrap with Expanded or SizedBox for performance
              SizedBox(
                height: 400, // or any fixed height depending on your design
                child: ListView.builder(
                  itemCount: voters.length,
                  itemBuilder: (context, index) {
                    final voter = voters[index];
                    return Column(
                      children: [
                        _VoterTile(
                          voter: voter,
                          primary: primary,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTapMark: () => onMarkTap(voter),
                        ),
                        if (index != voters.length - 1)
                          Divider(color: dividerColor, height: 1),
                      ],
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.value, required this.primary});
  final String label;
  final int value;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.black87)),
          Text('$value', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _VoterTile extends StatelessWidget {
  const _VoterTile({
    required this.voter,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTapMark,
  });

  final Voter voter;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTapMark;

  @override
  Widget build(BuildContext context) {
    final statusBg = voter.isMarked ? primary.withOpacity(.10) : Colors.transparent;
    final statusText = voter.isMarked ? 'Marked' : 'Pending';
    final statusIcon = voter.isMarked ? Icons.verified : Icons.schedule;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: primary.withOpacity(.12),
        child: Icon(Icons.person, color: primary),
      ),
      title: Text(voter.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text('ID: ${voter.id} • ${voter.govId}', style: TextStyle(color: textSecondary)),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: primary.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, size: 16, color: primary),
                  const SizedBox(width: 4),
                  Text(statusText, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            voter.isMarked
                ? OutlinedButton(
              onPressed: onTapMark,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary, width: 1.25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Undo', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
            )
                : FilledButton(
              onPressed: onTapMark,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mark'),
            ),
          ],
        ),
      ),
    );
  }
}