import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebv/provider/patient_provider.dart';
import 'package:ebv/screens/patient/view_patient_dtl.dart';
import 'package:ebv/widgets/custom_table.dart';

class PmsPatients extends ConsumerStatefulWidget {
  const PmsPatients({super.key});

  @override
  ConsumerState<PmsPatients> createState() => _PatientsEligibilityVerificationState();
}

class _PatientsEligibilityVerificationState extends ConsumerState<PmsPatients> {


  TextEditingController textController = TextEditingController();
  bool _isCardView = true;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ref.read(patientProvider.notifier).getPmsPatients(context);
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          'Patients',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white
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
            child: state.pmsPatientList == null || state.pmsPatientList!.isEmpty
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
      padding: EdgeInsets.symmetric(vertical: 10),
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
          ref.read(patientProvider.notifier).searchCallPmsPatient(value);
        },
        controller: textController,
        placeholder: 'Search patients by name, ID ...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: const Icon(Icons.close, color: Colors.grey),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPatientCount(PatientState state) {
    final count = state.pmsPatientList?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Patients',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14,
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
        dataList: state.pmsPatientList!,
        columns: const [
          DataColumn(label: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Age/Gender', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Future Visit', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        dataSourceBuilder: (dataList) => GenericDataSource<dynamic>(
          dataList,
              (item) => [
            DataCell(CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.person, color: Colors.blue),
            )),
            DataCell(Text(item['PatientID'].toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            )),
            DataCell(
              SizedBox(
                width: 120,
                child: InkWell(
                  onTap: () => _navigateToPatientDetails(item['PatientID'], context),
                  child: Text(
                    item['PatientName'].toString() ?? '--',
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
            DataCell(Text(
              '\$${item['BalanceDue'].toString() ?? '0.00'}',
              style: TextStyle(
                color: (double.tryParse(item['BalanceDue']?.toString() ?? '0') ?? 0) > 0
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            )),
            DataCell(Text(
              "${item['Age']?.toString() ?? '--'} / ${item['Gender'] ?? '--'}",
              style: const TextStyle(fontSize: 12),
            )),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(item['maritalStatus']).withOpacity(0.2),
                  border: Border.all(color: getStatusColor(item['maritalStatus'])),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['maritalStatus'] ?? '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: getStatusColor(item['maritalStatus']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataCell(Text(
              item['FutureVisit'] ?? '--',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            )),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.blue,
                onPressed: () => _navigateToPatientDetails(item['PatientID'], context),
              ),
            ),
          ],
              (dynamic data) {
            _navigateToPatientDetails(data['PatientID'], context);
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
        controller: _scrollController,
        itemCount: state.pmsPatientList!.length,
        itemBuilder: (context, index) {
          final patient = state.pmsPatientList![index];
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
        onTap: () => _navigateToPatientDetails(patient['PatientID'], context),
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
                      color: getStatusColor(patient['maritalStatus']).withOpacity(0.2),
                      border: Border.all(color: getStatusColor(patient['maritalStatus'])),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient['maritalStatus'] ?? '--',
                      style: TextStyle(
                        fontSize: 10,
                        color: getStatusColor(patient['maritalStatus']),
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
                      'ID: ${patient['PatientID']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Patient details row
                    Row(
                      children: [
                        _buildInfoItem(
                          icon: Icons.person_outline,
                          text: "${patient['Age']?.toString() ?? '--'} / ${patient['Gender'] ?? '--'}",
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          icon: Icons.account_balance_wallet,
                          text: '\$${patient['BalanceDue'] ?? '0.00'}',
                          color: (double.tryParse(patient['BalanceDue']?.toString() ?? '0') ?? 0) > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Future visit
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patient['FutureVisit'] ?? 'No visit scheduled',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Right side - Action button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text, Color color = Colors.grey}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToPatientDetails(patientID, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPatientDtl(patientID: patientID),
      ),
    );
  }

  Color getStatusColor(status) {
    if (status == "Married") {
      return Colors.green;
    } else if (status == "Single") {
      return Colors.blue;
    } else if (status == "Divorced") {
      return Colors.orange;
    } else if (status == "Widowed") {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }
}