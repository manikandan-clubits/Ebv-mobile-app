import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../../models/chat_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.showTime = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

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

  // Check if URL is an image
  bool isImageUrl(String url) {
    final imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  // Check if URL is a PDF
  bool isPdfUrl(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  // Get file name from URL
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
            title: Text('view pdf'),
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
      // Validate URL
      if (url.isEmpty) {
        throw Exception('URL is empty');
      }

      print('Starting download: $url');

      // Create HTTP client with timeout
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

// Helper method to extract filename from URL
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
          color: widget.isMe ? Colors.deepPurple.shade50 : Colors.grey.shade50,
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

  String _getDayChipText(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return 'Today';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else {
      // Show day name for this week, otherwise show date
      final difference = today.difference(messageDay).inDays;
      if (difference < 7) {
        return DateFormat('EEEE').format(messageDate); // Monday, Tuesday, etc.
      } else {
        return DateFormat('MMM dd, yyyy').format(messageDate); // Jan 15, 2024
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachments = attachments != null && attachments!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: widget.isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [

              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [


                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isMe ? Colors.deepPurple.shade400 : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topRight: const Radius.circular(20),
                          topLeft: const Radius.circular(20),
                          bottomLeft: widget.isMe ? const Radius.circular(20) : const Radius.circular(4),
                          bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(20),
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
                          // Text content
                          if (widget.message.content.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                // Only make text tappable if it's a file path/URL
                                if (widget.message.content.contains('http') ||
                                    widget.message.content.contains('.pdf') ||
                                    widget.message.content.contains('.png') ||
                                    widget.message.content.contains('.jpg')) {
                                  viewFiles(widget.message.content);
                                }
                              },
                              child: Text(
                                widget.message.content,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: widget.isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                          // Attachments
                          if (hasAttachments) ...[
                            if (widget.message.content.isNotEmpty) const SizedBox(height: 8),
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

                          // Timestamp and status
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(widget.message.sentAt.toLocal()),
                                  style: TextStyle(
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                                if (widget.isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.message.isSeenByReceiver
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 12,
                                    color: widget.message.isSeenByReceiver
                                        ? Colors.blue
                                        : Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delivery status for received messages (below bubble)
                    if (!widget.isMe && widget.showTime)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, right: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.message.isSeenByReceiver ? 'Seen' : 'Delivered',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              widget.message.isSeenByReceiver ? Icons.done_all : Icons.done,
                              size: 12,
                              color: widget.message.isSeenByReceiver ? Colors.blue : Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}