import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentReportPage extends StatefulWidget {
  const AgentReportPage({super.key});

  @override
  State<AgentReportPage> createState() => _AgentReportPageState();
}

class _AgentReportPageState extends State<AgentReportPage> {
  List<Report> reports = [];

  // Dummy agent data (replace with actual data from login/profile)
  String agentName = 'John Doe';
  String agentVoterId = 'V123456';
  String agentPhone = '+91 9876543210';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    // TODO: Replace with API call to fetch reports submitted by this agent
    setState(() {
      reports = [
        Report(
          type: 'Agent Issue',
          voterName: agentName,
          voterId: agentVoterId,
          phone: agentPhone,
          description: 'Booth delayed opening',
          time: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    });
  }

  Future<void> _addReport() async {
    final descCtrl = TextEditingController();
    String reportType = 'Agent Issue';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: reportType,
                  items: const [
                    DropdownMenuItem(value: 'Voter Issue', child: Text('Voter Issue')),
                    DropdownMenuItem(value: 'Agent Issue', child: Text('Agent Issue')),
                  ],
                  onChanged: (val) => setState(() => reportType = val!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(hintText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, descCtrl.text.trim());
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        reports.add(Report(
          type: reportType,
          voterName: agentName,
          voterId: agentVoterId,
          phone: agentPhone,
          description: result,
          time: DateTime.now(),
        ));
      });

      // TODO: Send report to admin via API

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? const Center(child: Text('No reports submitted yet'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = reports[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.voterName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Voter ID: ${r.voterId}'),
                  const SizedBox(height: 2),
                  Text('Phone: ${r.phone}'),
                  const SizedBox(height: 6),
                  Text(r.description),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(r.time),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReport,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.day}/${t.month}/${t.year} $h:$m';
  }
}

class Report {
  Report({
    required this.type,
    required this.voterName,
    required this.voterId,
    required this.phone,
    required this.description,
    required this.time,
  });

  final String type; // 'Voter Issue' or 'Agent Issue'
  final String voterName;
  final String voterId;
  final String phone;
  final String description;
  final DateTime time;
}
