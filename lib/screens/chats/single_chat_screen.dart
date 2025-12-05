import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/chat_model.dart';
import '../../provider/chat_encrpt_provider.dart';
import '../../provider/chat_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/storage_services.dart';
import 'single_message_bubble.dart';

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
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late FocusNode _messageFocusNode;
  late AudioPlayer _audioPlayer;
  Timer? _typingTimer;
  bool _isMounted = false;
  bool _isInitializing = false;
  List<PlatformFile> _selectedFiles = [];
  List urls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    // Initialize controllers
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageFocusNode = FocusNode();
    _audioPlayer = AudioPlayer();

    // Setup message controller listener
    _messageController.addListener(_handleMessageTextChange);

    // Initialize chat after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatAsync();
    });
  }

  void _handleMessageTextChange() {
    if (!_isMounted) return;
    _handleTyping();
  }

  Future<void> _initializeChatAsync() async {
    if (!_isMounted || widget.chat == null || _isInitializing) return;

    _isInitializing = true;

    try {
      // Step 1: Initialize chat keys
      await _initializeChatKeys();

      // Step 2: Load messages
      await _loadMessagesSafely();

      // Step 3: Scroll to bottom
      _scrollToBottom();
      log('✅ All chat initialization completed successfully');
    } catch (e, stackTrace) {
      log('Chat initialization failed: $e');

      if (_isMounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize chat'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (_isMounted) {
        _isInitializing = false;
      }
    }
  }

  Future<void> _initializeChatKeys() async {
    if (!_isMounted || !context.mounted) return;
    log('🔄 Initializing chat keys...');
    final chatKeysNotifier = ref.read(chatKeysProvider.notifier);
    final chatKeysState = ref.read(chatKeysProvider);
    try {
      // Step 1: Verify auth keys
      await _safeVerifyAuthKeys(chatKeysNotifier);
      if (!_isMounted) return;

      // Step 2: Get sender keys
      await _safeGetSenderKeys(chatKeysNotifier, chatKeysState);
      if (!_isMounted) return;

      // Step 3: Get receiver keys (if available)
      await _safeGetReceiverKeys(chatKeysNotifier);
      if (!_isMounted) return;
      // Verify final state
      _verifyKeysState();

    } catch (e, stackTrace) {
      log('Chat keys initialization error: $e');
      log('Stack trace: $stackTrace');

      // Don't throw - continue with message loading
      if (_isMounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Security initialization had issues'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _safeVerifyAuthKeys(ChatKeysNotifier notifier) async {
    try {
      log('🔐 Verifying auth keys...');
      await notifier.verifyAuthKeys();
      log('✅ Auth keys verified');
    } catch (e) {
      log('⚠️ Auth keys verification failed: $e');
      // Continue without throwing - auth might not be critical
    }
  }

  Future<void> _safeGetSenderKeys(ChatKeysNotifier notifier, ChatKeysState state) async {
    try {
      if (state.senderKeys == null) {
        log('📤 Getting sender chat keys...');
        await notifier.getSenderChatKeys();

        // Verify
        final updatedState = ref.read(chatKeysProvider);
        if (updatedState.senderKeys == null) {
          log('⚠️ Warning: Sender keys may not be available');
        } else {
          log('✅ Sender chat keys retrieved');
        }
      } else {
        log('📤 Sender keys already available');
      }
    } catch (e) {
      log('❌ Failed to get sender keys: $e');
      throw e; // This is critical, rethrow
    }
  }

  Future<void> _safeGetReceiverKeys(ChatKeysNotifier notifier) async {
    try {
      if (widget.chat != null && widget.chat!.receiverID != null) {
        final receiverId = widget.chat!.receiverID!;
        log('📥 Getting receiver chat keys for ID: $receiverId');

        await notifier.getReceiverChatKeys(receiverId);

        final updatedState = ref.read(chatKeysProvider);
        final receiverIdStr = receiverId.toString();

        if (updatedState.receiverKeys.containsKey(receiverIdStr)) {
          log('✅ Receiver chat keys retrieved');
        } else {
          log('⚠️ Receiver keys may not have been stored');
        }
      } else {
        log('ℹ️ No receiver ID available, skipping receiver keys');
      }
    } catch (e) {
      log('⚠️ Could not get receiver keys: $e');
      // Don't throw - receiver keys might not be critical
    }
  }

  void _verifyKeysState() {
    if (!_isMounted) return;

    final updatedState = ref.read(chatKeysProvider);

    if (updatedState.senderKeys == null) {
      log('⚠️ Warning: Sender keys are null');
    }

    if (updatedState.receiverKeys.isEmpty) {
      log('ℹ️ Info: No receiver keys available');
    }
  }

  Future<void> _loadMessagesSafely() async {
    if (!_isMounted || widget.chat == null) return;

    try {
      log('📥 Loading messages...');

      await ref.read(chatProvider.notifier).loadMessages(
        widget.chatId,
        widget.chat!.userID,
      );

      log('✅ Messages loaded successfully');

    } catch (e, stackTrace) {
      log('❌ Error loading messages: $e');
      log('Stack trace: $stackTrace');

      if (_isMounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!_isMounted || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTyping() {
    if (!_isMounted) return;
    _typingTimer?.cancel();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      // _markMessagesAsSeen();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _isInitializing = false;

    // Cleanup
    // _stopTyping();
    _typingTimer?.cancel();
    _audioPlayer.dispose();
    _messageController.removeListener(_handleMessageTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatState = ref.watch(chatProvider);

    // Call the public stopTyping function with required parameters
    chatNotifier.stopTyping(
      senderId: chatState.currentUserId!,
      senderName: chatState.currentUserName!,
      receiverId:widget.chat!.userID,
      groupId:0,
      isGroupChat: false,
    );
  }

  void _startTyping() {
    print("call_startTyping");
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatState = ref.watch(chatProvider);

    if (chatState.currentUserId != null && widget.chat?.userID != null && chatState.currentUserName != null) {
      chatNotifier.startTyping(
        senderId: chatState.currentUserId!,
        senderName: chatState.currentUserName!,
        receiverId: widget.chat!.userID!,
        groupId: null,
        isGroupChat: false,
      );
      log('📝 Started typing indicator');
    }
  }

  void _sendMessage() async {
    // if ( _selectedFiles.isEmpty) return;

    // Stop typing indicator
    _stopTyping();

    // Upload files if any
    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });
      try {
        urls = await ref.read(chatProvider.notifier).uploadImage(_selectedFiles);
      } catch (e) {
        log('Error uploading files: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload files: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }

    final chatState = ref.watch(chatProvider);
    final messageContent = _messageController.text.trim();

    if (messageContent.isNotEmpty || urls.isNotEmpty) {
      try {
        await ref.read(chatProvider.notifier).sendMessage(
          currentUserId: chatState.currentUserId!,
          type: MessageType.text,
          uploadUrl: urls.isNotEmpty ? urls : [],
          author: chatState.currentUserName ?? 'User',
          content: messageContent,
          receiverId: widget.chat?.userID,
          chatId: int.tryParse(widget.chatId) ?? 0,
          selectedFiles: _selectedFiles,
        );

        // Clear after sending
        _selectedFiles.clear();
        urls.clear();
        _messageController.clear();
        _scrollToBottom();
      } catch (e) {
        log('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Widget _buildMessage(Message message) {
    final chatState = ref.watch(chatProvider);
    final isMe = message.senderID == chatState.currentUserId;


    return MessageBubble(
      message: message,
      isMe: isMe,
      showAvatar: true,
      showTime: true,
      onLongPress: () => _showMessageOptions(message),
    );
  }

  void _showMessageOptions(Message message) {
    final chatState = ref.watch(chatProvider);
    final isMyMessage = message.senderID == chatState.currentUserId;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return SimpleMessageOptionsPopup(
          message: message,
          isMyMessage: isMyMessage,
          onEdit: () {
            _editMessage(message);
          },
          onDelete: (deleteForEveryone) {
            _deleteMessage(message, deleteForEveryone);
          },
          messageContext: context,
        );
      },
    );
  }

  void _editMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => EditMessageDialog(
        initialContent: message.content,
        onSave: (newContent) async {
          Navigator.pop(context);
          await _saveEditedMessage(message, newContent);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _saveEditedMessage(Message message, String newContent) async {
    if (newContent == message.content) return;

    try {
      final chatState = ref.watch(chatProvider);
      final chatNotifier = ref.read(chatProvider.notifier);

      await chatNotifier.editMessage(
        messageId: message.messageID!,
        newContent: newContent,
        receiverId: widget.chat?.userID ?? 0,
        isGroup: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message edited successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to edit message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(Message message, bool deleteForEveryone) async {
    try {
      final chatNotifier = ref.read(chatProvider.notifier);
      final chatState = ref.watch(chatProvider);

      await chatNotifier.deleteMessage(
        messageId: message.messageID!,
        receiverId: widget.chat?.userID ?? 0,
        isGroup: false,
        deleteForEveryone: deleteForEveryone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleteForEveryone
                ? 'Message deleted for everyone'
                : 'Message deleted for you',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Update contact list if needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildSelectedFilesPreview() {
    if (_selectedFiles.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade100,
                      Colors.blue.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedFiles.length} file${_selectedFiles.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedFiles.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFiles.clear();
                        urls.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final fileExtension = _getFileExtension(file.name);
                final isImage = _isImageFile(file.name);
                final fileSize = _formatFileSize(file.size);

                return Container(
                  margin: EdgeInsets.only(right: index == _selectedFiles.length - 1 ? 0 : 8),
                  width: 100,
                  child: Stack(
                    children: [
                      // File Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: chatState.isUpload ? Colors.blue.shade300 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // File Icon
                            Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getFileColor(fileExtension),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: isImage
                                      ? const Icon(
                                    Icons.image_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                      : Icon(
                                    _getFileIcon(fileExtension),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 2),
                            Center(
                              child: Text(
                                fileSize,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Remove Button
                      if (!chatState.isUpload)
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
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 12,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Max 3 files • 5MB each',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (_selectedFiles.length >= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Limit reached',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(PlatformFile file, int index) {
    final sizeInMB = (file.size / (1024 * 1024)).toStringAsFixed(2);
    final extension = file.extension?.toLowerCase() ?? 'unknown';

    return Stack(
      children: [
        Container(
          width: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getFileColor(extension).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getFileIcon(extension),
                        size: 32,
                        color: _getFileColor(extension),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sizeInMB MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade600;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade600;
      case 'jpg':
      case 'png':
      case 'jpeg':
        return Colors.purple.shade600;
      case 'txt':
        return Colors.grey.shade600;
      default:
        return Colors.deepPurple.shade600;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'png':
      case 'jpeg':
        return Icons.image_rounded;
      case 'txt':
        return Icons.text_fields_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    try {
      var status = await Permission.storage.status;
      if (status.isGranted) return true;

      if (status.isDenied || status.isRestricted) {
        status = await Permission.storage.request();
        status = await Permission.photos.request();
        return status.isGranted;
      }

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

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'png', 'jpeg'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty && _isMounted) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print("Failed to pick documents: $e");
    }
  }

  Future<void> openCamera(BuildContext context) async {
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
        final platformFile = await _convertXFileToPlatformFile(image);
        setState(() {
          _selectedFiles.add(platformFile);
        });
      }
    } catch (e) {
      print("Failed to capture image: $e");
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Share Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6a11cb).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.document, color: Color(0xFF6a11cb)),
                  ),
                  title: const Text('Document'),
                  subtitle: Text(
                    'Share files and documents',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pickDocuments();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6a11cb).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.camera, color: Color(0xFF6a11cb)),
                  ),
                  title: const Text('Camera'),
                  subtitle: Text(
                    'Take a photo',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    openCamera(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: const EdgeInsets.only(
              top: 30,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color:  Colors.grey.shade100,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                // User Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:  CircleAvatar(
                    radius: 44,
                    backgroundImage: widget.chat!.profilePicture!=null
                        ? NetworkImage(widget.chat!.profilePicture.toString())
                        : AssetImage('assets/images/profile.png') as ImageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.chatName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.chat!.isActive
                                  ? Colors.green.shade500
                                  : Colors.orange.shade500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.chat!.isActive ? 'Online' : 'Away',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.chat!.isActive
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.call,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
                  onPressed: () {
                    showAsBottomSheet(context);
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.video,
                      size: 20,
                      color: Colors.indigo,
                    ),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          Expanded(
            child: chatState.chatMsgLoading && chatState.messages.isEmpty
                ? Center(
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
                          color: Colors.deepPurple.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading messages',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Typing indicator at the top (since ListView is reversed)
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
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
                            child: const Icon(
                              Iconsax.messages_3,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Send a message to start the conversation',
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
                ],
              ),
            ),
          ),
          _buildSelectedFilesPreview(),

            SizedBox(height: 15,),
            if(chatState.typingStatus.toString().isNotEmpty && chatState.typingStatus!=null)
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Typing...'),
                )),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Attachment Button
                    GestureDetector(
                      onTap: _isUploading ? null : _showMediaOptions,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child:
                             const Icon(
                          Iconsax.add,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message Input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                maxLines: null,
                                enabled: !_isUploading,
                                onChanged: (value) {
                                  if (_messageController.text.isNotEmpty) {
                                    _startTyping();
                                  }else {
                                    _stopTyping();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: _isUploading ? 'Uploading...' : 'Type a message...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: _isUploading ? Colors.grey.shade400 : Colors.grey,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      child: FloatingActionButton(
                        onPressed:  _sendMessage,
                        backgroundColor:  Colors.deepPurple,
                        elevation: 0,
                        child: _isUploading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(
                          Iconsax.send_2,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class SimpleMessageOptionsPopup extends StatelessWidget {
  final Message message;
  final bool isMyMessage;
  final Function() onEdit;
  final Function(bool) onDelete;
  final BuildContext messageContext;

  const SimpleMessageOptionsPopup({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.onEdit,
    required this.onDelete,
    required this.messageContext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),

        // Menu positioned at tap location
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // // Copy
                        // _buildMenuItem(
                        //   icon: Iconsax.copy,
                        //   label: 'Copy',
                        //   onTap: onCopy,
                        //   color: Colors.grey.shade700,
                        // ),
                        //
                        // // Forward
                        // _buildMenuItem(
                        //   icon: Iconsax.send_2,
                        //   label: 'Forward',
                        //   onTap: onForward,
                        //   color: Colors.grey.shade700,
                        // ),

                        // Edit (only for my messages)
                        if (isMyMessage)
                          _buildMenuItem(
                            icon: Iconsax.edit_2,
                            label: 'Edit',
                            onTap: onEdit,
                            color: Colors.blue.shade600,
                          ),

                        // Delete
                        _buildMenuItem(
                          icon: Iconsax.trash,
                          label: 'Delete',
                          onTap: () => _showDeleteOptions(context),
                          color: Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),

                  // Cancel button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Function() onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(messageContext);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: color,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteOptions(BuildContext context) {
    showDialog(
      context: messageContext,
      builder: (context) => DeleteOptionsDialog(
        isMyMessage: isMyMessage,
        message: message,
        onDelete: onDelete,
      ),
    );
  }
}

class DeleteOptionsDialog extends StatelessWidget {
  final bool isMyMessage;
  final Message message;
  final Function(bool) onDelete;

  const DeleteOptionsDialog({
    super.key,
    required this.isMyMessage,
    required this.message,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.trash,
                      size: 30,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to delete this message',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Column(
              children: [
                // Delete for me
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.user,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text('Delete for me'),
                  subtitle: const Text('Remove this message from your chat'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete(false);
                  },
                ),

                // Delete for everyone (only for my messages)
                if (isMyMessage)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.people,
                        size: 20,
                        color: Colors.red.shade600,
                      ),
                    ),
                    title: const Text('Delete for everyone'),
                    subtitle: const Text('Remove this message for all chat members'),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete(true);
                    },
                  ),
              ],
            ),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class EditMessageDialog extends StatefulWidget {
  final String initialContent;
  final Function(String) onSave;
  final Function() onCancel;

  const EditMessageDialog({
    Key? key,
    required this.initialContent,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  _EditMessageDialogState createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500, minWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: 'Edit your message...',
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    widget.onSave(value.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press Enter to save changes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => widget.onSave(_controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}