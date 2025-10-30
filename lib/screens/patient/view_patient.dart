import 'dart:io';
import 'package:ebv/screens/voip/voip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../provider/patient_provider.dart';
import 'package:http/http.dart' as http;

class ViewPatient extends ConsumerStatefulWidget {
  final data;
  const ViewPatient({super.key, this.data});

  @override
  ConsumerState<ViewPatient> createState() => _ViewPatientState();
}

class _ViewPatientState extends ConsumerState<ViewPatient> {
  String? selectedCountry;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(patientProvider.notifier)
          .getPatientById(widget.data?['patientId'], context);
    });
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final state = ref.watch(patientProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor?.withOpacity(0.1) ?? Colors.blue.shade50.withOpacity(0.3),
                backgroundColor?.withOpacity(0.05) ?? Colors.blue.shade100.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: backgroundColor?.withOpacity(0.3) ?? Colors.blue.shade100!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor ?? Color(0xFF29BFFF),
                      iconColor ?? Color(0xFF8548D0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (iconColor ?? Colors.blue).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isImportant = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isImportant ? FontWeight.w600 : FontWeight.w400,
                color: isImportant ? Colors.black87 : Colors.grey.shade800,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        title: Text(
          'Patient Benefit Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: !state.isDownloadLoading
                ? IconButton(
              icon: Icon(Icons.download_rounded, color: Colors.blue.shade700),
              onPressed: _showReportOptions,
              tooltip: 'Download Reports',
            )
                : Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Patient ID Badge
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF29BFFF).withOpacity(0.1),
                    Color(0xFF8548D0).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient ID',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.data?['patientId']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // VOIP Selection
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOIP Communication',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCountry,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      labelText: 'Select VOIP Option',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'US',
                        child: Text('US-IVR', style: TextStyle(fontSize: 14)),
                      ),
                      DropdownMenuItem(
                        value: 'IN',
                        child: Text('India-IVR', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCountry = newValue;
                      });
                      if (newValue != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VOIPView(
                              patientId: widget.data?['patientId'],
                              selectedCountry: selectedCountry,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Patient Information Section
            _buildInfoSection(
              title: 'PATIENT INFORMATION',
              color: Colors.blue,
              child: _buildPatientInfo(),
            ),

            // Subscriber Information Section
            _buildInfoSection(
              title: 'SUBSCRIBER INFORMATION',
              color: Colors.green,
              child: _buildSubscriberInfo(),
            ),

            // Insurance Information Section
            _buildInfoSection(
              title: 'INSURANCE INFORMATION',
              color: Colors.purple,
              child: _buildInsuranceInfo(),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    final state = ref.watch(patientProvider);
    final patientInfo = state.patientReportData?['PatientDetails'];

    if (patientInfo == null) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        _buildInfoRow("Patient Name:", patientInfo['FirstName'] ?? "N/A", isImportant: true),
        _buildInfoRow("Date Of Birth:", patientInfo['DateOfBirth'] ?? "N/A"),
        _buildInfoRow("Phone No.", "N/A"),
        _buildInfoRow("Plan Status:", "N/A"),
      ],
    );
  }

  Widget _buildSubscriberInfo() {
    final state = ref.watch(patientProvider);
    final patientInfo = state.patientReportData?['PatientDetails'];

    if (patientInfo == null) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        _buildInfoRow("Subscriber Name:", patientInfo['SubscriberName'] ?? "N/A", isImportant: true),
        _buildInfoRow("Date Of Birth:", patientInfo['SubscriberDateOfBirth'] ?? "N/A"),
        _buildInfoRow("Plan/Group:", "N/A"),
        _buildInfoRow("Employer Name:", "N/A"),
      ],
    );
  }

  Widget _buildInsuranceInfo() {
    final state = ref.watch(patientProvider);
    final patientInfo = state.patientReportData?['InsuranceDetails'];

    if (patientInfo == null) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        _buildInfoRow("Insurance Name:", patientInfo['InsurancePayer'] ?? "N/A", isImportant: true),
        _buildInfoRow("Payer ID:", patientInfo['PayerIdCode'] ?? "N/A"),
        _buildInfoRow("Insurance Eff Date:", "N/A"),
        _buildInfoRow("Plan Year:", "N/A"),
        _buildInfoRow("Individual Ded Met:", "N/A"),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading information...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 500,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            Expanded(
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  _buildReportOption(
                    icon: Icons.description_outlined,
                    title: 'Basic Report',
                    subtitle: 'Quick overview of essential patient information',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(patientProvider.notifier).getBasicPdf(context,'M4102','Basic Report');
                    },
                    iconColor: Colors.blue,
                    backgroundColor: Colors.blue,
                  ),

                  SizedBox(height: 16),

                  _buildReportOption(
                    icon: Icons.assignment_outlined,
                    title: 'Practice Reference Report',
                    subtitle: 'Detailed reference materials and practice guidelines',
                    onTap: () {
                      ref.read(patientProvider.notifier).getBasicPdf(context,'M4102','Basic Report');

                      // Handle Practice Reference Report
                    },
                    iconColor: Colors.green,
                    backgroundColor: Colors.green,
                  ),

                  SizedBox(height: 16),

                  _buildReportOption(
                    icon: Icons.analytics_outlined,
                    title: 'Detailed Report',
                    subtitle: 'Comprehensive analysis with detailed insights',
                    onTap: () {
                      ref.read(patientProvider.notifier).getBasicPdf(context,'M4102','Basic Report');
                      Navigator.pop(context);
                      // Handle Detailed Report
                    },
                    iconColor: Colors.purple,
                    backgroundColor: Colors.purple,
                  ),

                  SizedBox(height: 16),

                  _buildReportOption(
                    icon: Icons.medical_services_outlined,
                    title: 'Medical History Report',
                    subtitle: 'Complete medical history and treatment records',
                    onTap: () {
                      Navigator.pop(context);
                      // Handle Medical History Report
                    },
                    iconColor: Colors.orange,
                    backgroundColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}