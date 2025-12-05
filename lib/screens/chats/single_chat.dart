import 'dart:developer';
import 'package:ebv/screens/chats/single_chat_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/chat_model.dart';
import '../../provider/chat_provider.dart';

class SingleChat extends ConsumerStatefulWidget {
  const SingleChat({super.key});

  @override
  ConsumerState<SingleChat> createState() => _ChatSelectionScreenState();
}

class _ChatSelectionScreenState extends ConsumerState<SingleChat> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    ref.read(chatProvider.notifier).initializeSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadSingleChatUsers();
    });
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
    _searchController.dispose();
    super.dispose();
  }

  List<ChatUser> _filterChats(List<ChatUser> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      final searchTerm = _searchQuery.toLowerCase();
      return chat.firstName.toLowerCase().contains(searchTerm) ||
          chat.lastName.toLowerCase().contains(searchTerm) ||
          chat.username.toLowerCase().contains(searchTerm) ||
          chat.email.toLowerCase().contains(searchTerm);
    }).toList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading conversations',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting your messages ready',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Iconsax.search_normal_1 : Iconsax.messages_3,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching
                ? 'No users found'
                : 'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isSearching
                  ? 'Try searching with a different name or email address'
                  : 'Start a new conversation to begin your messaging journey',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final filteredChats = _filterChats(chatState.chats);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Iconsax.close_circle,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),



          // Chat List
          Expanded(
            child: chatState.chatListLoading && chatState.chats.isEmpty
                ? _buildLoadingState()
                : filteredChats.isEmpty
                ? _buildEmptyState(_searchQuery.isNotEmpty)
                : RefreshIndicator(
              onRefresh: _loadChatsSafely,
              backgroundColor: Colors.white,
              color: Colors.deepPurple,
              displacement: 40,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return ChatListItem(chat: chat);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

