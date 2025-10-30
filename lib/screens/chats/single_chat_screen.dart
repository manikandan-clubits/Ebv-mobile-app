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
  final TextEditingController _messageController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  List<PlatformFile> _selectedFiles = [];
  List urls = [];
  bool _isMounted = false;
  bool _isUploading = false;
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    _messageController.addListener(() {
      setState(() {
        _showSendButton = _messageController.text.trim().isNotEmpty;
      });
    });

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
    _messageFocusNode.dispose();
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

  Widget _buildMessage(Message message) {
    final isMe = message.senderID == widget.chat?.userID;

    return MessageBubble(
      message: message,
      isMe: isMe,
      showAvatar: true,
      showTime: true,
    );
  }

  Widget _buildSelectedFilesPreview() {
    if (_selectedFiles.isEmpty) return const SizedBox();
    final chatState = ref.watch(chatProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.attach_square,
                  size: 18,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Attachments (${_selectedFiles.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
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
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                return _buildFilePreview(file, index);
              },
            ),
          ),
        ],
      ),
    );
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
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'png'],
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
      print("Failed to pick documents");
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


  Widget _buildFilePreview(PlatformFile file, int index) {
    final isImage = _isImageFile(file.name);
    final fileSize = _formatFileSize(file.size);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 120,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getFileColor(_getFileExtension(file.name)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          _getFileIcon(_getFileExtension(file.name)),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  file.name.length > 12
                      ? '${file.name.substring(0, 10)}...'
                      : file.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFiles.removeAt(index);
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
  }

  // Helper methods for file handling
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
        return Iconsax.document;
      case 'doc':
      case 'docx':
        return Iconsax.document_text;
      case 'xls':
      case 'xlsx':
        return Iconsax.document_text;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Iconsax.gallery;
      case 'zip':
      case 'rar':
        return Iconsax.archive;
      default:
        return Iconsax.document;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
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
                    pickDocuments();
                    Navigator.pop(context);
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
                    openCamera(context);
                    Navigator.pop(context);
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
              top: 60,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  child: Center(
                    child: Text(
                      widget.chatName.isNotEmpty
                          ? widget.chatName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
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
                                  : Colors.grey.shade500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.chat!.isActive ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.chat!.isActive
                                  ? Colors.green.shade600
                                  : Colors.grey.shade600,
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
                      color: Colors.black87,
                    ),
                  ),
                  onPressed: () {},
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
                      color: Colors.black87,
                    ),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Messages
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
                : messages.isEmpty
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
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Send a message to start the conversation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
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
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(messages[index]);
                },
              ),
            ),
          ),

          // Selected Files Preview
          _buildSelectedFilesPreview(),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Attachment Button
                GestureDetector(
                  onTap: _showMediaOptions,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.add,
                      size: 20,
                      color: Colors.grey,
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
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Iconsax.emoji_happy,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Send Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _showSendButton ? 48 : 0,
                  height: 48,
                  child: FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Colors.deepPurple,
                    elevation: 0,
                    child: const Icon(
                      Iconsax.send_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}