import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/chat_model.dart';
import '../../provider/chat_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'message_bubble.dart';

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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          SizedBox(height: 16),
          Text(
            'Loading conversations...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
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
          Icon(
            isSearching ? Icons.search_off : Icons.chat_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No users found for "$_searchQuery"'
                : 'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Start a new conversation to begin chatting',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade500),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            return _ChatListItem(chat: chat);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends ConsumerWidget {
  final ChatUser chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    // Get messages for this specific chat
    final chatMessages = chatState.messages.where((m) {
      final messageChatId = m.chatID?.toString() ?? '';
      final currentChatId = chat.chatID?.toString() ?? '';
      return messageChatId == currentChatId;
    }).toList();

    // Sort by timestamp (newest first)
    chatMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

    final lastMessage = chatMessages.isNotEmpty ? chatMessages.first : null;
    final lastMessageContent =
        lastMessage?.content ?? chat.lastMessage ?? 'Start a conversation';
    final lastMessageTime = lastMessage?.sentAt ?? chat.lastSeen;

    // Calculate unread count
    final unreadCount = chatMessages.where((m) {
      return m.receiverID == chatState.currentChatId &&
          !m.isSeenByReceiver &&
          m.senderID != chatState.currentChatId;
    }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                chat.firstName.isNotEmpty
                    ? chat.firstName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (chat.isActive) // Assuming you have an isOnline property
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.firstName.isNotEmpty ? '${chat.firstName}' : 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lastMessageContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          if (chat.chatID != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.chatID!.toString(),
                  chatName:
                      chat.firstName.isNotEmpty ? chat.firstName : 'Unknown',
                  chat: chat,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final ChatUser? chat;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chat,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  List<PlatformFile> _selectedFiles = [];
  List urls = [];
  bool _isMounted = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted && widget.chat != null) {
        _loadMessagesSafely();
      }
    });
  }

  Future<void> _loadMessagesSafely() async {
    try {
      await ref.read(chatProvider.notifier).loadMessages(
            widget.chatId,
            widget.chat!.userID,
          );
    } catch (e) {
      log('Error loading messages: $e');
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_selectedFiles.isNotEmpty) {
      final fileUrl =
          await ref.read(chatProvider.notifier).uploadImage(_selectedFiles);
      urls = [];
      urls.add(fileUrl);
    }

    if (_messageController.text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(
          uploadUrl: urls,
          author: widget.chatName,
          content: _messageController.text.trim(),
          receiverId: widget.chat!.userID,
          chatId: int.tryParse(widget.chatId) ?? 0,
          selectedFiles: _selectedFiles);
      _selectedFiles.clear();
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    try {
      var status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied || status.isRestricted) {
        status = await Permission.storage.request();
        status = await Permission.photos.request();

        if (status.isGranted) {
          return true;
        }
      }

      if (status.isPermanentlyDenied) {}

      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  Future<void> pickDocuments() async {
    final permissionStatus = await _checkAndRequestPermission();
    if (permissionStatus) {
      return;
    }
    _selectedFiles.clear();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'png'
        ],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
          _messageController.text = result.files.first.name;
        });

        for (final file in result.files) {
          setState(() {
            _selectedFiles.removeWhere((f) => f.path == file.path);
            _selectedFiles.add(file);
          });
        }
      }
    } catch (e) {
      _showSnackBar("Failed to pick documents");
    }
  }

  Future<void> openCamera(BuildContext context) async {
    _selectedFiles.clear();
    try {
      final permissionStatus = await Permission.camera.request();

      if (!permissionStatus.isGranted) {
        print('Camera permission denied');
        return;
      }
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null && _isMounted) {
        print("Processing captured image...");
        final platformFile = await _convertXFileToPlatformFile(image);
        setState(() {
          _selectedFiles.add(platformFile);
          _messageController.text = image.name;
        });
        // setState(() {
        //   _messageController.text = platformFile.name;
        // });
      }
    } catch (e) {
      print("Failed to capture image");
    }
  }

  Future<PlatformFile> _convertXFileToPlatformFile(XFile xFile) async {
    final file = File(xFile.path);
    final bytes = await file.readAsBytes();

    return PlatformFile(
      name: xFile.name,
      size: await file.length(),
      bytes: bytes,
      path: xFile.path,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    final isMe = message.senderID == widget.chat?.userID;

    return MessageBubble(
      message: message,
      isMe: isMe,
      showAvatar: true,
      showTime: true,
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading:
                      const Icon(Iconsax.document, color: Colors.deepPurple),
                  title: const Text('Document'),
                  onTap: () {
                    pickDocuments();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.camera, color: Colors.deepPurple),
                  title: const Text('Camera'),
                  onTap: () {
                    openCamera(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedFilesPreview() {
    if (_selectedFiles.isEmpty) return const SizedBox();
    final chatState = ref.watch(chatProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Attachments (${_selectedFiles.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (_selectedFiles.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFiles.clear();
                      _messageController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Files List
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final fileExtension = _getFileExtension(file.name);
                final isImage = _isImageFile(file.name);
                final fileSize = _formatFileSize(file.size);

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 120,
                  child: Stack(
                    children: [
                      // File Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: chatState.isUpload
                                ? Colors.blue.shade300
                                : Colors.green.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // File Icon/Image Preview
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _getFileColor(fileExtension),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: chatState.isUpload
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                            ),
                                          )
                                        : isImage
                                            ? Icon(
                                                Icons.image,
                                                color: Colors.white,
                                                size: 18,
                                              )
                                            : Icon(
                                                _getFileIcon(fileExtension),
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                  ),
                                ),
                                const Spacer(),
                                if (chatState.isUpload)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.sync,
                                      color: Colors.blue.shade600,
                                      size: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // File Size
                            Text(
                              fileSize,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Remove Button
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFiles.removeAt(index);
                              _messageController.clear();
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Upload Status
          if (chatState.isUpload) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uploading files...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'file';
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final ext = _getFileExtension(fileName);
    return imageExtensions.contains(ext);
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red.shade500;
      case 'doc':
      case 'docx':
        return Colors.blue.shade500;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade500;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple.shade500;
      case 'zip':
      case 'rar':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    widget.chatName.isNotEmpty
                        ? widget.chatName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget
                    .chat!.isActive) // Assuming you have an isOnline property
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.chat!.isActive ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: chatState.isConnected
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.call, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Iconsax.video, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'info',
                  child: Text('View Info'),
                ),
                const PopupMenuItem<String>(
                  value: 'mute',
                  child: Text('Mute Notifications'),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Text('Clear Chat'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.chatMsgLoading && chatState.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'start the conversation',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(messages[index]);
                        },
                      ),
          ),
          _buildSelectedFilesPreview(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.add, color: Colors.deepPurple),
                  onPressed: _showMediaOptions,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: TextField(
                      onChanged:
                          ref.watch(chatProvider.notifier).typingMessage(),
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.deepPurple,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
