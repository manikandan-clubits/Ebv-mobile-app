import 'package:ebv/provider/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/theme_colors.dart';

class ViewPatientDtl extends ConsumerStatefulWidget {
  final patientID;
  const ViewPatientDtl({super.key, this.patientID});

  @override
  ConsumerState<ViewPatientDtl> createState() => _ViewPatientDtlState();
}

class _ViewPatientDtlState extends ConsumerState<ViewPatientDtl>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey paymentSectionKey = GlobalKey();
  final GlobalKey basicSectionKey = GlobalKey();
  final GlobalKey contactSectionKey = GlobalKey();
  final GlobalKey vehicleSectionKey = GlobalKey();
  final GlobalKey petSectionKey = GlobalKey();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 5, vsync: this);
    _scrollToPaymentSection();
    Future.microtask(() {
      ref.read(patientProvider.notifier).getBasicInfo(widget.patientID);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPaymentSection() {
    final context = paymentSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Patient Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sticky Tab Bar
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(0.1),
          //         blurRadius: 8,
          //         offset: Offset(0, 2),
          //       ),
          //     ],
          //   ),
          //   child: TabBar(
          //     onTap: (value) {
          //       _scrollToSection(value);
          //     },
          //     controller: _tabController,
          //     isScrollable: true,
          //     indicator: BoxDecoration(
          //
          //       gradient: LinearGradient(
          //         colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
          //       ),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     labelColor: Colors.white,
          //     unselectedLabelColor: Colors.grey.shade600,
          //     labelStyle: TextStyle(
          //       fontSize: 13,
          //       fontWeight: FontWeight.w600,
          //     ),
          //     unselectedLabelStyle: TextStyle(
          //       fontSize: 13,
          //       fontWeight: FontWeight.w500,
          //     ),
          //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     tabs: [
          //       Tab(text: "Basic Info"),
          //       Tab(text: "Contact Info"),
          //       Tab(text: "Insurance Info"),
          //       Tab(text: "Appointments"),
          //       Tab(text: "Treatments Info"),
          //     ],
          //   ),
          // ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Basic Information Section
                  _buildSectionCard(
                    key: basicSectionKey,
                    title: 'Basic Information',
                    icon: Icons.person_outline_rounded,
                    child: _buildBasicInfoSection(),
                  ),

                  const SizedBox(height: 16),

                  // Contact Information Section
                  _buildSectionCard(
                    key: contactSectionKey,
                    title: 'Contact Information',
                    icon: Icons.contact_phone_rounded,
                    child: _buildContactInfoSection(),
                  ),

                  const SizedBox(height: 16),

                  // Insurance Information Section
                  _buildSectionCard(
                    key: paymentSectionKey,
                    title: 'Insurance Information',
                    icon: Icons.medical_services_rounded,
                    child: _buildInsuranceInfoSection(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int index) {
    GlobalKey? targetKey;
    switch (index) {
      case 0:
        targetKey = basicSectionKey;
        break;
      case 1:
        targetKey = contactSectionKey;
        break;
      case 2:
        targetKey = paymentSectionKey;
        break;
      case 3:
        targetKey = vehicleSectionKey;
        break;
      case 4:
        targetKey = petSectionKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(targetKey!.currentContext!,
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  Widget _buildSectionCard({
    required GlobalKey key,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.symmetric(horizontal:20),
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
          // Section Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF29BFFF).withOpacity(0.1),
                  Color(0xFF8548D0).withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF29BFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

  Widget _buildBasicInfoSection() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(patientProvider);
        final resident = state.basicInfo?.first;

        if (resident == null) {
          return _buildLoadingState();
        }

        return Column(
          children: [
            // Profile Summary Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        resident['patFname']?.toString().substring(0, 1) ?? 'P',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${resident['patFname'] ?? "N/A"}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Patient ID: ${resident['PatientID']?.toString() ?? "N/A"}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Information Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildInfoCard("Age", resident['Age'].toString() ?? "N/A", Icons.cake_rounded),
                _buildInfoCard("Phone", resident['mobileNumber'].toString() ?? "N/A", Icons.phone_rounded),
                _buildInfoCard("Email", resident['email'] ?? "N/A", Icons.email_rounded),
                _buildInfoCard("Marital Status", resident['maritalStatus'] ?? "N/A", Icons.favorite_rounded),
                _buildInfoCard("Relationship", resident['relationship'] ?? "N/A", Icons.people_rounded),
                _buildInfoCard("Hygiene", resident['HygenieSchedule'] ?? "N/A", Icons.cleaning_services_rounded),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.blue.shade600),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(patientProvider);
        if (state.contactLoading) {
          return _buildLoadingState();
        }
        return state.contactInfo != null && !state.contactLoading
            ? FamilyInfoDropdownTable(
          famInfo: state.contactInfo,
          onTab: (index, info) {},
          residentId: 36,
        )
            : _buildEmptyState("No contact information available");
      },
    );
  }

  Widget _buildInsuranceInfoSection() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(patientProvider);
        if (state.isLoading) {
          return _buildLoadingState();
        }
        return state.contactInfo != null
            ? InsuranceDropdownTable(
          insurance: state.contactInfo,
          onTab: (index, info) {},
          patientId: 36,
        )
            : _buildEmptyState("No insurance information available");
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF29BFFF)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading information...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



class FamilyInfoDropdownTable extends StatefulWidget {
  final List<dynamic>? famInfo;
  final void Function(int index, dynamic familyInfo) onTab;
  final int residentId;

  const FamilyInfoDropdownTable({
    super.key,
    required this.famInfo,
    required this.onTab,
    required this.residentId,
  });

  @override
  State<FamilyInfoDropdownTable> createState() =>
      _FamilyInfoDropdownTableState();
}

class _FamilyInfoDropdownTableState extends State<FamilyInfoDropdownTable> {
  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    if (widget.famInfo!.isEmpty) {
      return Center(child: Image.asset(
          width: 150,
          height: 100,
          'assets/images/notfound.png'));
    }

    return Column(

      children: [
        ...widget.famInfo!.map((familyInfo) {
          final id = familyInfo['ContactID'] as int;
          final isExpanded = _expandedItems[id] ?? false;

          return Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey)),
            child: Column(
              children: [
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Visibility(
                        visible: widget.famInfo!.indexOf(familyInfo) == 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFCF2),
                            border: Border.all(
                                color: const Color(0xFFAAEFC6)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Primary',
                            // textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF057647),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(familyInfo['TypeName'] ?? '',
                                style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.mode_edit_outline_outlined,
                                    color: Colors.blue),
                                onPressed: () => widget.onTab(widget.famInfo!.indexOf(familyInfo), familyInfo),
                              ),
                              IconButton(
                                icon: Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more),
                                onPressed: () {
                                  setState(() {
                                    _expandedItems[id] = !isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],

                      ),
                    ],
                  ),

                ),
                // Expanded Details
                if (isExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _DetailRow(
                          icon: Icons.email,
                          label: 'Door',
                          value: familyInfo['Address'],
                        ),
                        _DetailRow(
                          icon: Icons.email,
                          label: 'City',
                          value: familyInfo['City'] ?? 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.emergency,
                          label: 'State',
                          value: familyInfo['State'],
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.person,
                          label: 'Pincode',
                          value: familyInfo['Pincode'],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

      ],
    );
  }
}



class InsuranceDropdownTable extends StatefulWidget {
  final List<dynamic>? insurance;
  final void Function(int index, dynamic familyInfo) onTab;
  final int patientId;

  const InsuranceDropdownTable({
    super.key,
    required this.insurance,
    required this.onTab,
    required this.patientId,
  });

  @override
  State<InsuranceDropdownTable> createState() =>
      _InsuranceDropdownTableState();
}

class _InsuranceDropdownTableState extends State<InsuranceDropdownTable> {
  final Map<int, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    if (widget.insurance!.isEmpty) {
      return Center(child: Image.asset(
          width: 150,
          height: 100,
          'assets/images/notfound.png'));
    }

    return Column(
      children: [
        ...widget.insurance!.map((insurance) {
          final id = insurance['ContactID'] as int;
          final isExpanded = _expandedItems[id] ?? false;

          return Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey)),
            child: Column(
              children: [
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Visibility(
                        visible: widget.insurance!.indexOf(insurance) == 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFCF2),
                            border: Border.all(
                                color: const Color(0xFFAAEFC6)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Primary',
                            // textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF057647),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('Insurance1',
                                style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.mode_edit_outline_outlined,
                                    color: Colors.blue),
                                onPressed: () => widget.onTab(widget.insurance!.indexOf(insurance), insurance),
                              ),
                              IconButton(
                                icon: Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more),
                                onPressed: () {
                                  setState(() {
                                    _expandedItems[id] = !isExpanded;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],

                      ),
                    ],
                  ),

                ),
                // Expanded Details
                if (isExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _DetailRow(
                          icon: Icons.email,
                          label: 'Relationship',
                          value: '',
                        ),
                        _DetailRow(
                          icon: Icons.email,
                          label: 'FirstName',
                          value:  'N/A',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.emergency,
                          label: 'DOB',
                          value: '',
                        ),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.person,
                          label: 'InsNo',
                          value: '',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

      ],
    );
  }
}


class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmergency;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEmergency ? Colors.red : Colors.black,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

