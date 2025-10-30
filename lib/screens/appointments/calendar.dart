import 'package:ebv/provider/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _currentView = CalendarView.month;
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    final appointments = _convertToSyncfusionAppointments(state.filterappointments ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () => _changeView(CalendarView.day),
            color: _currentView == CalendarView.day ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () => _changeView(CalendarView.week),
            color: _currentView == CalendarView.week ? Colors.blue : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_month),
            onPressed: () => _changeView(CalendarView.month),
            color: _currentView == CalendarView.month ? Colors.blue : Colors.grey,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildNavigationToolbar(),
          Expanded(
            child: SfCalendar(
              controller: _calendarController,
              view: _currentView,
              dataSource: _AppointmentDataSource(appointments),
              onViewChanged: (ViewChangedDetails details) {
                // Handle view changes
              },
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.calendarCell) {
                  _handleDateTap(details.date!, appointments);
                } else if (details.targetElement == CalendarElement.appointment) {
                  _handleAppointmentTap(details.appointments!.first);
                }
              },
              monthViewSettings: const MonthViewSettings(
                agendaViewHeight: 50,
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                agendaStyle: AgendaStyle(
                  dateTextStyle: TextStyle(fontWeight: FontWeight.bold),
                  appointmentTextStyle: TextStyle(fontSize: 12),
                ),
              ),
              allowDragAndDrop: true,
              backgroundColor: Colors.white,
              allowAppointmentResize: true,
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeFormat: 'h:mm a',
                timeInterval: Duration(minutes: 30),
                timeRulerSize: 70,
                timeTextStyle: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              headerStyle: CalendarHeaderStyle(
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: Colors.blue[50],
              ),
              allowedViews: const [
                CalendarView.day,
                CalendarView.week,
                CalendarView.month,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Convert your API data to Syncfusion appointments
  List<Appointment> _convertToSyncfusionAppointments(List<dynamic> appointmentList) {
    return appointmentList.map((appointment) {
      final DateTime startTime = DateTime.parse(appointment['AppointmentDateTime']);
      final DateTime endTime = startTime.add(const Duration(minutes: 30));
      return Appointment(
        startTime: startTime,
        endTime: endTime,
        subject: appointment['PatName'].toString() ?? 'Appointment',
        color: _getColorFromStatus(appointment['StatusDesc'].toString()),
        notes: appointment['Description'].toString() ?? '',
        id: appointment['AppointmentID']?.toString(),
        // You can add more fields from your API here
        // For example: patientId, doctorName, etc.
      );
    }).toList();
  }

  Color _getColorFromStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.green;
      case 'noshow':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  Widget _buildNavigationToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToPrevious,
          ),
          TextButton(
            onPressed: _goToToday,
            child: const Text('TODAY'),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _navigateToNext,
          ),
        ],
      ),
    );
  }

  void _changeView(CalendarView newView) {
    setState(() {
      _currentView = newView;
      _calendarController.view = newView;
    });
  }

  void _navigateToPrevious() {
    _calendarController.backward!();
  }

  void _navigateToNext() {
    _calendarController.forward!();
  }

  void _goToToday() {
    _calendarController.displayDate = DateTime.now();
  }

  void _handleDateTap(DateTime date, List<Appointment> allAppointments) {
    // Filter appointments for the selected date
    final selectedDateAppointments = allAppointments.where((appointment) {
      return _isSameDay(appointment.startTime, date);
    }).toList();

    // Show bottom sheet with appointments for the selected date
    _showDateAppointmentsBottomSheet(date, selectedDateAppointments);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _showDateAppointmentsBottomSheet(DateTime date, List<Appointment> appointments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.blue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Appointments count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Appointments list
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return _buildAppointmentCard(appointment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Appointments',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No appointments scheduled for this date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: appointment.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          appointment.subject,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${DateFormat('h:mm a').format(appointment.startTime)} - ${DateFormat('h:mm a').format(appointment.endTime)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  appointment.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: Colors.blue),
          onPressed: () {
            Navigator.pop(context); // Close bottom sheet
            _handleAppointmentTap(appointment); // Show detailed dialog
          },
        ),
        onTap: () {
          Navigator.pop(context); // Close bottom sheet
          _handleAppointmentTap(appointment); // Show detailed dialog
        },
      ),
    );
  }

  void _handleAppointmentTap(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appointment.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(Icons.access_time,
                '${DateFormat('MMM dd, yyyy').format(appointment.startTime)}'),
            _buildDetailRow(Icons.schedule,
                '${DateFormat('h:mm a').format(appointment.startTime)} - ${DateFormat('h:mm a').format(appointment.endTime)}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow(Icons.notes, appointment.notes!),
            _buildDetailRow(Icons.circle, 'Status',
                color: appointment.color, status: _getStatusFromColor(appointment.color)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color, String? status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: status != null
                ? Row(
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
                Text(status),
              ],
            )
                : Text(text),
          ),
        ],
      ),
    );
  }

  String _getStatusFromColor(Color color) {
    if (color == Colors.green) return 'Scheduled';
    if (color == Colors.orange) return 'No Show';
    if (color == Colors.red) return 'Cancelled';
    if (color == Colors.blue) return 'Rescheduled';
    return 'Scheduled';
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}