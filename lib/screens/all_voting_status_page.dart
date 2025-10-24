import 'package:flutter/material.dart';

class AllVotingStatusPage extends StatefulWidget {
  final String? statusType;

  const AllVotingStatusPage({super.key, this.statusType});

  @override
  State<AllVotingStatusPage> createState() => _AllVotingStatusPageState();
}

class _AllVotingStatusPageState extends State<AllVotingStatusPage> {
  late Map<String, Map<String, int>> _totalsCache;
  String _searchQuery = '';

  final List<Map<String, dynamic>> votingData = [
    {
      'state': 'Maharashtra',
      'districts': [
        {
          'district': 'Mumbai',
          'cities': [
            {
              'city': 'Mumbai City',
              'areas': [
                {'area': 'Colaba', 'casted': 700, 'pending': 300},
                {'area': 'Andheri', 'casted': 1200, 'pending': 800},
              ],
            },
            {
              'city': 'Thane',
              'areas': [
                {'area': 'Ghodbunder', 'casted': 500, 'pending': 200},
              ],
            },
          ],
        },
      ],
    },
    {
      'state': 'Karnataka',
      'districts': [
        {
          'district': 'Bangalore',
          'cities': [
            {
              'city': 'Bangalore Urban',
              'areas': [
                {'area': 'Whitefield', 'casted': 900, 'pending': 100},
                {'area': 'Electronic City', 'casted': 800, 'pending': 200},
              ],
            },
          ],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _totalsCache = {};
  }

  Future<void> _refreshPage() async {
    setState(() {
      _totalsCache.clear();
      _searchQuery = '';
      // Simulate data reload here if fetching from API
    });
  }

  List<Map<String, dynamic>> _filterData(String query) {
    if (query.isEmpty) return votingData;

    final lowerQuery = query.toLowerCase();
    List<Map<String, dynamic>> filtered = [];

    for (var state in votingData) {
      bool stateMatch = (state['state'] as String).toLowerCase().contains(lowerQuery);

      List<Map<String, dynamic>> filteredDistricts = [];
      for (var district in (state['districts'] as List)) {
        bool districtMatch = (district['district'] as String).toLowerCase().contains(lowerQuery);

        List<Map<String, dynamic>> filteredCities = [];
        for (var city in (district['cities'] as List)) {
          bool cityMatch = (city['city'] as String).toLowerCase().contains(lowerQuery);

          List<Map<String, dynamic>> filteredAreas = [];
          for (var area in (city['areas'] as List)) {
            bool areaMatch = (area['area'] as String).toLowerCase().contains(lowerQuery);
            if (areaMatch) filteredAreas.add(area);
          }

          if (cityMatch || filteredAreas.isNotEmpty) {
            filteredCities.add({
              ...city,
              'areas': filteredAreas.isNotEmpty ? filteredAreas : city['areas'],
            });
          }
        }

        if (districtMatch || filteredCities.isNotEmpty) {
          filteredDistricts.add({
            ...district,
            'cities': filteredCities.isNotEmpty ? filteredCities : district['cities'],
          });
        }
      }

      if (stateMatch || filteredDistricts.isNotEmpty) {
        filtered.add({
          ...state,
          'districts': filteredDistricts.isNotEmpty ? filteredDistricts : state['districts'],
        });
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filterData(_searchQuery);
    final globalTotals = _calculateTotals(filteredData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting Status Overview'),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPage,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Column(
          children: [
            _buildSummaryCards(globalTotals),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search state, district, city or area...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildHierarchyList(filteredData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> totals) {
    final totalVoters = totals['totalVoters'] ?? 0;
    final casted = totals['casted'] ?? 0;
    final pending = totals['pending'] ?? 0;
    final castedPercent = totalVoters > 0 ? (casted / totalVoters * 100).toStringAsFixed(1) : '0';

    return Container(
      color: const Color(0xFF1E88E5),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Voters', totalVoters.toString(), const Color(0xFF42A5F5), Icons.people)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Casted', casted.toString(), const Color(0xFF66BB6A), Icons.check_circle)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Pending', pending.toString(), const Color(0xFFEF5350), Icons.pending_actions)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voting Progress: $castedPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalVoters > 0 ? casted / totalVoters : 0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: const Color(0xFF66BB6A),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No data available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, stateIndex) {
          final state = data[stateIndex];
          return _buildStateExpansionTile(state);
        },
      ),
    );
  }


Widget _buildStateExpansionTile(Map<String, dynamic> state) {
    final stateTotals = _calculateTotals(state['districts'] ?? []);
    final districts = (state['districts'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF1E88E5), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state['state'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                  Text(
                    'Total: ${stateTotals['totalVoters'] ?? 0} | Casted: ${stateTotals['casted'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildProgressBar(stateTotals),
          ),
          ...districts.map((district) {
            return _buildDistrictExpansionTile(district);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDistrictExpansionTile(Map<String, dynamic> district) {
    final districtTotals = _calculateTotals(district['cities'] ?? []);
    final cities = (district['cities'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.domain, color: Color(0xFF42A5F5), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district['district'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      'Casted: ${districtTotals['casted'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildProgressBar(districtTotals),
            ),
            ...cities.map((city) {
              return _buildCityExpansionTile(city);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCityExpansionTile(Map<String, dynamic> city) {
    final cityTotals = _calculateTotals(city['areas'] ?? []);
    final areas = (city['areas'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
      child: Card(
        elevation: 0,
        color: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.apartment, color: Color(0xFF66BB6A), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  city['city'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF212121),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildProgressBar(cityTotals),
            ),
            if (areas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No areas found',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...areas.map((area) {
                final casted = (area['casted'] as int?) ?? 0;
                final pending = (area['pending'] as int?) ?? 0;
                final totalVotes = casted + pending;
                final percentage = totalVotes > 0 ? ((casted / totalVotes) * 100).toStringAsFixed(0) : '0';

                return Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  area['area'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF212121),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF66BB6A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildProgressBar({
                            'casted': casted,
                            'pending': pending,
                            'totalVoters': totalVotes
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildVoteChip('Casted', casted, const Color(0xFF66BB6A)),
                              _buildVoteChip('Pending', pending, const Color(0xFFEF5350)),
                            ],
                          ),
                        ],
                      ),
                    ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Map<String, int> totals) {
    final int totalVoters = totals['totalVoters'] ?? 0;
    final int casted = totals['casted'] ?? 0;
    final int pending = totals['pending'] ?? 0;
    final double castedPercent = totalVoters > 0 ? casted / totalVoters : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: castedPercent,
            backgroundColor: const Color(0xFFEF5350).withOpacity(0.2),
            color: const Color(0xFF66BB6A),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: $totalVoters | Casted: $casted | Pending: $pending',
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
      ],
    );
  }

  Map<String, int> _calculateTotals(List items) {
    int totalCasted = 0;
    int totalPending = 0;

    try {
      for (var item in items) {
        if (item is! Map) continue;

        if (item.containsKey('areas') ||
            item.containsKey('cities') ||
            item.containsKey('districts')) {
          final nestedKey = item.containsKey('areas')
              ? 'areas'
              : item.containsKey('cities')
              ? 'cities'
              : 'districts';
          final nestedList = item[nestedKey];
          if (nestedList is List) {
            final totals = _calculateTotals(nestedList);
            totalCasted += totals['casted'] ?? 0;
            totalPending += totals['pending'] ?? 0;
          }
        } else {
          final casted = item['casted'];
          final pending = item['pending'];
          if (casted is int && pending is int) {
            totalCasted += casted;
            totalPending += pending;
          }
        }
      }
    } catch (e) {
      return {'casted': 0, 'pending': 0, 'totalVoters': 0};
    }

    return {
      'casted': totalCasted,
      'pending': totalPending,
      'totalVoters': totalCasted + totalPending
    };
  }
}
