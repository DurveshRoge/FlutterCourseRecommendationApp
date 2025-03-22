import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
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
    final entries = valuecounts.entries.toList()
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
        child: SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: _buildPieChartSections(topSubjects),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
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

  List<PieChartSectionData> _buildPieChartSections(List<MapEntry<String, dynamic>> entries) {
    final colors = [
      const Color(0xFF3AAFA9),
      const Color(0xFF2B7A78),
      const Color(0xFF17252A),
      const Color(0xFF5CDB95),
      const Color(0xFF8EE4AF),
    ];

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: (entry.value as num).toDouble(),
        title: '${entry.key}\n${entry.value}',
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
                maxY: (levelcounts.values.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final levels = levelcounts.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < levels.length) {
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            levels[value.toInt()],
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
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
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
                barGroups: List.generate(
                  levelcounts.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: levelcounts[levelcounts.keys.elementAt(index)]!.toDouble(),
                        color: const Color(0xFF3AAFA9),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildYearlyPerformanceCard(Map<String, dynamic> profit, Map<String, dynamic> subscribers) {
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

      // Sort years in ascending order
      final years = profit.keys.toList()..sort();
      final profitValues = years.map((year) => (profit[year] as num).toDouble()).toList();
      final subscriberValues = years.map((year) => (subscribers[year] as num).toDouble()).toList();

      // Add print for debugging
      print('Years: $years');
      print('Profit values: $profitValues');
      print('Subscriber values: $subscriberValues');

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < years.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              years[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
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
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000000).toStringAsFixed(1)}M',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(1)}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Profit Line
                  LineChartBarData(
                    spots: List.generate(years.length, (i) => FlSpot(i.toDouble(), profitValues[i])),
                    isCurved: true,
            color: const Color(0xFF3AAFA9),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3AAFA9).withOpacity(0.1),
                    ),
                  ),
                  // Subscribers Line
                  LineChartBarData(
                    spots: List.generate(years.length, (i) => FlSpot(i.toDouble(), subscriberValues[i])),
                    isCurved: true,
                    color: const Color(0xFF2B7A78),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2B7A78).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
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
      
      final months = profit.keys.toList()
        ..sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));
      
      final profitValues = months.map((month) => (profit[month] as num).toDouble()).toList();
      final subscriberValues = months.map((month) => (subscribers[month] as num).toDouble()).toList();

      // Add print for debugging
      print('Months: $months');
      print('Monthly profit values: $profitValues');
      print('Monthly subscriber values: $subscriberValues');
    
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
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < months.length) {
            return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  months[value.toInt()].substring(0, 3),
                    style: const TextStyle(
                                    fontSize: 10,
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
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${(value / 1000000).toStringAsFixed(1)}M',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(1)}K',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      // Profit Line
                      LineChartBarData(
                        spots: List.generate(months.length, (i) => FlSpot(i.toDouble(), profitValues[i])),
                        isCurved: true,
                        color: const Color(0xFF3AAFA9),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3AAFA9).withOpacity(0.1),
                        ),
                      ),
                      // Subscribers Line
                      LineChartBarData(
                        spots: List.generate(months.length, (i) => FlSpot(i.toDouble(), subscriberValues[i])),
                        isCurved: true,
                        color: const Color(0xFF2B7A78),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF2B7A78).withOpacity(0.1),
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