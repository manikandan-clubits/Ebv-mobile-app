import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../models/chat_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../services/encrption_service.dart';
import '../services/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_services.dart';
import 'package:flutter/material.dart';
import 'chat_encrpt_provider.dart';
import '../services/encryptions.dart';

class ChatState {
  final List<ChatUser> chats;
  final List<Message> messages;
  final List<GroupChat> groups;
  final List<GroupMessage> groupMessages;
  final List<GroupMember> groupMembers;
  final bool isLoading;
  final bool isUpload;
  final bool chatListLoading;
  final bool chatMsgLoading;
  final bool grpMsgLoading;
  final bool grpListLoading;
  final String? currentChatId;
  final String? currentUserName;
  final int? currentUserId;
  final int? currentGroupId;
  final bool isConnected;
  final String? error;
  final bool isCreatingGroup;
  final bool isLoadingMember;

  ChatState({
    this.chats = const [],
    this.messages = const [],
    this.groups = const [],
    this.groupMessages = const [],
    this.groupMembers = const [],
    this.isLoading = false,
    this.isUpload = false,
    this.grpMsgLoading = false,
    this.chatListLoading = false,
    this.chatMsgLoading = false,
    this.grpListLoading = false,
    this.currentChatId,
    this.currentUserName,
    this.currentUserId,
    this.currentGroupId,
    this.isConnected = false,
    this.error,
    this.isCreatingGroup = false,
    this.isLoadingMember = false,
  });

