import 'dart:developer';

import 'package:ebv/provider/patient_provider.dart';
import 'package:ebv/screens/network_check_service.dart';
import 'package:ebv/screens/patient/Profile.dart';
import 'package:ebv/screens/chats/combined_chat.dart';
import 'package:ebv/screens/appointments/view_today_appointments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/auth_provider.dart';
import '../../provider/home_provider.dart';
import '../../routes/menu_routes.dart';
import '../../widgets/dialogs.dart';
import '../auth/email_login.dart';
import '../notification/notifications.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final icons = [
    Icons.home,
    Icons.calendar_month,
    Icons.verified_user,
    Icons.supervised_user_circle_outlined,
    Icons.phone_callback,
    Icons.history_outlined,
    Icons.sticky_note_2_sharp,
    Icons.dashboard_rounded
  ];

  @override
  void initState() {
    super.initState();
    // Initialize data
    Future.microtask(() {
      ref.read(homeProvider.notifier).readUser();
      ref.read(homeProvider.notifier).getFilterAppointments();
      ref.read(patientProvider.notifier).getAppointments(context);
      ref.read(patientProvider.notifier).getPmsPatients(context);
      ref.read(patientProvider.notifier).getEbvPatients(context);
      ref.read(patientProvider.notifier).getPatientsCallHistory(context);
    });

    // Schedule auth check after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  void _initializeAuth() {
    final authState = ref.read(authStateProvider); // Use read instead of watch
    if (!authState.isTokenVerified && !authState.isLoading) {
      ref.read(authStateProvider.notifier).initializeAuth(context);
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Auth state listener - moved to build method
    ref.listen<AuthState>(authStateProvider, (previous, current) {
      if (!current.isTokenVerified && !current.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignIn()),
          );
        });
      }
    });

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showExitConfirmationDialog(context);
        return shouldExit ?? false;
      },
      child: SafeArea(
        child: NetworkManager(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CombinedChatScreen()));
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF8548D0).withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.chat, color: Colors.white, size: 24),
              ),
            ),
            key: _scaffoldKey,
            drawer: _buildDrawer(state),
            backgroundColor: Colors.grey[50],
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(state, context),
                  state.todaysappointmentList!.isNotEmpty ?
                  _buildAppointmentsAlert(context) : Container(),
                  _buildQuickActionsHeader(),
                  _buildMenuGrid(ref, context, screenWidth),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Rest of your methods remain the same...
  Widget _buildAppointmentsAlert(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ViewAppointments()));
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8548D0).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Appointments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check your scheduled appointments for today',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(dynamic state) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/dentiverify-logo.png',
                    height: 40,
                    width: 160,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Dentiverify Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  hintText: 'Search menu...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: state.menus?.length ?? 0,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(state.menus?[index]['iconClr'] ?? 0xFF8548D0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icons[index],
                        color: Color(state.menus?[index]['iconClr'] ?? 0xFF8548D0),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${state.menus?[index]['menu']}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                    onTap: () {
                      MenuRoutes.goRoute(state.menus?[index]['menu'], context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout Button
          Container(
            margin: EdgeInsets.all(16),
            child: ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ShoeAlert(message: ''),
                );
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic state, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openDrawer,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu, color: Colors.white, size: 22),
                  ),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationsScreen()));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Profile Card
          Container(
            margin: EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: Card(
              elevation: 5,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.userInfo?.email ?? "Guest User",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              state.userInfo?.roleName != null
                                  ? "${state.userInfo!.roleName} Role"
                                  : "No Role",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8548D0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            '${ref.watch(homeProvider).menus?.length ?? 0} Options',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(WidgetRef ref, BuildContext context, double screenWidth) {
    final state = ref.watch(homeProvider);
    final menus = state.menus ?? [];

    if (menus.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8548D0),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15.0,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        final baseColor = Color(menu['color'] is int ? menu['color'] : 0xFF4285F4);
        final iconColor = Color(menu['iconClr'] is int ? menu['iconClr'] : 0xFFFFFFFF);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                MenuRoutes.goRoute(menu['routeName'], context);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      baseColor.withOpacity(0.9),
                      baseColor,
                      baseColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: baseColor.withOpacity(0.6),
                    width: 2.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icons[index],
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${menu['menu']}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}