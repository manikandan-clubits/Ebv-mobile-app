import 'package:ebv/provider/patient_provider.dart';
import 'package:ebv/screens/appointments/calendar.dart';
import 'package:ebv/screens/appointments/view_all_appointments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class Appointments extends ConsumerStatefulWidget {
  const Appointments({super.key});

  @override
  ConsumerState createState() => _AppointmentsState();
}

class _AppointmentsState extends ConsumerState<Appointments> {

  int _selectedTimeFilter = 3;
  String filterStatus = "All";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ref.read(patientProvider.notifier).getAppointments(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
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

          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarScreen()),
                );
              },
              icon: const Icon(Icons.calendar_month, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/dentiverify-logo.png',
              width: 120,
              height: 200,
            ),
          ),
        ],
        title: Text(
          'Appointments',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildWeekCalendar(),
          _buildTimeFilters(),
          _buildAppointmentsHeader(state.filterappointments?.length ?? 0),
          state.isLoading
              ? _buildLoadingIndicator()
              : state.filterappointments!.isEmpty
              ? _buildEmptyState()
              : _buildAppointmentsList(state),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildTimeFilterButton(3, 'All', Icons.all_inclusive),
          const SizedBox(width: 8),
          _buildTimeFilterButton(0, 'Today', Icons.today),
          const SizedBox(width: 8),
          _buildTimeFilterButton(1, 'Tomorrow', Icons.today_outlined),
        ],
      ),
    );
  }

  Widget _buildTimeFilterButton(int index, String text, IconData icon) {
    final isSelected = _selectedTimeFilter == index;
    return Expanded(
      child: Container(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.white : Colors.grey.shade100,
            foregroundColor: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
            elevation: isSelected ? 2 : 0,
            shadowColor: Colors.blue.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onPressed: () {
            ref.read(patientProvider.notifier).filterCall(index);
            setState(() {
              filterStatus = text;
              _selectedTimeFilter = index;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final selectedDate = ref.watch(selectedDateProvider);
    final firstDayOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final weekDates = List.generate(7, (i) => firstDayOfWeek.add(Duration(days: i)));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Month/Year and Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 24, color: Colors.blueGrey.shade700),
                  onPressed: () => _navigateWeek(false),
                  splashRadius: 20,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 24, color: Colors.blueGrey.shade700),
                  onPressed: () => _navigateWeek(true),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dates row with day indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDates.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final isSelected = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;

                return Column(
                  children: [
                    Text(
                      days[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state = date;
                        ref.read(patientProvider.notifier).filterDay(date);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF8548D0)
                              : isToday
                              ? Colors.blue.shade50
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: isToday && !isSelected
                              ? Border.all(color: Colors.blue.shade300, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateWeek(bool forward) {
    final currentDate = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state =
    forward ? currentDate.add(const Duration(days: 7)) : currentDate.subtract(const Duration(days: 7));
  }

  Widget _buildAppointmentsHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$filterStatus Appointments",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewAllAppointments()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'view all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Appointments...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No appointments found for $filterStatus',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String convertDateToTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    return DateFormat('h:mm a').format(date);
  }

  String formatAppointmentDate(String dateTime) {
    final date = DateTime.parse(dateTime);
    return DateFormat('EEE, MMM d • h:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.green;
      case 'noshow':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAppointmentsList(state) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.filterappointments!.length,
        itemBuilder: (context, index) {
          final appointment = state.filterappointments![index];
          final status = appointment['StatusDesc']?.toString() ?? 'Scheduled';
          final time = convertDateToTime(appointment['AppointmentDateTime']);
          final fullDate = formatAppointmentDate(appointment['AppointmentDateTime']);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shadowColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with patient name and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment['PatName']?.toString().toUpperCase() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date and time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          fullDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Doctor info
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          'Dr. ${appointment['DoctorName'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Disease info
                    if (appointment['DiseaseName'] != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.medical_services, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appointment['DiseaseName'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Footer with status and view button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // ref.read(patientProvider.notifier).showPdfViewer(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}