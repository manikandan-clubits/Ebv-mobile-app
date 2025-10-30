import 'dart:convert';
import 'package:ebv/models/group_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../provider/chat_provider.dart';
import 'group_details.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

import 'package:path/path.dart' as path;


class GroupChatScreen extends ConsumerStatefulWidget {
  final GroupChat group;

  const GroupChatScreen({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<PlatformFile> _selectedFiles = [];
  bool _isMounted = false;
  bool _showSendButton = false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _scrollToBottom();

    _messageController.addListener(() {
      if (_isMounted) {
        setState(() {
          _showSendButton = _messageController.text.trim().isNotEmpty;
        });
      }
    });

    Future.microtask(() async {
      final chatNotifier = ref.read(chatProvider.notifier);
      await chatNotifier.loadGroupMessages(widget.group.groupID);
      await chatNotifier.loadGroupMembers(widget.group.groupID);

    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage() async{
    final message = _messageController.text.trim();
    List<dynamic> urls = [];
    if (message.isEmpty) return;

    if(_selectedFiles.isNotEmpty) {
      final fileUrl = await ref.read(chatProvider.notifier).uploadImage(_selectedFiles);
      urls.add(fileUrl);
    }

    final chatNotifier = ref.read(chatProvider.notifier);

    chatNotifier.sendGroupMessage(
      author: widget.group.groupName,
      uploadUrl: urls,
      selectedFiles: _selectedFiles,
      groupId: widget.group.groupID,
      content: message,
    );

    _selectedFiles.clear();
    _messageController.clear();
    _scrollToBottom();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  void _showGroupMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(
          group: widget.group,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message, bool isMe) {


    List<String>? getAttachments(GroupMessage msg) {
      if (msg.uploadedUrls.isNotEmpty) {
        return List<String>.from(msg.uploadedUrls);
      }

      if (msg.attachment.isNotEmpty) {
        try {
          final parsed = jsonDecode(msg.attachment);
          if (parsed is List) {
            return List<String>.from(parsed);
          } else if (parsed is String && parsed.isNotEmpty) {
            return [parsed];
          }
        } catch (e) {
          return [msg.attachment];
        }
      }

      return null;
    }

    final attachments = getAttachments(message);
    final hasAttachments = attachments != null && attachments.isNotEmpty;

    // Safe author handling
    final author = message.author ?? 'Unknown User';
    final authorInitial = author.isNotEmpty ? author.substring(0, 1).toUpperCase() : '?';

    // Safe content handling
    final content = message.content ?? '';
    final hasContent = content.isNotEmpty;

    // Safe timestamp handling
    final sentAt = message.sentAt ?? DateTime.now();
    final formattedTime = _formatMessageTime(sentAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                authorInitial,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurple : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        author,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMe ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (hasContent)
                    Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),

                  if (hasAttachments) ...[
                    if (hasContent) const SizedBox(height: 8),
                    Column(
                      children: attachments.map((url) {
                        if (isImageUrl(url)) {
                          return _buildImageAttachment(url);
                        } else {
                          return _buildFileAttachment(url);
                        }
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Make sure your _formatMessageTime method can handle DateTime
  String _formatMessageTime(DateTime dateTime) {
    // Add null safety to your time formatting method
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildImageAttachment(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImagePreview(imageUrl),
      child: Container(
        width: 200,
        height: 150,
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.grey),
                          SizedBox(height: 4),
                          Text(
                            'Failed to load',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(String fileUrl) {
    final fileName = getFileName(fileUrl);
    final isPdf = isPdfUrl(fileUrl);

    return GestureDetector(
      onTap: () => viewFiles(fileUrl),
      child: Container(
        width: 200,
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPdf ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                color: isPdf ? Colors.red : Colors.blue,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    isPdf ? 'PDF Document' : 'File',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isImageUrl(String url) {
    final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  // Check if URL is a PDF
  bool isPdfUrl(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  String getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      return pathSegments.isNotEmpty ? pathSegments.last : 'file';
    } catch (e) {
      return 'file';
    }
  }

  void viewFiles(String fileUrl) {
    if (isPdfUrl(fileUrl)) {
      _showPdfViewer(fileUrl);
    } else if (isImageUrl(fileUrl)) {
      _showImagePreview(fileUrl);
    } else {
      _showFileOptions(fileUrl);
    }
  }

  void _showPdfViewer(String pdfUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Preview File'),
            backgroundColor: Colors.white,
          ),
          body: FutureBuilder<File>(
            // You'll need to implement file downloading logic here
            // For now, using network URL directly
            future: _downloadFile(pdfUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text('Failed to load PDF'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewFiles(pdfUrl),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.hasData) {
                return SfPdfViewer.file(
                  snapshot.data!,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    print('PDF loaded successfully');
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    print('PDF load failed: ${details.error}');
                  },
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  scrollDirection: PdfScrollDirection.horizontal,
                );
              }
              return Center(child: Text('Unable to load PDF'));
            },
          ),
        ),
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFileOptions(String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Download'),
        content: Text('Would you like to download "${getFileName(fileUrl)}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(fileUrl);
            },
            child: Text('Download'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<File> _downloadFile(String url) async {
    try {
      if (url.isEmpty) {
        throw Exception('URL is empty');
      }
      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Your-App-Name/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      // Check if request was successful
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to download file');
      }

      // Check if response has content
      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      // Get temporary directory for storing the file
      final Directory tempDir = await getTemporaryDirectory();

      // Generate filename from URL or use a timestamp
      String fileName = _getFileNameFromUrl(url);

      // Create file path
      final String filePath = path.join(tempDir.path, fileName);
      final File file = File(filePath);

      // Write bytes to file
      await file.writeAsBytes(response.bodyBytes);

      // Verify file was created and has content
      if (!await file.exists()) {
        throw Exception('Failed to create file');
      }

      final fileLength = await file.length();
      if (fileLength == 0) {
        throw Exception('Downloaded file is empty');
      }

      print('File downloaded successfully: $filePath (${fileLength} bytes)');

      return file;

    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Network connection failed: ${e.message}');
    }
    catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String fileName = path.basename(uri.path);

      // If no filename in URL, generate one with timestamp
      if (fileName.isEmpty || fileName == '/') {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = _getFileExtensionFromUrl(url);
        fileName = 'download_$timestamp$extension';
      }

      return fileName;
    } catch (e) {
      // Fallback filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'download_$timestamp';
    }
  }

// Helper method to guess file extension from URL
  String _getFileExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.pdf')) return '.pdf';
    if (path.endsWith('.doc') || path.endsWith('.docx')) return '.doc';
    if (path.endsWith('.xls') || path.endsWith('.xlsx')) return '.xls';
    if (path.endsWith('.zip')) return '.zip';
    if (path.endsWith('.mp4')) return '.mp4';
    if (path.endsWith('.mp3')) return '.mp3';
    if (path.endsWith('.txt')) return '.txt';

    return ''; // No extension
  }


  Future<bool> _checkAndRequestPermission() async {
    try {
      var status = await Permission.storage.status;

      if (status.isGranted) return true;

      status = await Permission.storage.request();

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _showSettingsDialog();
      }

      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Storage permission is required to select files. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
                            color: chatState.isUpload ? Colors.blue.shade300 : Colors.green.shade300,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
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
                  leading: const Icon(Iconsax.document, color: Colors.deepPurple),
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


  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
          ),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        trailing: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final currentUserId = chatState.currentUserId;
    final groupMessages = chatState.groupMessages;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(top: 50, bottom: 16, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                // Group Profile
                GestureDetector(
                  onTap: _showGroupMembers,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.group.groupName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showGroupMembers,
                  child: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${chatState.groupMembers.length} members',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: chatState.grpMsgLoading
                ? _buildMemberShimmer()
                : groupMessages.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () async {
                await ref.read(chatProvider.notifier).loadGroupMessages(widget.group.groupID);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: groupMessages.length,
                itemBuilder: (context, index) {
                  final message = groupMessages[index];
                  final isMe = message.senderID == currentUserId;
                  return _buildMessageBubble(message, isMe);
                },
              ),
            ),
          ),


          _buildSelectedFilesPreview(),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.add, color: Colors.deepPurple),
                  onPressed: _showMediaOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _showSendButton ? Colors.deepPurple : Colors.grey,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _showSendButton ? _sendMessage : null,
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

