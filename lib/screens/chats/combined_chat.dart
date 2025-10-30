import 'dart:developer';
import 'package:ebv/screens/chats/group_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../provider/chat_provider.dart';
import 'single_chat.dart';

class CombinedChatScreen extends ConsumerStatefulWidget {
  const CombinedChatScreen({super.key});

  @override
  ConsumerState<CombinedChatScreen> createState() => _CombinedChatScreenState();
}

class _CombinedChatScreenState extends ConsumerState<CombinedChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isMounted = true;
    ref.read(chatProvider.notifier).initializeSocket();
  _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        _loadChatsSafely();
      }
    });
  }

   void _handleTabChange() {
    if (!_tabController.indexIsChanging && _isMounted) {
      if (_tabController.index == 0) {
        _loadChatsSafely();
      } else if (_tabController.index == 1) {
        _loadGroupsSafely();
      }
    }
  }

   Future<void> _loadGroupsSafely() async {
    try {
      await ref.read(chatProvider.notifier).loadGroups();
    } catch (e) {
      log('Error loading groups: $e');
    }
  }

  Future<void> _loadChatsSafely() async {
    try {
      await ref.read(chatProvider.notifier).loadSingleChatUsers();
    } catch (e) {
      log('Error loading chats: $e');
    }
  }

  @override
  void dispose() {
    _isMounted = false;
     _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Messages',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(
                  icon: Icon(Icons.chat_bubble_outline),
                  text: 'Chats',
                ),
                Tab(
                  icon: Icon(Icons.group_outlined),
                  text: 'Groups',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Individual Chats Tab
          const SingleChat(),
          // Group Chats Tab
          const GroupListScreen(),
        ],
      ),
    );
  }
}




