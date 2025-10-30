import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../provider/dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate = DateTime.now();
    Future.microtask(() async {
      ref.read(dashboardProvider.notifier).userList();
      ref.read(dashboardProvider.notifier).refreshDashboard();
    });
  }

  String _selectedUser = 'All Users';
  List<String> _selectedTypes = ['All'];

  final List<String> _userTypes = ['All', 'Manual', 'Automation'];

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF29BFFF),
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      ref.read(dashboardProvider.notifier).refreshDashboard(frDate: picked.toString());
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8548D0),
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      ref.read(dashboardProvider.notifier).refreshDashboard(enDate: _endDate.toString());
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedUser = 'All Users';
      _selectedTypes = ['All'];
    });
    ref.read(dashboardProvider.notifier).refreshDashboard();
  }

  void _showUserModal(BuildContext context, userList) {
    TextEditingController searchController = TextEditingController();
    List<dynamic> filteredList = List.from(userList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 24),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Search user...",
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {
                            filteredList = userList
                                .where((user) => user['UserName']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User List
                    Expanded(
                      child: filteredList.isEmpty
                          ? _buildEmptyUserState()
                          : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final user = filteredList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                user['UserName']?.toString() ?? 'Unknown User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedUser = user['UserName']!.toString();
                                });
                                ref.read(dashboardProvider.notifier).refreshDashboard(
                                    userId: user['UserGuid'],
                                    accId: user['AccountId']);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyUserState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTypeSelection(String type) {
    setState(() {
      if (type == 'All') {
        _selectedTypes = ['All'];
      } else {
        if (_selectedTypes.contains(type)) {
          _selectedTypes.remove(type);
          if (_selectedTypes.isEmpty) {
            _selectedTypes = ['All'];
          }
        } else {
          _selectedTypes.remove('All');
          _selectedTypes.add(type);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF29BFFF),
                Color(0xFF8548D0),
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/dentiverify-logo.png',
              width: 120,
              height: 200,
            ),
          ),
        ],
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date Range Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Start Date',
                          _startDate,
                          _selectStartDate,
                          Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          'End Date',
                          _endDate,
                          _selectEndDate,
                          Colors.purple.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Selection
                  _buildUserSelector(state.userList),
                  const SizedBox(height: 16),

                  // Type Filters
                  _buildTypeFilters(),
                  const SizedBox(height: 16),

                  // Reset Button
                  _buildResetButton(),
                ],
              ),
            ),

            // Dashboard Content
            state.isLoading
                ? _buildLoadingState()
                : state.dashboardList!.isEmpty
                ? _buildEmptyState()
                : _buildDashboardContent(state.dashboardList, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, Function onTap, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => onTap(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserSelector(userList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select User',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showUserModal(context, userList),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedUser,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 24,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Types',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _userTypes.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (bool selected) {
                _toggleTypeSelection(type);
                ref.read(dashboardProvider.notifier).refreshDashboard(type: type);
              },
              selectedColor: const Color(0xFF29BFFF).withOpacity(0.2),
              checkmarkColor: const Color(0xFF29BFFF),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF29BFFF) : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF29BFFF) : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resetFilters,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(
          'Reset Filters',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF29BFFF)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or date range',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(dashboardList, double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Cards
          _buildStatusSection(dashboardList, isSmallScreen),
          const SizedBox(height: 24),

          // Charts Section
          _buildChartsSection(dashboardList),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusSection(dashboardList, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 1200 ? 4 :
            screenWidth > 800 ? 3 :
            screenWidth > 500 ? 2 : 2;
            final childAspectRatio = screenWidth > 1200 ? 1.2 :
            screenWidth > 800 ? 1.4 :
            screenWidth > 500 ? 1.6 : 1.8;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: screenWidth > 500 ? 12 : 8,
              mainAxisSpacing: screenWidth > 500 ? 12 : 8,
              childAspectRatio: childAspectRatio,
              children: _buildStatusCards(dashboardList, screenWidth),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartsSection(dashboardList) {
    return Column(
      children: [
        // Line Chart
        _buildGroupedBarChartCard(),
        const SizedBox(height: 24),

        // Pie Chart
        SizedBox(
          height: 350,
          child: ActiveInactiveChart(
            activeCount: 7,
            inactiveCount: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedBarChartCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Patient Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payers vs Total Patients Comparison',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(text: 'Number of Patients'),
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries>[
                    ColumnSeries<ChartData, String>(
                      name: 'Payers',
                      dataSource: _getChartData(),
                      xValueMapper: (ChartData data, _) => data.category,
                      yValueMapper: (ChartData data, _) => data.value,
                      color: const Color(0xFF29BFFF),
                      width: 0.8,
                      spacing: 0.1,
                      borderRadius: BorderRadius.circular(4),
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.top,
                        textStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ColumnSeries<ChartData, String>(
                      name: 'Total Patients',
                      dataSource: _getChartData(),
                      xValueMapper: (ChartData data, _) => data.category,
                      yValueMapper: (ChartData data, _) => data.value + 25,
                      color: const Color(0xFF8548D0),
                      width: 0.8,
                      spacing: 0.1,
                      borderRadius: BorderRadius.circular(4),
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.top,
                        textStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStatusCards(dashboardList, double screenWidth) {
    return [
      _buildStatCard(
        value: dashboardList[0]?['totalPatients']?.toString() ?? '0',
        label: 'Total Patients',
        icon: Icons.people_alt_rounded,
        color: Colors.blue,
        screenWidth: screenWidth,
      ),
      _buildStatCard(
        value: dashboardList[0]?['payerCount']?.toString() ?? '0',
        label: 'Payers',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.green,
        screenWidth: screenWidth,
      ),
      _buildStatCard(
        value: dashboardList[0]?['verified']?.toString() ?? '0',
        label: 'Verified',
        icon: Icons.verified_rounded,
        color: Colors.orange,
        screenWidth: screenWidth,
      ),
      _buildStatCard(
        value: dashboardList[0]?['notVerified']?.toString() ?? '0',
        label: 'Not Verified',
        icon: Icons.warning_amber_rounded,
        color: Colors.purple,
        screenWidth: screenWidth,
      ),
      _buildStatCard(
        value: dashboardList[0]?['active']?.toString() ?? '0',
        label: 'Active',
        icon: Icons.ac_unit,
        color: Colors.teal,
        screenWidth: screenWidth,
      ),
      _buildStatCard(
        value: dashboardList[0]?['pendingCount']?.toString() ?? '0',
        label: 'Pending',
        icon: Icons.pending_actions_rounded,
        color: Colors.red,
        screenWidth: screenWidth,
      ),
    ];
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required double screenWidth,
  }) {
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;
    final isLargeScreen = screenWidth >= 1200;

    // Responsive sizing
    final iconSize = isSmallScreen ? 16.0 : isMediumScreen ? 18.0 : 20.0;
    final valueFontSize = isSmallScreen ? 14.0 : isMediumScreen ? 16.0 : 18.0;
    final labelFontSize = isSmallScreen ? 10.0 : isMediumScreen ? 11.0 : 12.0;
    final padding = isSmallScreen ? 8.0 : isMediumScreen ? 12.0 : 16.0;
    final iconPadding = isSmallScreen ? 4.0 : isMediumScreen ? 6.0 : 8.0;
    final borderRadius = isSmallScreen ? 8.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(borderRadius - 2),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<ChartData> _getChartData() {
    return [
      ChartData('Jan', 120, Colors.blue),
      ChartData('Feb', 135, Colors.blue),
      ChartData('Mar', 145, Colors.blue),
      ChartData('Apr', 160, Colors.blue),
      ChartData('May', 175, Colors.blue),
      ChartData('Jun', 190, Colors.blue),
    ];
  }
}

class ChartData {
  final String category;
  final int value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}

class ActiveInactiveChart extends StatelessWidget {
  final int activeCount;
  final int inactiveCount;

  const ActiveInactiveChart({
    Key? key,
    required this.activeCount,
    required this.inactiveCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = activeCount + inactiveCount;
    final activePercentage = total > 0 ? (activeCount / total * 100).round() : 0;
    final inactivePercentage = total > 0 ? (inactiveCount / total * 100).round() : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Active vs Inactive Payers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Distribution of payer status",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 50,
                    sectionsSpace: 4,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: activeCount.toDouble(),
                        color: const Color(0xFF29BFFF),
                        radius: 35,
                        title: "$activePercentage%",
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: inactiveCount.toDouble(),
                        color: const Color(0xFF8548D0),
                        radius: 35,
                        title: "$inactivePercentage%",
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegend(color: const Color(0xFF29BFFF), text: "Active: $activeCount"),
                  const SizedBox(width: 20),
                  _buildLegend(color: const Color(0xFF8548D0), text: "Inactive: $inactiveCount"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}