  ChatState copyWith({
    List<ChatUser>? chats,
    List<Message>? messages,
    List<GroupChat>? groups,
    List<GroupMessage>? groupMessages,
    List<GroupMember>? groupMembers,
    bool? isLoading,
    bool? isUpload,
    bool? chatListLoading,
    bool? grpMsgLoading,
    bool? chatMsgLoading,
    bool? grpListLoading,
    String? currentChatId,
    String? currentUserName,
    int? currentUserId,
    int? currentGroupId,
    bool? isConnected,
    String? error,
    bool? isCreatingGroup,
    bool? isLoadingMember,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      groups: groups ?? this.groups,
      groupMessages: groupMessages ?? this.groupMessages,
      groupMembers: groupMembers ?? this.groupMembers,
      isLoading: isLoading ?? this.isLoading,
      isUpload: isUpload ?? this.isUpload,
      grpMsgLoading: grpMsgLoading ?? this.grpMsgLoading,
      chatListLoading: chatListLoading ?? this.chatListLoading,
      chatMsgLoading: chatMsgLoading ?? this.chatMsgLoading,
      grpListLoading: grpListLoading ?? this.grpListLoading,
      currentChatId: currentChatId ?? this.currentChatId,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      currentGroupId: currentGroupId ?? this.currentGroupId,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      isCreatingGroup: isCreatingGroup ?? this.isCreatingGroup,
      isLoadingMember: isLoadingMember ?? this.isLoadingMember,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final SocketService socketService;
  late IO.Socket socket;
  int? _currentUserId;
  String? _currentChatId;
  String? _currentUserName;

  final EncryptServices _encryptionService = EncryptServices();

  ChatNotifier(this.ref, this.socketService) : super(ChatState()) {
    initializeSocket();
    loadSingleChatUsers();
  }

  Future<void> initializeSocket() async {
    await _getCurrentUserId();
    connectToSocket();
  }

  Future<void> _getCurrentUserId() async {
    _currentUserId = null;
    final userInfo = await StorageServices.read("userInfo");
    _currentUserId = userInfo?['UserId'];
    _currentUserName = userInfo?['userName'];
    state = state.copyWith(
        currentUserId: _currentUserId, currentUserName: _currentUserName);
  }

  void connectToSocket() {
    socket = IO.io(
      'https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );

    socket.onConnect((_) {
      log('Connected to server');
      state = state.copyWith(isConnected: true);

      if (_currentUserId != null) {
        socket.emit('join_user', {'userId': _currentUserId});
      }
    });

    socket.onDisconnect((_) {
      state = state.copyWith(isConnected: false);
    });

    socket.onConnectError((error) {
      state = state.copyWith(isConnected: false);
    });

    socket.on('receive_message', (data) {
      print("receiveMessage");
      _handleIncomingMessage(data);
    });

    socket.on('message_sent', (data) {
      print("Message sent confirmation: $data");
      _handleMessageSentConfirmation(data);
    });

    socket.on('message_delivered', (data) {
      _updateMessageDeliveryStatus(data['messageId'], isDelivered: true);
    });

    socket.on('message_read', (data) {
      _updateMessageDeliveryStatus(data['messageId'], isRead: true);
    });
  }

  @override
  void dispose() {
    leaveChat();
    socket.disconnect();
    super.dispose();
  }

  Message _mapToMessage(dynamic data) {
    log("data$data");
    if (data is! Map<String, dynamic>) {
      throw ArgumentError('Invalid message payload');
    }

    return Message(
      messageID: data['MessageID'] ??
          data['messageID'] ??
          DateTime.now().millisecondsSinceEpoch,
      senderID: data['SenderID'] ?? data['senderID'] ?? 0,
      receiverID: data['ReceiverID'] ?? data['receiverID'] ?? 0,
      content: data['Content'] ?? data['content'] ?? '',
      attachment: data['attachment'] ?? '',
      uploadedUrls: data['uploadedUrls'] ?? [],
      sentAt: data['SentAt'] != null
          ? DateTime.parse(data['SentAt'])
          : data['sentAt'] != null
          ? DateTime.parse(data['sentAt'])
          : DateTime.now(),
      isDeleted: data['IsDeleted'] ?? data['isDeleted'] ?? false,
      isPinned: data['IsPinned'] ?? data['isPinned'] ?? false,
      isSeenBySender: data['IsSeenBySender'] ?? data['isSeenBySender'] ?? true,
      isSeenByReceiver:
      data['IsSeenByReceiver'] ?? data['isSeenByReceiver'] ?? false,
      chatID: data['ChatID'] ?? data['chatID'],
      type: _stringToMessageType(data['type'] ?? 'text'),
      isGroup: data['isGroupChat'] ?? data['isGroup'] ?? false,
      iv: data['iv'],
      encryptedAesKeyForSender: data['encryptedAesKeyForSender'],
      encryptedAesKeyForReceiver: data['encryptedAesKeyForReceiver'],
      groupReceivers: data['groupReceiversKeys'] != null
          ? (data['groupReceiversKeys'] as List).map((e) => Map<String, String>.from(e)).toList()
          : null,
      isSending: data['isSending'] ?? false,
      error: data['error'],
    );
  }

  GroupMessage _mapToGroupMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ArgumentError('Invalid group message payload');
    }

    return GroupMessage(
      messageID: data['MessageID'] ?? data['messageID'] ?? 0,
      chatID: data['ChatID'] ??
          data['chatID'] ??
          data['groupID'] ??
          data['GroupID'] ??
          0,
      senderID: data['SenderID'] ?? data['senderID'] ?? 0,
      receiverID: data['ReceiverID'] ?? data['receiverID'],
      attachment: data['attachment'] ?? '',
      uploadedUrls: data['uploadedUrls'] ?? [],
      content: data['Content'] ?? data['content'] ?? '',
      sentAt: data['SentAt'] != null
          ? DateTime.parse(data['SentAt'])
          : data['sentAt'] != null
          ? DateTime.parse(data['sentAt'])
          : DateTime.now(),
      isDeleted: data['IsDeleted'] ?? data['isDeleted'] ?? false,
      isPinned: data['IsPinned'] ?? data['isPinned'] ?? false,
      isSeenBySender: data['IsSeenBySender'] ?? data['isSeenBySender'] ?? true,
      isSeenByReceiver:
      data['IsSeenByReceiver'] ?? data['isSeenByReceiver'] ?? false,
      groupID: data['groupID'] ?? data['GroupID'] ?? 0,
      isSeenAll: data['isSeenAll'] ?? data['IsSeenAll'] ?? 0,
      author: data['author'] ?? data['Author'] ?? 'Unknown',
      iv: data['iv'],
      encryptedAesKeyForSender: data['encryptedAesKeyForSender'],
      groupReceivers: data['groupReceiversKeys'] != null
          ? (data['groupReceiversKeys'] as List).map((e) => Map<String, String>.from(e)).toList()
          : null,
    );
  }

  Future<List<Map<String, dynamic>>> _prepareFiles(
      List<PlatformFile> selectedFiles) async {
    final preparedFiles = <Map<String, dynamic>>[];

    for (final file in selectedFiles) {
      final base64Data = await fileToBase64(file);

      preparedFiles.add({
        'fileName': file.name,
        'fileData': base64Data,
        'fileType': _getMimeType(file),
      });
    }

    return preparedFiles;
  }

  Future<void> _handleIncomingMessage(dynamic data) async {
    try {
      print("Processing incoming message: ${data.toString()}");
      final chatKeysState = ref.read(chatKeysProvider);
      final senderPrivateKey = chatKeysState.senderKeys?.privateKey;
      final currentUserId = state.currentUserId;

      if (senderPrivateKey == null) {
        print('Missing sender private key. Cannot decrypt message.');
        return;
      }

      if (currentUserId == null) {
        print('Missing current user ID. Cannot decrypt message.');
        return;
      }

      // Convert data to Message object
      final Map<String, dynamic> messageMap = Map<String, dynamic>.from(data);
      print("messageMap: $messageMap");

      Message message = Message.fromJson(messageMap);
      var decryptedContent;

      // Check if message is encrypted
      final isEncrypted = message.iv != null &&
          (message.encryptedAesKeyForSender != null ||
              message.encryptedAesKeyForReceiver != null ||
              message.groupReceivers != null);

      if (!isEncrypted) {
        print('Message is not encrypted, using original content');
        decryptedContent = message.content;
      } else {
        // Decrypt the message content based on chat type
        if (!message.isGroup) {
          print('Decrypting individual message');
          print("senderPrivateKey$senderPrivateKey");
          print("currentUserId$currentUserId");
          decryptedContent = await EncryptServices.decryptMessage(
            message,
            senderPrivateKey,
            currentUserId,
          );
        } else {
          print('Decrypting group message');
          decryptedContent = await EncryptServices.decryptMessageGroup(
            messageData: message,
            privateKeyRef: senderPrivateKey,
            currentUserId: currentUserId,
          );
        }
      }

      // Update message with decrypted content
      final decryptedMessage = Message(
        messageID: message.messageID,
        senderID: message.senderID,
        receiverID: message.receiverID,
        content: decryptedContent['text'],
        attachment: message.attachment,
        uploadedUrls: message.uploadedUrls,
        sentAt: message.sentAt,
        isDeleted: message.isDeleted,
        isPinned: message.isPinned,
        isSeenBySender: message.isSeenBySender,
        isSeenByReceiver: message.isSeenByReceiver,
        chatID: message.chatID,
        type: message.type,
        isGroup: message.isGroup,
        iv: message.iv,
        encryptedAesKeyForSender: message.encryptedAesKeyForSender,
        encryptedAesKeyForReceiver: message.encryptedAesKeyForReceiver,
        groupReceivers: message.groupReceivers,
        isSending: false,
        error: null,
      );

      if (message.isGroup) {
        _handleGroupMessage(decryptedMessage);
      } else {
        _handleIndividualMessage(decryptedMessage);
      }
    } catch (e, stackTrace) {
      log('Error processing received message: $e');
      log('Stack trace: $stackTrace');
      state = state.copyWith(
        error: 'Failed to process incoming message: ${e.toString()}',
      );
    }
  }

  void _handleIndividualMessage(Message message) {
    try {
      _addMessageToState(message, prepend: true);
    } catch (e, stackTrace) {
      log('Error processing individual message: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _handleGroupMessage(Message message) {
    try {
      _addMessageToState(message, prepend: true);
    } catch (e, stackTrace) {
      log('Error processing group message: $e');
      log('Stack trace: $stackTrace');
    }
  }

  // Update the loadMessages method to handle decryption properly
  Future<void> loadMessages(String chatId, int userId) async {
    _currentChatId = chatId;
    state = state.copyWith(
        chatMsgLoading: true, currentChatId: chatId, error: null);

    try {
      // Join chat via socket
      socket.emit('join_chat', {
        'chatId': chatId,
        'userId': _currentUserId,
      });

      final response = await ApiService()
          .post('/chat/messages/singlelist', {"SelectedUserId": userId});

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }

      // Decrypt the main response
      final result = ApiService().decryptData(encryptedData, iv);
      if (result != null && result is List) {
        List<Message> messagesList =
        (result).map((m) => Message.fromJson(m)).toList();
        final chatKeysState = ref.read(chatKeysProvider);

        List<Message> decryptedMessages =
        await Future.wait(messagesList.map((message) async {
          try {
            final decryptedContent = await EncryptServices.decryptMessage(
              message,
              chatKeysState.senderKeys?.privateKey,
              state.currentUserId,
            );
            log("Decrypted content${decryptedContent['text']}");
            return Message(
              messageID: message.messageID,
              senderID: message.senderID,
              receiverID: message.receiverID,
              content: decryptedContent['text'],
              attachment: message.attachment,
              uploadedUrls: message.uploadedUrls,
              sentAt: message.sentAt,
              isDeleted: message.isDeleted,
              isPinned: message.isPinned,
              isSeenBySender: message.isSeenBySender,
              isSeenByReceiver: message.isSeenByReceiver,
              chatID: message.chatID,
              type: message.type,
              isGroup: message.isGroup,
              iv: message.iv,
              encryptedAesKeyForSender: message.encryptedAesKeyForSender,
              encryptedAesKeyForReceiver: message.encryptedAesKeyForReceiver,
              groupReceivers: message.groupReceivers,
              isSending: false,
              error: null,
            );
          } catch (e) {
            return message; // Return original message if decryption fails
          }
        }));

        decryptedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

        // Update state
        state = state.copyWith(
          messages: decryptedMessages,
          chatMsgLoading: false,
          error: null,
        );

        markMessagesAsRead(chatId);
      } else {
        throw Exception('Failed to decrypt response data');
      }
    } catch (error) {
      log('Error loading messages: $error');
      state = state.copyWith(
        chatMsgLoading: false,
        error: 'Failed to load messages: ${error.toString()}',
      );
    }
  }

  void _addMessageToState(Message message, {bool prepend = true}) {
    if (message.chatID == null && !message.isGroup) {
      return;
    }

    final existingMessageIndex =
    state.messages.indexWhere((m) => m.messageID == message.messageID);

    if (existingMessageIndex != -1) {
      final updatedMessages = List<Message>.from(state.messages);
      updatedMessages[existingMessageIndex] = message;
      state = state.copyWith(messages: updatedMessages);
    } else {
      final updatedMessages = List<Message>.from(state.messages);
      if (prepend) {
        updatedMessages.insert(0, message);
      } else {
        updatedMessages.add(message);
      }
      updatedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      state = state.copyWith(messages: updatedMessages);
    }
  }

  void _addGroupMessageToState(GroupMessage message) {
    final existingIndex =
    state.groupMessages.indexWhere((m) => m.messageID == message.messageID);

    if (existingIndex != -1) {
      final updatedMessages = List<GroupMessage>.from(state.groupMessages);
      updatedMessages[existingIndex] = message;
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      state = state.copyWith(groupMessages: updatedMessages);
    } else {
      final updatedMessages = List<GroupMessage>.from(state.groupMessages);
      _insertMessageChronological(updatedMessages, message);
      state = state.copyWith(groupMessages: updatedMessages);
    }
  }

  MessageType _stringToMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'document':
        return MessageType.document;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  void _insertMessageChronological(
      List<GroupMessage> messages, GroupMessage newMessage) {
    int low = 0;
    int high = messages.length;

    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (newMessage.sentAt.compareTo(messages[mid].sentAt) < 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    messages.insert(low, newMessage);
  }

  Future<void> loadSingleChatUsers() async {
    state = state.copyWith(chatListLoading: true, error: null);
    try {
      final response = await ApiService().get('/chat/users/list', {});

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }

      final res = ApiService().decryptData(encryptedData, iv);

      if (res != null) {
        List<dynamic> usersData;
        if (res is Map && res.containsKey('userList')) {
          usersData = res['userList'] as List;
        } else if (res is List) {
          usersData = res;
        } else {
          throw Exception('Unexpected response format: ${res.runtimeType}');
        }
        print("usersData$usersData");

        final users =
        usersData.map((userData) => ChatUser.fromJson(userData)).toList();
        state =
            state.copyWith(chats: users, chatListLoading: false, error: null);
      } else {
        throw Exception('Failed to decrypt response data');
      }
    } catch (error) {
      log('Error loading chats: $error');
      state = state.copyWith(
          chatListLoading: false,
          error: 'Failed to load chats: ${error.toString()}');
    }
  }

  Future<void> sendMessage({
    required String author,
    required List<dynamic> uploadUrl,
    required String content,
    required MessageType type,
    List<PlatformFile>? selectedFiles,
    int? receiverId,
    int? groupId,
    int? chatId,
    required String currentUserId,
  }) async {
    try {
      final bool isGroupChat = groupId != null;
      final combinedContent = content;

      // Check if we have content to send
      if (combinedContent.trim().isEmpty && (uploadUrl.isEmpty)) {
        print('No content to send');
        return;
      }

      // Get encryption keys from global state
      final chatKeysState = ref.read(chatKeysProvider);
      final senderPublicKey = chatKeysState.senderKeys?.publicKey;
      final senderPrivateKey = chatKeysState.senderKeys?.privateKey;

      // Create temporary message for instant display
      final tempMessageId = DateTime.now().millisecondsSinceEpoch;

      // Create initial unencrypted message for immediate display
      Message tempMessage = Message(
        messageID: tempMessageId,
        senderID: int.parse(currentUserId),
        receiverID: isGroupChat ? int.parse(currentUserId) : receiverId!,
        content: combinedContent,
        attachment: '',
        uploadedUrls: uploadUrl,
        sentAt: DateTime.now(),
        isDeleted: false,
        isPinned: false,
        isSeenBySender: true,
        isSeenByReceiver: false,
        chatID: chatId,
        type: type,
        isGroup: isGroupChat,
        isSending: true, // Flag to show sending state
      );

      print("Temporary message created: ${tempMessage.toJson()}");

      // 1. FIRST: Add message to local state immediately for instant display
      _addMessageToState(tempMessage, prepend: true);

      Map<String, dynamic> messageData = {
        "author": author,
        "receiverID": isGroupChat ? currentUserId : receiverId,
        "groupID": isGroupChat ? groupId : '',
        "SenderID": currentUserId,
        "Content": combinedContent,
        "SentAt": DateTime.now().toIso8601String(),
        "IsDeleted": false,
        "IsPinned": false,
        "isGroupChat": isGroupChat,
        "uploadedUrls": uploadUrl,
        "error": '',
        "tempMessageId": tempMessageId, // Send temp ID for confirmation
        if (!isGroupChat && chatId != null) "chatID": chatId,
      };

      print("Initial messageData: $messageData");

      // Handle encryption based on message type
      if (!isGroupChat) {
        // Individual message encryption
        if (receiverId == null) {
          throw ArgumentError('receiverId is required for individual messages');
        }

        print("receiverId$receiverId");

        final receiverPublicKey = ref.read(chatKeysProvider.notifier).getReceiverPublicKey(receiverId.toString());

        print("receiverPublicKey$receiverPublicKey");

        if (receiverPublicKey == null || senderPublicKey == null || senderPrivateKey == null) {
          // Update message to show error state
          _updateMessageStatus(tempMessageId, false, 'Missing encryption keys');
          throw Exception('Missing encryption keys. Message not sent.');
        }

        final encryptedMessage = await EncryptServices.encryptMessage(
          content: combinedContent,
          publicKeyRef: senderPublicKey,
          receiverPubKeyRef: receiverPublicKey,
          senderId: currentUserId,
          receiverId: receiverId.toString(),
        );

        print("Encrypted message: $encryptedMessage");

        // Update message data with encrypted content
        messageData['Content'] = encryptedMessage.encryptedText;
        messageData['iv'] = encryptedMessage.iv;
        messageData['encryptedAesKeyForSender'] = encryptedMessage.encryptedAesKeyForSender;
        messageData['encryptedAesKeyForReceiver'] = encryptedMessage.encryptedAesKeyForReceiver;

      } else {
        // Group message encryption
        final groupPublicKeys = <GroupPublicKey>[]; // Get from your group provider

        if (groupPublicKeys.isEmpty) {
          _updateMessageStatus(tempMessageId, false, 'Missing group public keys');
          throw Exception('Missing group public keys. Message not sent.');
        }

        final encryptedMessage = await EncryptServices.encryptMessageGroup(
          content: combinedContent,
          publicKeyRef: senderPublicKey.toString(),
          groupReceivers: groupPublicKeys,
          groupId: groupId.toString(),
          senderId: currentUserId,
        );

        print("Group encrypted message: $encryptedMessage");

        // Update message data with encrypted content
        messageData['Content'] = encryptedMessage.encryptedText;
        messageData['iv'] = encryptedMessage.iv;
        messageData['encryptedAesKeyForSender'] = encryptedMessage.encryptedAesKeyForSender;
        messageData['groupReceiversKeys'] = encryptedMessage.groupReceivers;
      }

      // Prepare files if any
      List<Map<String, dynamic>>? formDataList;
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        formDataList = await _prepareFiles(selectedFiles);
      }

      print("Sending encrypted message data: $messageData");

      // Emit via socket
      socket.emit('send_message', messageData);

    } catch (error) {
      log('Send message error: $error');

      // Update message to show error state
      final tempMessageId = DateTime.now().millisecondsSinceEpoch;
      _updateMessageStatus(tempMessageId, false, error.toString());

      state = state.copyWith(
        error: 'Failed to send message: ${error.toString()}',
      );
      rethrow;
    }
  }

  void _updateMessageStatus(int messageId, bool isSent, String? error) {
    final updatedMessages = state.messages.map((message) {
      if (message.messageID == messageId) {
        return message.copyWith(
          isSending: !isSent,
          error: error,
        );
      }
      return message;
    }).toList();

    state = state.copyWith(
      messages: updatedMessages,
      error: error,
    );
  }

  void _handleMessageSentConfirmation(Map<String, dynamic> data) {
    final serverMessageId = data['MessageID'];
    final tempMessageId = data['tempMessageId'];

    if (serverMessageId != null && tempMessageId != null) {
      final updatedMessages = state.messages.map((message) {
        if (message.messageID == tempMessageId) {
          return message.copyWith(
            messageID: serverMessageId,
            isSending: false,
            error: null,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    }
  }

  typingMessage() {
    final messageData = {
      "senderID": _currentUserId,
      "senderName": "",
      "receiverID": _currentUserId,
      "receiverName": "",
      "groupID": null,
      "isGroupChat": false,
    };
    socket.emit('typing', messageData);
  }

  stopTypingMessage(
      {required String author,
        required List<dynamic> uploadUrl,
        required String content,
        required int receiverId,
        required int chatId}) {
    final messageData = {
      "senderID": _currentUserId,
      "senderName": author,
      "receiverID": receiverId,
      "receiverName": "",
      "groupID": null,
      "isGroupChat": false,
    };
  }

  Future<String> fileToBase64(PlatformFile file) async {
    try {
      if (file.bytes != null) {
        final base64String = base64Encode(file.bytes!);
        return 'data:${file.extension ?? 'application/octet-stream'};base64,$base64String';
      } else if (file.path != null) {
        final fileData = await File(file.path!).readAsBytes();
        final base64String = base64Encode(fileData);
        return 'data:${file.extension ?? 'application/octet-stream'};base64,$base64String';
      } else {
        throw Exception('File has no bytes or path');
      }
    } catch (e) {
      throw Exception('Error converting file to base64: $e');
    }
  }

  String _getMimeType(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.document:
        return 'document';
      case MessageType.audio:
        return 'audio';
      default:
        return 'text';
    }
  }

  Message? getLatestMessageForChat(String chatId) {
    final chatMessages =
    state.messages.where((m) => m.chatID == chatId).toList();
    if (chatMessages.isEmpty) return null;

    chatMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return chatMessages.first;
  }

  int getUnreadMessageCount(String chatId) {
    return state.messages
        .where((m) =>
    m.chatID == chatId &&
        m.receiverID == _currentUserId &&
        !m.isSeenByReceiver)
        .length;
  }

  void markMessagesAsRead(String chatId) {
    final updatedMessages = state.messages.map((message) {
      if (message.chatID == chatId &&
          message.receiverID == _currentUserId && !message.isSeenByReceiver) {
        return message.copyWith(
          isSeenByReceiver: true,
        );
      }
      return message;
    }).toList();

    state = state.copyWith(messages: updatedMessages);

    final chatIndex =
    state.chats.indexWhere((chat) => chat.chatID.toString() == chatId);
    if (chatIndex != -1) {
      final updatedChats = List<ChatUser>.from(state.chats);
      final oldChat = updatedChats[chatIndex];

      updatedChats[chatIndex] = ChatUser(
        userID: oldChat.userID,
        username: oldChat.username,
        email: oldChat.email,
        firstName: oldChat.firstName,
        lastName: oldChat.lastName,
        profilePicture: oldChat.profilePicture,
        status: oldChat.status,
        lastSeen: oldChat.lastSeen,
        isMaster: oldChat.isMaster,
        adminID: oldChat.adminID,
        isActive: oldChat.isActive,
        lastMessage: oldChat.lastMessage,
        lastMessageTime: oldChat.lastMessageTime,
        isSeenByReceiver: true,
        isSeenBySender: oldChat.isSeenBySender,
        chatID: oldChat.chatID,
        receiverID: oldChat.receiverID,
        messageID: oldChat.messageID,
        unreadCount: 0,
      );
      state = state.copyWith(chats: updatedChats);

      socket.emit('message_read', {
        'chatId': chatId,
        'messageIds': updatedMessages
            .where((m) => m.chatID == chatId && m.isSeenByReceiver)
            .map((m) => m.messageID)
            .toList(),
        'readerId': _currentUserId,
      });
    }
  }

  void leaveChat() {
    if (state.currentChatId != null) {
      socket.emit('leave_chat', {
        'chatId': state.currentChatId,
        'userId': _currentUserId,
      });
      _currentChatId = null;
      state = state.copyWith(currentChatId: null);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  // Group Chat Methods
  Future<void> loadGroups() async {
    state = state.copyWith(grpListLoading: true, error: null);
    try {
      final response = await ApiService().get('/chat/groups/list', {});

      if (response.statusCode == 404) {
        state = state.copyWith(
          groups: [],
          grpListLoading: false,
          error: null,
        );
        return;
      }

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        if (response.data.containsKey('groupList')) {
          final groupList = (response.data['groupList'] as List)
              .map((group) => GroupChat.fromJson(group))
              .toList();
          state = state.copyWith(
            groups: groupList,
            grpListLoading: false,
            error: null,
          );
          return;
        }
        throw Exception('Missing encrypted data or IV');
      }

      final decrypted =
      ApiService().decryptData(encryptedData as String, iv as String);

      if (decrypted is Map<String, dynamic>) {
        if (decrypted.containsKey('groupList')) {
          final groupResponse = GroupListResponse.fromJson(decrypted);
          state = state.copyWith(
            groups: groupResponse.groupList,
            grpListLoading: false,
            error: null,
          );
        } else {
          // Try direct list parsing
          final groups = (decrypted as List)
              .map((group) => GroupChat.fromJson(group))
              .toList();
          state = state.copyWith(
            groups: groups,
            grpListLoading: false,
            error: null,
          );
        }
      } else if (decrypted is List) {
        final groups =
        decrypted.map((group) => GroupChat.fromJson(group)).toList();
        state = state.copyWith(
          groups: groups,
          grpListLoading: false,
          error: null,
        );
      } else {
        throw Exception(
            'Unexpected group response format: ${decrypted.runtimeType}');
      }
    } catch (error) {
      log('Error loading groups: $error');
      state = state.copyWith(
        grpListLoading: false,
        error: 'Failed to load groups: ${error.toString()}',
      );
    }
  }

  Future<void> createGroup({
    required String groupName,
    required List<String> memberIds,
  }) async {
    state = state.copyWith(isCreatingGroup: true, error: null);
    try {
      final payload = {
        "GroupName": groupName,
        "Username": memberIds,
        "CreatedAt": DateTime.now().toIso8601String(),
        "CreatedBy": _currentUserId,
      };
      final response = await ApiService().post('/chat/groups/create', payload);

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      dynamic decrypted;
      if (encryptedData != null && iv != null) {
        decrypted =
            ApiService().decryptData(encryptedData as String, iv as String);
      } else {
        decrypted = response.data;
      }

      if (decrypted is Map<String, dynamic> && decrypted.containsKey('group')) {
        final newGroup = GroupChat.fromJson(decrypted['group']);
        final updatedGroups = List<GroupChat>.from(state.groups)
          ..insert(0, newGroup);
        state = state.copyWith(groups: updatedGroups, isCreatingGroup: false);
      } else {
        await loadGroups();
        state = state.copyWith(isCreatingGroup: false);
      }
    } catch (error) {
      log('Error creating group: $error');
      state = state.copyWith(
        isCreatingGroup: false,
        error: 'Failed to create group: ${error.toString()}',
      );
      rethrow;
    }
  }

  Future<void> addGrpMember({
    required int GroupID,
    required List<String> Usernames,
  }) async {
    state = state.copyWith(isLoadingMember: true, error: null);
    try {
      final payload = {
        "GroupID": GroupID,
        "Usernames": Usernames,
      };

      final response =
      await ApiService().post('/chat/groups/addusers', payload);
      if (response.data == null) {
        throw Exception('No response data received');
      }
    } catch (error) {
      state = state.copyWith(
        isLoadingMember: false,
      );
      rethrow;
    }
  }

  Future<void> loadGroupMessages(int groupId) async {
    state = state.copyWith(
      grpMsgLoading: true,
      currentGroupId: groupId,
      error: null,
    );

    try {
      final response = await ApiService().post('/chat/groups/messagelist', {
        "groupId": groupId,
        "userId": _currentUserId,
      });

      if (response.data == null) {
        throw Exception('No response data received');
      }

      if (response.statusCode == 404) {
        state = state.copyWith(
          groupMessages: [],
          grpMsgLoading: false,
          error: null,
        );
        return;
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      // Handle both encrypted and unencrypted responses
      dynamic decryptedData;
      if (encryptedData != null && iv != null) {
        decryptedData = ApiService().decryptData(encryptedData, iv);
      } else {
        // If no encryption, use the raw data
        decryptedData = response.data;
      }

      if (decryptedData != null) {
        List<dynamic> messagesData;

        // Extract the messages list from different possible response structures
        if (decryptedData is Map && decryptedData.containsKey('messageList')) {
          messagesData = decryptedData['messageList'] as List;
        } else if (decryptedData is Map && decryptedData.containsKey('messages')) {
          messagesData = decryptedData['messages'] as List;
        } else if (decryptedData is List) {
          messagesData = decryptedData;
        } else {
          throw Exception('Unexpected response format: ${decryptedData.runtimeType}');
        }

        // Safe conversion of messages data to GroupMessage objects
        List<GroupMessage> messagesList = messagesData.map((m) {
          try {
            Map<String, dynamic> messageJson;

            if (m is Map<String, dynamic>) {
              // If it's already Map<String, dynamic>, use it directly
              messageJson = m;
            } else if (m is Map) {
              // If it's a Map but not specifically Map<String, dynamic>, convert it
              messageJson = Map<String, dynamic>.from(m);
            } else if (m is String) {
              // If it's a string, try to parse it as JSON
              try {
                messageJson = Map<String, dynamic>.from(jsonDecode(m));
              } catch (e) {
                throw Exception('Failed to parse message string as JSON: $e');
              }
            } else {
              throw Exception('Unexpected message data type: ${m.runtimeType}');
            }

            return GroupMessage.fromJson(messageJson);
          } catch (e, stackTrace) {
            log('Error converting message data to GroupMessage: $e');
            log('Problematic data: $m');
            log('Stack trace: $stackTrace');

            // Return a default error message instead of crashing
            return GroupMessage(
              messageID: DateTime.now().millisecondsSinceEpoch,
              senderID: 0,
              content: 'Error loading message: ${e.toString()}',
              sentAt: DateTime.now(),
              isDeleted: false,
              isPinned: false,
              isSeenBySender: true,
              isSeenByReceiver: false,
              groupID: groupId,
              isSeenAll: 0,
              author: 'System',
            );
          }
        }).toList();

        final chatKeysState = ref.read(chatKeysProvider);
        final senderPrivateKey = chatKeysState.senderKeys?.privateKey;
        final currentUserId = state.currentUserId;

        // Decrypt each group message
        List<GroupMessage> decryptedMessages = await Future.wait(
          messagesList.map((groupMessage) async {
            try {
              // Check if message needs decryption
              final isEncrypted = groupMessage.iv != null &&
                  (groupMessage.encryptedAesKeyForSender != null ||
                      groupMessage.groupReceivers != null);

              if (!isEncrypted) {
                print('Group message ${groupMessage.messageID} is not encrypted');
                return groupMessage;
              }

              if (senderPrivateKey == null) {
                print('Missing private key for decryption');
                return groupMessage.copyWith(
                  content: '[Encrypted - No Key]',
                );
              }

              if (currentUserId == null) {
                print('Missing current user ID');
                return groupMessage.copyWith(
                  content: '[Encrypted - No User ID]',
                );
              }

              print('Decrypting group message ${groupMessage.messageID}');
              print('IV: ${groupMessage.iv}');
              print('Encrypted AES Key: ${groupMessage.encryptedAesKeyForSender}');
              print('Group Receivers: ${groupMessage.groupReceivers}');

              // Create a proper Message object for decryption
              final messageForDecryption = Message(
                messageID: groupMessage.messageID,
                senderID: groupMessage.senderID,
                receiverID: 0,
                content: groupMessage.content,
                attachment: groupMessage.attachment ?? '',
                uploadedUrls: _safeConvertUploadedUrls(groupMessage.uploadedUrls),
                sentAt: groupMessage.sentAt,
                isDeleted: groupMessage.isDeleted,
                isPinned: groupMessage.isPinned,
                isSeenBySender: groupMessage.isSeenBySender,
                isSeenByReceiver: groupMessage.isSeenByReceiver,
                chatID: groupMessage.chatID,
                type: MessageType.text,
                isGroup: true,
                iv: groupMessage.iv,
                encryptedAesKeyForSender: groupMessage.encryptedAesKeyForSender,
                groupReceivers: groupMessage.groupReceivers?.map((e) => Map<String, String>.from(e))
                    .toList(),
              );

              final decryptedContent = await EncryptServices.decryptMessageGroup(
                messageData: messageForDecryption,
                privateKeyRef: senderPrivateKey,
                currentUserId: currentUserId,
              );

              if (decryptedContent['text'] != null) {
                print('Successfully decrypted group message: ${decryptedContent['text']}');
                return groupMessage.copyWith(
                  content: decryptedContent['text'],
                );
              } else {
                print('Decryption returned null text');
                return groupMessage.copyWith(
                  content: '[Decryption Failed]',
                );
              }
            } catch (e, stackTrace) {
              log('Error decrypting group message ${groupMessage.messageID}: $e');
              log('Stack trace: $stackTrace');

              // Return the message with error indicator but keep original data
              return groupMessage.copyWith(
                content: '[Decryption Error: ${e.toString()}]',
              );
            }
          }),
        );

        // Sort messages chronologically (oldest first)
        decryptedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

        state = state.copyWith(
          groupMessages: decryptedMessages,
          grpMsgLoading: false,
          error: null,
        );

        print('Successfully loaded ${decryptedMessages.length} group messages');

      } else {
        throw Exception('Failed to process response data');
      }
    } catch (error, stackTrace) {
      log('Error loading group messages: $error');
      log('Stack trace: $stackTrace');

      state = state.copyWith(
        groupMessages: [],
        grpMsgLoading: false,
        error: 'Failed to load group messages: ${error.toString()}',
      );
    }
  }

// Helper method to safely convert uploadedUrls
  List<dynamic> _safeConvertUploadedUrls(dynamic uploadedUrls) {
    if (uploadedUrls == null) return [];
    if (uploadedUrls is List) return uploadedUrls;
    if (uploadedUrls is String) {
      try {
        final parsed = jsonDecode(uploadedUrls);
        if (parsed is List) return parsed;
        if (parsed is String) return [parsed];
      } catch (e) {
        return [uploadedUrls];
      }
    }
    return [];
  }

  Future<void> loadGroupMembers(int groupId) async {
    state = state.copyWith(groupMembers: [], isLoading: true, error: null);

    try {
      final response = await ApiService().post('/chat/groups/groupmembers', {
        'groupId': groupId,
      });

      if (response.statusCode == 404) {
        state = state.copyWith(
          groupMembers: [],
          isLoading: false,
          error: null,
        );
        return;
      }

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }
      final decrypted =
      ApiService().decryptData(encryptedData as String, iv as String);
      if (decrypted is List) {
        final membersList =
        decrypted.map((m) => GroupMember.fromJson(m)).toList();
        state = state.copyWith(
          groupMembers: membersList,
          isLoading: false,
          error: null,
        );
      } else if (decrypted is Map<String, dynamic> &&
          decrypted.containsKey('members')) {
        final members = decrypted['members'] as List<dynamic>;
        final membersList =
        members.map((m) => GroupMember.fromJson(m)).toList();
        state = state.copyWith(
          groupMembers: membersList,
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception(
            'Unexpected group members response format: ${decrypted.runtimeType}');
      }
    } catch (error) {
      log('Error loading group members: $error');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load group members: ${error.toString()}',
      );
    }
  }

  void clearGroupMessages() {
    state = state.copyWith(groupMessages: []);
  }

  void clearGroupMembers() {
    state = state.copyWith(groupMembers: []);
  }

  void clearGroupData() {
    state = state.copyWith(
      groupMessages: [],
      groupMembers: [],
      currentGroupId: null,
    );
  }

  void _updateMessageDeliveryStatus(dynamic messageId,
      {bool isDelivered = false, bool isRead = false}) {
    final messageIndex =
    state.messages.indexWhere((m) => m.messageID == messageId);
    if (messageIndex != -1) {
      final updatedMessages = List<Message>.from(state.messages);
      final oldMessage = updatedMessages[messageIndex];

      updatedMessages[messageIndex] = oldMessage.copyWith(
        isSeenBySender: isDelivered || isRead ? true : oldMessage.isSeenBySender,
        isSeenByReceiver: isRead ? true : oldMessage.isSeenByReceiver,
      );

      state = state.copyWith(messages: updatedMessages);
    }
  }

  Future<dio.MultipartFile> _platformFileToMultipartFile(
      PlatformFile platformFile) async {
    if (platformFile.bytes != null) {
      return dio.MultipartFile.fromBytes(
        platformFile.bytes!,
        filename: platformFile.name,
      );
    }
    if (platformFile.path != null) {
      return await dio.MultipartFile.fromFile(
        platformFile.path!,
        filename: platformFile.name,
      );
    }

    throw Exception('PlatformFile has no bytes or path');
  }

  Future<String?> uploadImage(files) async {
    final accessToken = await StorageServices.read('accessToken');
    try {
      state = state.copyWith(isUpload: true);
      final formData = dio.FormData();
      for (final file in files) {
        final multipartFile = await _platformFileToMultipartFile(file);
        formData.files.add(MapEntry('file', multipartFile));
      }

      dio.Dio dioInstance = dio.Dio();
      final response = await dioInstance.post(
        'https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net/chat/users/upload',
        data: formData,
        options: dio.Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            "Authorization": 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final encryptedData = response.data['encryptedData'];
        final iv = response.data['iv'];
        if (encryptedData == null || iv == null) {
          throw Exception('Missing encrypted data or IV');
        }
        final decryptedResult = ApiService().decryptData(encryptedData, iv);

        final Map<String, dynamic> resultData;
        if (decryptedResult is String) {
          resultData = jsonDecode(decryptedResult);
        } else if (decryptedResult is Map<String, dynamic>) {
          resultData = decryptedResult;
        } else {
          throw Exception('Invalid decrypted data format');
        }

        if (resultData['Data'] != null &&
            resultData['Data'] is List &&
            resultData['Data'].isNotEmpty) {
          final imageUrl = resultData['Data'][0];
          state = state.copyWith(isUpload: false);

          Fluttertoast.showToast(
            msg: "Sent",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          return imageUrl.toString();
        } else {
          Fluttertoast.showToast(
            msg: "Upload failed: No data in response",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return null;
        }
      } else {
        Fluttertoast.showToast(
          msg: "Upload failed: Server error ${response.statusCode}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(isUpload: false);
      Fluttertoast.showToast(
        msg: "Upload failed: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return null;
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return ChatNotifier(ref, socketService);
});