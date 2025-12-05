import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../../models/chat_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool showTime;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool showReply;
  final Message? repliedMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.showTime = true,
    this.onLongPress,
    this.onTap,
    this.showReply = false,
    this.repliedMessage,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // Loading states
  bool _isContentLoading = false;
  bool _areAttachmentsLoading = false;
  final Map<String, bool> _attachmentLoadingStates = {};
  final Map<String, File?> _downloadedFiles = {};

  @override
  void initState() {
    super.initState();
    _initializeMessage();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _initializeMessage();
    }
  }

  void _initializeMessage() {
    // Reset loading states
    _isContentLoading = false;
    _areAttachmentsLoading = false;
    _attachmentLoadingStates.clear();

    // Pre-load attachments if any
    if (attachments != null && attachments!.isNotEmpty) {
      _preloadAttachments();
    }
  }

  void _preloadAttachments() async {
    setState(() {
      _areAttachmentsLoading = true;
    });

    for (final url in attachments!) {
      _attachmentLoadingStates[url] = true;

      // Pre-load images for better UX
      if (isImageUrl(url)) {
        try {
          await _precacheImage(url);
        } catch (e) {
          print('Failed to preload image: $e');
        }
      }

      // Pre-download files that might be viewed
      if (isPdfUrl(url) || isDocumentUrl(url)) {
        _downloadFile(url).then((file) {
          if (mounted) {
            setState(() {
              _downloadedFiles[url] = file;
              _attachmentLoadingStates[url] = false;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _attachmentLoadingStates[url] = false;
            });
          }
        });
      } else {
        setState(() {
          _attachmentLoadingStates[url] = false;
        });
      }
    }

    if (mounted) {
      setState(() {
        _areAttachmentsLoading = false;
      });
    }
  }

  Future<void> _precacheImage(String imageUrl) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      await precacheImage(imageProvider, context);
    } catch (e) {
      print('Image precaching failed: $e');
    }
  }

  List<dynamic>? get attachments {
    if (widget.message.uploadedUrls.isNotEmpty) {
      return widget.message.uploadedUrls;
    }

    if (widget.message.attachment.isNotEmpty) {
      try {
        final parsed = jsonDecode(widget.message.attachment);
        if (parsed is List) {
          return List<String>.from(parsed);
        } else if (parsed is String && parsed.isNotEmpty) {
          return [parsed];
        }
      } catch (e) {
        return [widget.message.attachment];
      }
    }

    return null;
  }

  bool isImageUrl(String url) {
    final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool isPdfUrl(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  bool isDocumentUrl(String url) {
    final docExtensions = [
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt'
    ];
    final lowerUrl = url.toLowerCase();
    return docExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool isExcelUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx');
  }

  bool isWordUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.doc') || lowerUrl.contains('.docx');
  }

  bool isTextUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.txt');
  }

  bool isPowerPointUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx');
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

  void viewFiles(String fileUrl) async {
    if (_attachmentLoadingStates[fileUrl] == true) {
      _showLoadingDialog('Preparing file...');
      return;
    }

    final String fileExtension = _getFileExtension(fileUrl).toLowerCase();

    switch (fileExtension) {
      case 'pdf':
        _showPdfViewer(fileUrl);
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        _showImagePreview(fileUrl);
        break;
      case 'xls':
      case 'xlsx':
      case 'doc':
      case 'docx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        _openDocumentFile(fileUrl);
        break;
      default:
        _showFileOptions(fileUrl);
        break;
    }
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return '';

      final filename = pathSegments.last;
      final dotIndex = filename.lastIndexOf('.');

      if (dotIndex != -1 && dotIndex < filename.length - 1) {
        return filename.substring(dotIndex + 1);
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  void _showPdfViewer(String pdfUrl) {
    final preDownloadedFile = _downloadedFiles[pdfUrl];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(
                title: Text('PDF Viewer'),
                backgroundColor: Colors.white,
              ),
              body: preDownloadedFile != null
                  ? _buildPdfViewer(preDownloadedFile)
                  : FutureBuilder<File>(
                future: _downloadFile(pdfUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState('Loading PDF...');
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      'Failed to load PDF',
                      onRetry: () => viewFiles(pdfUrl),
                    );
                  }
                  if (snapshot.hasData) {
                    return _buildPdfViewer(snapshot.data!);
                  }
                  return _buildErrorState('Unable to load PDF');
                },
              ),
            ),
      ),
    );
  }

  Widget _buildPdfViewer(File file) {
    return SfPdfViewer.file(
      file,
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

  void _showImagePreview(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: FutureBuilder<void>(
                future: _precacheImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState('Loading image...');
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      'Failed to load image',
                      onRetry: () => viewFiles(imageUrl),
                    );
                  }
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildErrorState(
                            'Failed to load image',
                            onRetry: () => viewFiles(imageUrl),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }

  Future<void> _openDocumentFile(String fileUrl) async {
    try {
      _showLoadingDialog('Opening document...');

      // Check storage permission
      final permissionStatus = await Permission.storage.status;
      if (!permissionStatus.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          Navigator.pop(context);
          _showPermissionDeniedDialog();
          return;
        }
      }

      // Download the file
      final file = await _downloadFile(fileUrl);
      Navigator.pop(context); // Close loading dialog

      // Open with default app
      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done) {
        _showOpenFileError(result.message);
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Error opening document: $e');
    }
  }

  void _showFileOptions(String fileUrl) {
    final fileName = getFileName(fileUrl);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('File Options'),
            content: Text('What would you like to do with "$fileName"?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadFileWithProgress(fileUrl);
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Permission Required'),
            content: Text('Storage permission is required to open files.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  void _showOpenFileError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot open file: $message'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _downloadFileWithProgress(String url) async {
    _showLoadingDialog('Downloading file...');

    try {
      final file = await _downloadFile(url);
      Navigator.of(context).pop(); // Close loading dialog

      _showDownloadSuccessDialog(file.path);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Download failed: $e');
    }
  }

  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Download Complete'),
            content: Text('File saved successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
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

      print('Starting download: $url');

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Your-App-Name/1.0'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to download file');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = _getFileNameFromUrl(url);
      final String filePath = path.join(tempDir.path, fileName);
      final File file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      if (!await file.exists()) {
        throw Exception('Failed to create file');
      }

      final fileLength = await file.length();
      if (fileLength == 0) {
        throw Exception('Downloaded file is empty');
      }

      print('File downloaded successfully: $filePath (${fileLength} bytes)');
      return file;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String fileName = path.basename(uri.path);

      if (fileName.isEmpty || fileName == '/') {
        final timestamp = DateTime
            .now()
            .millisecondsSinceEpoch;
        final extension = _getFileExtensionFromUrl(url);
        fileName = 'download_$timestamp$extension';
      }

      return fileName;
    } catch (e) {
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      return 'download_$timestamp';
    }
  }

  String _getFileExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.pdf')) return '.pdf';
    if (path.endsWith('.doc') || path.endsWith('.docx')) return '.doc';
    if (path.endsWith('.xls') || path.endsWith('.xlsx')) return '.xls';
    if (path.endsWith('.ppt') || path.endsWith('.pptx')) return '.ppt';
    if (path.endsWith('.txt')) return '.txt';

    return '';
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(message),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageAttachment(String imageUrl) {
    final isLoading = _attachmentLoadingStates[imageUrl] ?? false;

    return GestureDetector(
      onTap: isLoading ? null : () => _showImagePreview(imageUrl),
      child: Container(
        width: 220,
        height: 160,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (isLoading)
                _buildAttachmentLoadingState()
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildImageLoadingProgress(loadingProgress);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAttachmentErrorState();
                  },
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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
    final isLoading = _attachmentLoadingStates[fileUrl] ?? false;
    final isDownloaded = _downloadedFiles.containsKey(fileUrl);

    return GestureDetector(
      onTap: isLoading ? null : () => viewFiles(fileUrl),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.deepPurple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                  color: isPdf ? Colors.red : Colors.blue,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: widget.isMe ? Colors.deepPurple : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isLoading)
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    if (isDownloaded)
                      Text(
                        'Ready to view',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      )
                    else
                      Text(
                        isPdf ? 'PDF Document' : 'File',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isMe
                              ? Colors.deepPurple.shade600
                              : Colors.grey.shade600,
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

  Widget _buildAttachmentLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoadingProgress(ImageChunkEvent loadingProgress) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
              loadingProgress.expectedTotalBytes!
              : null,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildAttachmentErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyIndicator() {
    if (!widget.showReply || widget.repliedMessage == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Colors.deepPurple,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 16, color: Colors.deepPurple),
              SizedBox(width: 4),
              Text(
                'Replying to ${widget.repliedMessage!.senderID ==
                    widget.message.senderID ? 'yourself' : 'User'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            widget.repliedMessage!.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachments = attachments != null && attachments!.isNotEmpty;
    final isMessageLoading = _areAttachmentsLoading;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: widget.isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (isMessageLoading)
                    _buildMessageLoadingIndicator(),

                  if (widget.showReply && widget.repliedMessage != null)
                    _buildReplyIndicator(),

                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery
                          .of(context)
                          .size
                          .width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.deepPurple : Colors.grey
                          .shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: widget.isMe ? Radius.circular(20) : Radius
                            .circular(4),
                        bottomRight: widget.isMe ? Radius.circular(4) : Radius
                            .circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: widget.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [

                        // Message content
                        if (widget.message.content.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              if (widget.message.content.contains('http') ||
                                  widget.message.content.contains('.pdf') ||
                                  widget.message.content.contains('.png') ||
                                  widget.message.content.contains('.jpg')) {
                                viewFiles(widget.message.content);
                              }
                            },
                            child: Text(
                              widget.message.content,
                              style: TextStyle(
                                color: widget.isMe ? Colors.white : Colors
                                    .black87,
                                fontSize: 16,
                              ),
                            ),
                          ),

                        if (hasAttachments) ...[
                          if (widget.message.content.isNotEmpty) const SizedBox(
                              height: 8),
                          Column(
                            children: attachments!.map((url) {
                              if (isImageUrl(url)) {
                                return _buildImageAttachment(url);
                              } else {
                                return _buildFileAttachment(url);
                              }
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Time and status row
                  if (widget.showTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: widget.isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(widget.message.sentAt
                                .toLocal()),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (widget.isMe) ...[
                            SizedBox(width: 4),
                            Icon(
                              widget.message.isSeenByReceiver
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 12,
                              color: widget.message.isSeenByReceiver
                                  ? Colors.blue
                                  : Colors.grey.shade500,
                            ),
                          ],

                        ],
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

  Widget _buildMessageLoadingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Loading attachments...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}


