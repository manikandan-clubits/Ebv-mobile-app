import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../provider/home_provider.dart';
import '../../provider/patient_provider.dart';

class ViewAppointments extends ConsumerStatefulWidget {
  const ViewAppointments({super.key});

  @override
  ConsumerState<ViewAppointments> createState() => _ViewAppointmentsState();
}

class _ViewAppointmentsState extends ConsumerState<ViewAppointments> {

  bool showMorningOnly = true;
  String selectedFilter = 'All';

  // List<Appointment> get filteredAppointments {
  //   List<Appointment> filtered = showMorningOnly
  //       ? allAppointments.where((appt) => appt.isMorning).toList()
  //       : List.from(allAppointments);
  //
  //   if (selectedFilter != 'All') {
  //     filtered = filtered.where((appt) => appt.type == selectedFilter).toList();
  //   }
  //   return filtered;
  // }
  //
  // int get plannedCount => allAppointments.where((a) => a.type == 'Planned').length;
  // int get walkInCount => allAppointments.where((a) => a.type == 'WalkIn').length;

  String convertDateToTime() {
    final date = DateTime.now();
    return DateFormat("MMM d, yyyy").format(date);
  }

  @override
  void initState() {
    // TODO: implement initState
    Future.microtask(() {
      ref.read(homeProvider.notifier).getFilterAppointments();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Appointments"),
        backgroundColor:  Color(0xFF8548D0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats section
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(0.05),
          //         blurRadius: 6,
          //         offset: const Offset(0, 3),
          //       )
          //     ],
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround,
          //     children: [
          //       _buildStatItem("Planned", plannedCount, Colors.green),
          //       _buildStatItem("Walk-In", walkInCount, Colors.purple),
          //       _buildStatItem("Total", allAppointments.length, Colors.blue),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 16),

          // Date
          Text(
            convertDateToTime(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),


          // List
          Expanded(
            child: state.todaysappointmentList==[]
                ? const Center(
              child: Text(
                "No appointments found",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.todaysappointmentList?.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(state.todaysappointmentList?[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time + Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text(
                //   DateFormat("hh:mm a").format(appointment.time),
                //   style: const TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.deepPurple,
                //   ),
                // ),
                Row(
                  children: [
                    // _buildTag(appointment['StatusDesc'], _getTypeColor(appointment['StatusDesc'])),
                    // const SizedBox(width: 8),
                    // _buildTag(appointment.status, _getStatusColor(appointment.status)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info
            _buildInfoRow(Icons.person, appointment['PatName']),
            _buildInfoRow(Icons.medical_services, appointment['DoctorName']),
            // _buildInfoRow(Icons.business, appointment['DiseaseName']),

            const SizedBox(height: 12),
            Text(
              DateFormat("EEE, MMM d, yyyy").format(DateTime.parse(appointment['AppointmentDateTime'])),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'planned':
        return Colors.green;
      case 'walkin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class Appointment {
  final String id;
  final String patientName;
  final String doctorName;
  final String department;
  final DateTime time;
  final String status;
  final bool isMorning;
  final String type;

  Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.department,
    required this.time,
    required this.status,
    required this.isMorning,
    required this.type,
  });
}
