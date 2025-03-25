import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max, min;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  static DateTime _lastDashboardLoad = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    
    // Add throttling to prevent too many API calls in quick succession
    final now = DateTime.now();
    if (now.difference(_lastDashboardLoad).inSeconds < 2) {
      print("Throttling dashboard load - too frequent");
      return;
    }
    _lastDashboardLoad = now;
    
    setState(() => _isLoading = true);
    context.read<CourseBloc>().add(LoadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation even during loading
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: const Color(0xFF17252A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _loadDashboard,
              tooltip: 'Refresh dashboard',
            ),
          ],
        ),
        body: BlocConsumer<CourseBloc, CourseState>(
          listener: (context, state) {
            if (state is CourseLoading) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);
            }
          },
          builder: (context, state) {
            if (state is CourseLoading && !_isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3AAFA9),
                ),
              );
            }
            
            if (state is DashboardLoaded) {
              final dashboardData = state.dashboardData;
              
              if (dashboardData.isEmpty) {
                return _buildEmptyState();
              }
              
              return RefreshIndicator(
                onRefresh: _loadDashboard,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildDashboardContent(dashboardData),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            if (state is CourseError) {
              return _buildErrorState(state.message);
            }
            
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3AAFA9),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No dashboard data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _loadDashboard,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[300],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _loadDashboard,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic> dashboardData) {
    try {
      final subjectDistribution = dashboardData['subject_distribution'] as Map<String, dynamic>? ?? {};
      final levelDistribution = dashboardData['level_distribution'] as Map<String, dynamic>? ?? {};
      final yearlyMetrics = dashboardData['yearly_metrics'] as Map<String, dynamic>? ?? {};
      final monthlyMetrics = dashboardData['monthly_metrics'] as Map<String, dynamic>? ?? {};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subjectDistribution.isNotEmpty) ...[
            _buildSectionTitle('Course Distribution by Subject'),
            _buildSubjectDistributionCard(subjectDistribution),
            const SizedBox(height: 24),
          ],
          if (levelDistribution.isNotEmpty) ...[
            _buildSectionTitle('Course Distribution by Level'),
            _buildLevelDistributionCard(levelDistribution),
            const SizedBox(height: 24),
          ],
          if (yearlyMetrics.isNotEmpty) ...[
            _buildSectionTitle('Yearly Performance'),
            _buildYearlyPerformanceCard(
              yearlyMetrics['profit'] as Map<String, dynamic>? ?? {},
              yearlyMetrics['subscribers'] as Map<String, dynamic>? ?? {},
            ),
            const SizedBox(height: 24),
          ],
          if (monthlyMetrics.isNotEmpty) ...[
            _buildSectionTitle('Monthly Performance'),
            _buildMonthlyPerformanceCard(
              monthlyMetrics['profit'] as Map<String, dynamic>? ?? {},
              monthlyMetrics['subscribers'] as Map<String, dynamic>? ?? {},
            ),
          ],
        ],
      );
    } catch (e) {
      print('Error building dashboard content: $e');
      return Center(
        child: Text(
          'Error displaying dashboard data',
          style: TextStyle(color: Colors.red[300]),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubjectDistributionCard(Map<String, dynamic> valuecounts) {
    try {
      // Protection against empty data
      if (valuecounts.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No subject data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      // Convert to list of entries and sort by value
      final entries = valuecounts.entries
          .where((entry) => 
            entry.key != null && 
            entry.key.toString().isNotEmpty &&
            entry.value != null && 
            entry.value is num)
          .toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));
      
      // Take top 5 subjects
      final topSubjects = entries.take(5).toList();
        
      print('Top subjects: $topSubjects');
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(topSubjects),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _buildLegendItems(topSubjects),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building subject distribution chart: $e');
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error building chart: $e',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  List<Widget> _buildLegendItems(List<MapEntry<String, dynamic>> entries) {
    final colors = [
      const Color(0xFF3AAFA9),
      const Color(0xFF2B7A78),
      const Color(0xFF17252A),
      const Color(0xFF5CDB95),
      const Color(0xFF8EE4AF),
    ];
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.key}: ${entry.value}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _buildPieChartSections(List<MapEntry<String, dynamic>> entries) {
    final colors = [
      const Color(0xFF3AAFA9),
      const Color(0xFF2B7A78),
      const Color(0xFF17252A),
      const Color(0xFF5CDB95),
      const Color(0xFF8EE4AF),
    ];

    if (entries.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Data',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
      ];
    }

    // Calculate total for percentage
    final total = entries.fold<double>(
      0, (sum, entry) => sum + (entry.value as num).toDouble());

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final value = (entry.value as num).toDouble();
      final percentage = (value / total * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '$percentage%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLevelDistributionCard(Map<String, dynamic> levelcounts) {
    try {
      // Protection against empty data
      if (levelcounts.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No level data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }

      print('Level counts: $levelcounts');
      
      // Convert to list of entries for display
      final entries = levelcounts.entries.toList();
      
      // Remove any entries that might be invalid
      final validEntries = entries.where((entry) => 
        entry.key != null && 
        entry.key.toString().isNotEmpty &&
        entry.value != null && 
        entry.value is num
      ).toList();
      
      // Sort by value in descending order
      validEntries.sort((a, b) => (b.value as num).compareTo(a.value as num));
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: List.generate(validEntries.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (validEntries[index].value as num).toDouble(),
                        color: const Color(0xFF3AAFA9),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < validEntries.length) {
                          String title = validEntries[value.toInt()].key.toString();
                          // Shorten long titles
                          if (title.length > 10) {
                            title = title.substring(0, 8) + '...';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: validEntries.isEmpty ? 1 : 
                      (validEntries.map((e) => (e.value as num).toDouble()).reduce(max) / 5),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building level distribution chart: $e');
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error building chart: $e',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildYearlyPerformanceCard(
    Map<String, dynamic> profitMap,
    Map<String, dynamic> subscribersMap,
  ) {
    try {
      // Protection against empty data
      if (profitMap.isEmpty || subscribersMap.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No yearly data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      // Sort years
      final years = profitMap.keys.toList()..sort();
      
      // Check if we have valid years
      if (years.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No valid years in data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      // Convert profit to millions and subscribers to thousands for better visualization
      final profitData = <FlSpot>[];
      final subscriberData = <FlSpot>[];
      
      // Additional error protection for data conversion
      double maxProfit = 0;
      double maxSubscribers = 0;
      
      // Safely create spots with additional error handling
      for (int i = 0; i < years.length; i++) {
        final year = years[i];
        
        try {
          if (profitMap.containsKey(year)) {
            final profitValue = (profitMap[year] is num) 
                ? (profitMap[year] as num).toDouble() / 1000000 // to millions
                : 0.0;
            
            if (profitValue.isFinite && !profitValue.isNaN) {
              profitData.add(FlSpot(i.toDouble(), profitValue));
              maxProfit = max(maxProfit, profitValue);
            }
          }
          
          if (subscribersMap.containsKey(year)) {
            final subscriberValue = (subscribersMap[year] is num) 
                ? (subscribersMap[year] as num).toDouble() / 1000 // to thousands
                : 0.0;
            
            if (subscriberValue.isFinite && !subscriberValue.isNaN) {
              subscriberData.add(FlSpot(i.toDouble(), subscriberValue));
              maxSubscribers = max(maxSubscribers, subscriberValue);
            }
          }
        } catch (e) {
          print('Error processing data for year $year: $e');
          // Skip this data point rather than crashing
          continue;
        }
      }
      
      // Safety check - if no valid data points, show fallback UI
      if (profitData.isEmpty && subscriberData.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Could not process performance data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchSpotThreshold: 20,
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 1,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < years.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  years[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Millions/Thousands',
                          style: TextStyle(fontSize: 10),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    minX: 0,
                    maxX: (years.length - 1).toDouble(),
                    minY: 0,
                    maxY: max(maxProfit, maxSubscribers) * 1.2, // Add 20% padding
                    lineBarsData: [
                      if (profitData.isNotEmpty) LineChartBarData(
                        spots: profitData,
                        isCurved: true,
                        color: const Color(0xFF3AAFA9),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3AAFA9).withOpacity(0.2),
                        ),
                      ),
                      if (subscriberData.isNotEmpty) LineChartBarData(
                        spots: subscriberData,
                        isCurved: true,
                        color: const Color(0xFF2B7A78),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF2B7A78).withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3AAFA9),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Profit (millions)', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B7A78),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Subscribers (thousands)', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building yearly performance chart: $e');
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error building yearly chart: $e',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMonthlyPerformanceCard(Map<String, dynamic> profit, Map<String, dynamic> subscribers) {
    try {
      // Protection against empty data
      if (profit.isEmpty || subscribers.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No monthly data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
    
      // Sort months in chronological order
      final monthOrder = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      // Get available months and filter/validate
      final months = profit.keys.toList()
        ..retainWhere((m) => monthOrder.contains(m))
        ..sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));
      
      // Check if we have valid months
      if (months.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No valid months in data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      // Convert profit to millions and subscribers to thousands for better visualization
      final profitData = <FlSpot>[];
      final subscriberData = <FlSpot>[];
      
      // Additional error protection for data conversion
      double maxProfit = 0;
      double maxSubscribers = 0;
      
      // Safely create spots with additional error handling
      for (int i = 0; i < months.length; i++) {
        final month = months[i];
        
        try {
          if (profit.containsKey(month)) {
            final profitValue = (profit[month] is num) 
                ? (profit[month] as num).toDouble() / 1000000 // to millions
                : 0.0;
            
            if (profitValue.isFinite && !profitValue.isNaN) {
              profitData.add(FlSpot(i.toDouble(), profitValue));
              maxProfit = max(maxProfit, profitValue);
            }
          }
          
          if (subscribers.containsKey(month)) {
            final subscriberValue = (subscribers[month] is num) 
                ? (subscribers[month] as num).toDouble() / 1000 // to thousands
                : 0.0;
            
            if (subscriberValue.isFinite && !subscriberValue.isNaN) {
              subscriberData.add(FlSpot(i.toDouble(), subscriberValue));
              maxSubscribers = max(maxSubscribers, subscriberValue);
            }
          }
        } catch (e) {
          print('Error processing data for month $month: $e');
          // Skip this data point rather than crashing
          continue;
        }
      }
      
      // Safety check - if no valid data points, show fallback UI
      if (profitData.isEmpty && subscriberData.isEmpty) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Could not process monthly performance data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }
      
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchSpotThreshold: 20,
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 1,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < months.length) {
                              // Abbreviated month names to save space
                              final shortName = months[index].substring(0, min(3, months[index].length));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  shortName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Millions/Thousands',
                          style: TextStyle(fontSize: 10),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    minX: 0,
                    maxX: (months.length - 1).toDouble(),
                    minY: 0,
                    maxY: max(maxProfit, maxSubscribers) * 1.2, // Add 20% padding
                    lineBarsData: [
                      if (profitData.isNotEmpty) LineChartBarData(
                        spots: profitData,
                        isCurved: true,
                        color: const Color(0xFF3AAFA9),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3AAFA9).withOpacity(0.2),
                        ),
                      ),
                      if (subscriberData.isNotEmpty) LineChartBarData(
                        spots: subscriberData,
                        isCurved: true,
                        color: const Color(0xFF2B7A78),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF2B7A78).withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Profit', const Color(0xFF3AAFA9)),
                  const SizedBox(width: 24),
                  _buildLegendItem('Subscribers', const Color(0xFF2B7A78)),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building monthly performance chart: $e');
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error building chart: $e',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 