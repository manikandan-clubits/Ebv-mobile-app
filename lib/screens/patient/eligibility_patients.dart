import 'package:ebv/provider/patient_provider.dart';
import 'package:ebv/screens/patient/view_patient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_table.dart';

class PatientsEligibility extends ConsumerStatefulWidget {
  const PatientsEligibility({super.key});

  @override
  ConsumerState<PatientsEligibility> createState() => _PatientsEligibilityState();
}

class _PatientsEligibilityState extends ConsumerState<PatientsEligibility> {
  TextEditingController textController = TextEditingController();
  bool _isCardView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ref.read(patientProvider.notifier).getPatients(context);
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
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
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        title: const Text(
          'Eligibility Verification',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isCardView ? Icons.table_chart : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isCardView = !_isCardView;
              });
            },
            tooltip: _isCardView ? 'Switch to Table View' : 'Switch to Card View',
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/dentiverify-logo.png',
              width: 120,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : Column(
        children: [
          _buildSearchBar(ref),
          const SizedBox(height: 8),
          _buildPatientCount(state),
          const SizedBox(height: 8),
          Expanded(
            child: state.ebvPatientList == null || state.ebvPatientList!.isEmpty
                ? _buildEmptyState()
                : _isCardView
                ? _buildCardView(state, context)
                : SingleChildScrollView(child: _buildTableView(state, context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Patient Data...',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoSearchTextField(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (value) {
          ref.read(patientProvider.notifier).searchCallPatient(value);
        },
        controller: textController,
        placeholder: 'Search patients by name, ID, or status...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: const Icon(Icons.close, color: Colors.grey),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPatientCount(PatientState state) {
    final count = state.ebvPatientList?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Patients Found',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            _isCardView ? 'Card View' : 'Table View',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/list.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Patients Found",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try adjusting your search or filter",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(PatientState state, BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CommonDataTable<dynamic>(
        dataList: state.ebvPatientList!,
        columns: const [
          DataColumn(label: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Documents', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Insurance', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Plan Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        dataSourceBuilder: (dataList) => GenericDataSource<dynamic>(
          dataList,
              (item) => [
            DataCell(CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.person, color: Colors.blue),
            )),
            DataCell(Text(
              item['patientId'].toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            )),
            DataCell(
              SizedBox(
                width: 120,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewPatient(data: item),
                      ),
                    );
                  },
                  child: Text(
                    item['PatientName'] ?? '--',
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            DataCell(
              IconButton(
                icon: Icon(
                  Icons.file_copy_rounded,
                  color: Colors.red[400],
                  size: 22,
                ),
                onPressed: () {
                  // ref.read(patientProvider.notifier).showPdfViewer(context);
                },
                tooltip: 'View Documents',
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Text(
                  item['insurancePayer'] ?? '--',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(item['Pat_status']).withOpacity(0.2),
                  border: Border.all(color: getStatusColor(item['Pat_status'])),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['Pat_status'] ?? '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: getStatusColor(item['Pat_status']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Text(
                  item['Status'] ?? '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: getPlanStatusColor(item['Status']),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
              (dynamic data) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewPatient(data: data),
              ),
            );
          },
        ),
        onSelect: (person) {},
      ),
    );
  }

  Widget _buildCardView(PatientState state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.builder(
        itemCount: state.ebvPatientList!.length,
        itemBuilder: (context, index) {
          final patient = state.ebvPatientList![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildPatientCard(patient, context),
          );
        },
      ),
    );
  }

  Widget _buildPatientCard(dynamic patient, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPatient(data: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Avatar and status
              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.person, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(patient['Pat_status']).withOpacity(0.2),
                      border: Border.all(color: getStatusColor(patient['Pat_status'])),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient['Pat_status'] ?? '--',
                      style: TextStyle(
                        fontSize: 10,
                        color: getStatusColor(patient['Pat_status']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Middle - Patient information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['PatientName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${patient['patientId']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Insurance information
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patient['insurancePayer'] ?? 'No insurance',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Plan status
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          patient['Status'] ?? '--',
                          style: TextStyle(
                            fontSize: 12,
                            color: getPlanStatusColor(patient['Status']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right side - Action buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue[700], size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewPatient(data: patient),
                        ),
                      );
                    },
                    tooltip: 'View Details',
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.file_copy, color: Colors.red[400], size: 24),
                    onPressed: () {
                      // ref.read(patientProvider.notifier).showPdfViewer(context);
                    },
                    tooltip: 'View Documents',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(status) {
    if (status == "Verified") {
      return Colors.green;
    } else if (status == "Pending") {
      return Colors.orange;
    } else if (status == "Rejected") {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  Color getPlanStatusColor(status) {
    if (status == "Active") {
      return Colors.green;
    } else if (status == "Pending") {
      return Colors.orange;
    } else if (status == "Expired") {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}