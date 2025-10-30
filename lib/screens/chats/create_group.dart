import 'package:ebv/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group_model.dart';
import '../../provider/chat_provider.dart';

class CreateGroup extends ConsumerStatefulWidget {
  final int currentUserId;
  final String? currentUserName;
  const CreateGroup({required this.currentUserId,required this.currentUserName});

  @override
  ConsumerState<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends ConsumerState<CreateGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _groupNameFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _selectedMemberIds = [];
  final List<String> _selectedMemberNames = [];

  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _isMounted = false;
    _groupNameController.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _groupNameFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (_isMounted) {
      setState(() {});
    }
  }

  void _toggleMemberSelection(ChatUser user) {
    if (!_isMounted) return;
    setState(() {
      if (_selectedMemberIds.contains(user.userID.toString())) {
        _selectedMemberIds.remove(user.userID.toString());
        _selectedMemberNames.remove(user.username);
      } else {
        _selectedMemberIds.add(user.userID.toString());
        _selectedMemberNames.add(user.username);
      }
    });
  }

  void _removeSelectedMember(String memberId, String memberName) {
    if (!_isMounted) return;
    setState(() {
      _selectedMemberIds.remove(memberId);
      _selectedMemberNames.remove(memberName);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_isMounted) return;

    final navigator = Navigator.of(context);
    final String groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      _showErrorSnackBar('Please enter a group name');
      _groupNameFocusNode.requestFocus();
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      _showErrorSnackBar('Select at least one member');
      return;
    }

    try {
      await ref.read(chatProvider.notifier).createGroup(
        groupName: groupName,
        memberIds: _selectedMemberNames,
      );

      if (_isMounted) {
        // _showSuccessSnackBar('Group "$groupName" created successfully!');
        // Navigate back without loading groups if widget is disposed
        if (_isMounted) {
          navigator.pop();
        }
      }
    } catch (e) {
      if (_isMounted) {
        _showErrorSnackBar('Failed to create group. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!_isMounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!_isMounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectedMembersChips() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedMemberIds.isEmpty ? Colors.grey.shade50 : Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedMemberIds.isEmpty ? Colors.grey.shade300 : Colors.deepPurple.shade100,
        ),
      ),
      child: _selectedMemberIds.isEmpty
          ? Row(
        children: [
          Icon(Icons.people_outline, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Text(
            'No members selected yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Members • ${_selectedMemberIds.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMemberIds.asMap().entries.map((entry) {
              final index = entry.key;
              final memberId = entry.value;
              final memberName = _selectedMemberNames[index];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Chip(
                  backgroundColor: Colors.deepPurple.shade100,
                  deleteIconColor: Colors.deepPurple,
                  onDeleted: () => _removeSelectedMember(memberId, memberName),
                  label: Text(
                    memberName,
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  avatar: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.deepPurple.shade200,
                    child: Text(
                      memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<ChatUser> filteredUsers, bool hasSearchQuery) {
    if (filteredUsers.isEmpty) {
      return Expanded(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasSearchQuery ? Icons.search_off_rounded : Icons.group_off_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  hasSearchQuery
                      ? 'No members found'
                      : 'No contacts available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  hasSearchQuery
                      ? 'Try adjusting your search terms'
                      : 'Your contacts will appear here',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = _selectedMemberIds.contains(user.userID.toString());

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleMemberSelection(user),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: isSelected
                                ? Colors.deepPurple
                                : Colors.deepPurple.shade100,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          user.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.deepPurple : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.deepPurple.shade700
                                : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepPurple : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isSelected
                                ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                                : const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade300,
              ),
              title: Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                height: 12,
                width: 180,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              trailing: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isCreatingGroup = chatState.isCreatingGroup;
    final userList = chatState.chats;
    final searchQuery = _searchController.text.trim().toLowerCase();
    final hasSearchQuery = searchQuery.isNotEmpty;
    final isMembersLoading = chatState.isLoading && userList.isEmpty;

    final List<ChatUser> filteredUsers = hasSearchQuery
        ? userList.where((user) {
      return user.username.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery) ||
          user.firstName.toLowerCase().contains(searchQuery) ||
          user.lastName.toLowerCase().contains(searchQuery);
    }).toList()
        : userList;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Group',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name Input
            TextField(
              controller: _groupNameController,
              focusNode: _groupNameFocusNode,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter a name for your group...',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.group_rounded, color: Colors.deepPurple),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Search Members
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Search Members',
                hintText: 'Search by name or email...',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.deepPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.requestFocus();
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Selected Members Section
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _buildSelectedMembersChips(),
            ),

            const SizedBox(height: 20),

            // Available Members Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Available Members',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Members List
            if (isMembersLoading) _buildLoadingState(),
            if (!isMembersLoading)
              _buildUserList(filteredUsers, hasSearchQuery),

            const SizedBox(height: 16),

            // Create Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCreatingGroup ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                  disabledBackgroundColor: Colors.deepPurple.withOpacity(0.5),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isCreatingGroup
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_add_rounded, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Create Group (${_selectedMemberIds.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}