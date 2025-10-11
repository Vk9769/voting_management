import 'dart:async';
import 'package:flutter/material.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  // Agent and booth info (replace with real data)
  final String agentName = 'A. Khan';
  final String boothName = 'Booth #13';
  final String boothWard = 'Ward 4';
  final String boothCode = 'BTH-13-W4';

  // Shift tracking
  final DateTime shiftStart = DateTime.now().subtract(const Duration(minutes: 37));
  late Timer _timer;
  Duration onShift = Duration.zero;

  // Sync state
  bool isSyncing = false;
  bool isOffline = false;

  // Voter data (in-memory for demo)
  late List<Voter> voters;

  // UI filters and search
  final TextEditingController _searchCtrl = TextEditingController();
  VoterFilter _filter = VoterFilter.all;

  // Recent activity log
  final List<Activity> _activity = [
    Activity('Checked in voter', 'ID 1007 • Booth #13', DateTime.now().subtract(const Duration(minutes: 12))),
    Activity('Synced updates', '3 voters uploaded', DateTime.now().subtract(const Duration(hours: 1, minutes: 4))),
    Activity('Flagged issue', 'Long queue near entry', DateTime.now().subtract(const Duration(hours: 2, minutes: 18))),
  ];

  @override
  void initState() {
    super.initState();
    voters = generateDemoVoters(120, assignedBoothCode: boothCode, seedMarkedEvery: 9);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        onShift = DateTime.now().difference(shiftStart);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
        _activity.insert(0, Activity('Checked in voter', 'ID ${voter.id} • ${voter.govId}', DateTime.now()));
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
      _activity.insert(0, Activity('Undo check-in', 'ID ${voter.id} • ${voter.govId}', DateTime.now()));
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
        _activity.insert(0, Activity('Issue reported', issue, DateTime.now()));
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
      _activity.insert(0, Activity('Synced updates', '${markedCount} voters uploaded', DateTime.now()));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync complete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = Colors.blue;
    final Color bg = theme.colorScheme.surface; // white
    final Color textPrimary = theme.colorScheme.onSurface.withOpacity(0.9);
    final Color textSecondary = theme.colorScheme.onSurface.withOpacity(0.65);
    final dividerColor = theme.dividerColor.withOpacity(0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
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
                  // Header Card
                  Card(
                    color: bg,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primary.withOpacity(0.12),
                            child: Icon(Icons.person, color: primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome, $agentName',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    )),
                                const SizedBox(height: 2),
                                Text('Allocated: $boothName • $boothWard • $boothCode',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _ShiftTimer(onShift: onShift, primary: primary, textPrimary: textPrimary),
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
                    primary: primary,
                    bg: bg,
                    textPrimary: textPrimary,
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions and Sync Status
                  _QuickActionsRow(
                    primary: primary,
                    onScan: _simulateScan,
                    onReport: _reportIssue,
                    onSync: _syncNow,
                    isSyncing: isSyncing,
                    isOffline: isOffline,
                  ),

                  const SizedBox(height: 16),

                  // Two-up: Voters list and Recent Activity
                  if (!wide) ...[
                    _VoterPanel(
                      voters: filteredVoters,
                      total: totalVoters,
                      marked: markedCount,
                      remaining: remainingCount,
                      primary: primary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                      searchCtrl: _searchCtrl,
                      filter: _filter,
                      onFilterChange: (f) => setState(() => _filter = f),
                      onMarkTap: _confirmMark,
                    ),
                    const SizedBox(height: 16),
                    _ActivityPanel(
                      activity: _activity,
                      primary: primary,
                      bg: bg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: dividerColor,
                    ),
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
                            primary: primary,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            dividerColor: dividerColor,
                            searchCtrl: _searchCtrl,
                            filter: _filter,
                            onFilterChange: (f) => setState(() => _filter = f),
                            onMarkTap: _confirmMark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _ActivityPanel(
                            activity: _activity,
                            primary: primary,
                            bg: bg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            dividerColor: dividerColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
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
        // Increased height so Column content fits comfortably on all devices
        mainAxisExtent: 180,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(title: 'Total Voters', value: total.toString(), icon: Icons.people, primary: primary, bg: bg, textPrimary: textPrimary),
        _StatCard(title: 'Marked by You', value: marked.toString(), icon: Icons.verified_user, primary: primary, bg: bg, textPrimary: textPrimary),
        _StatCard(title: 'Remaining', value: remaining.toString(), icon: Icons.pending_actions, primary: primary, bg: bg, textPrimary: textPrimary),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.primary,
    required this.bg,
    required this.textPrimary,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color primary; // kept for signature compatibility, not used
  final Color bg;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: bg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          label: '$title: $value',
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Use fixed small gaps instead of Spacer to avoid tight vertical pressure
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const SizedBox.shrink(), // placeholder, replaced below
                  ),
                  const SizedBox(height: 10),
                  // Scale number down if space is tight; keep single line
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Icon(icon, color: Colors.blue, size: 24),
                  ),
                ),
              ),
            ],
          ),
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
    required this.onSync,
    required this.isSyncing,
    required this.isOffline,
  });

  final Color primary;
  final VoidCallback onScan;
  final VoidCallback onReport;
  final VoidCallback onSync;
  final bool isSyncing;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 720;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Voter ID'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(
          width: wide ? 220 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReport,
            icon: Icon(Icons.report_gmailerrorred, color: primary),
            label: Text('Report Issue', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        SizedBox(
          width: wide ? 240 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncing ? null : onSync,
            icon: Icon(isOffline ? Icons.cloud_off : Icons.cloud_done, color: isSyncing ? Colors.grey : primary),
            label: Text(
              isSyncing
                  ? 'Syncing...'
                  : isOffline
                  ? 'Go Online & Sync'
                  : 'Sync Now',
              style: TextStyle(
                color: isSyncing ? Colors.grey : primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isSyncing ? Colors.grey : primary, width: 1.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      _CountPill(label: 'Total', value: total, primary: primary),
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: voters.length,
                separatorBuilder: (_, __) => Divider(color: dividerColor),
                itemBuilder: (context, index) {
                  final voter = voters[index];
                  return _VoterTile(
                    voter: voter,
                    primary: primary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTapMark: () => onMarkTap(voter),
                  );
                },
              ),
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

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.activity,
    required this.primary,
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
  });

  final List<Activity> activity;
  final Color primary;
  final Color bg;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: primary),
                const SizedBox(width: 8),
                Text('Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    )),
              ],
            ),
            const SizedBox(height: 6),
            Divider(color: dividerColor),
            const SizedBox(height: 6),
            if (activity.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No recent activity', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              ListView.separated(
                itemCount: activity.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => Divider(color: dividerColor),
                itemBuilder: (_, i) {
                  final a = activity[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.circle, color: primary, size: 12),
                    ),
                    title: Text(a.title, style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                    subtitle: Text(a.subtitle, style: TextStyle(color: textSecondary)),
                    trailing: Text(a.fmtTime(), style: TextStyle(color: textSecondary, fontSize: 12)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class Activity {
  Activity(this.title, this.subtitle, this.time);
  final String title;
  final String subtitle;
  final DateTime time;

  String fmtTime() {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
