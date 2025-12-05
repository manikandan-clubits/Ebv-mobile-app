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
  final String? typingStatus;
  final int? typingUserId;
  final DateTime? typingStartedAt;

  ChatState({
    this.typingStatus,
    this.typingUserId,
    this.typingStartedAt,
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
    String? typingStatus,
    int? typingUserId,
    DateTime? typingStartedAt,
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
      typingStatus: typingStatus ?? this.typingStatus,
      typingUserId: typingUserId ?? this.typingUserId,
      typingStartedAt: typingStartedAt ?? this.typingStartedAt,
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
    _currentUserName = userInfo?['UserName'];
    state = state.copyWith(
        currentUserId: _currentUserId, currentUserName: _currentUserName);
  }

  void connectToSocket() {
    log("🔌 Initializing socket connection...");

    socket = IO.io(
      'https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        // 'reconnectionDelay': 1000,
        // 'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 5,
        'forceNew': true,
      },
    );

    socket.onConnect((_) {
      log('✅ Connected to socket server successfully!');
      log('Socket ID: ${socket.id}');
      state = state.copyWith(isConnected: true);

      if (_currentUserId != null) {
        log('👤 Registering user with userId: $_currentUserId');
        socket.emit('register', _currentUserId);
        log('✅ register event emitted');
      } else {
        log('⚠️ Warning: _currentUserId is null, cannot join user room');
      }
    });

    socket.onDisconnect((reason) {
      log('❌ Disconnected from socket server');
      log('Reason: $reason');
      state = state.copyWith(isConnected: false);
    });

    socket.on('editMessageUpdated', (data) {
      log('📝 Message edited event received: $data');
      _handleMessageEdited(data);
    });

    // Listen for delete message events
    socket.on('deleteMessageUpdated', (data) {
      log('🗑️ Message deleted event received: $data');
      _handleMessageDeleted(data);
    });

    socket.onConnectError((error) {
      log('❌ Socket connection error: $error');
      state = state.copyWith(isConnected: false);
    });

    socket.onReconnect((attempt) {
      log('🔄 Reconnected to socket server (attempt: $attempt)');
    });

    socket.onReconnectAttempt((attempt) {
      log('🔄 Attempting to reconnect... (attempt: $attempt)');
    });

    socket.onReconnectError((error) {
      log('❌ Reconnection error: $error');
    });

    socket.onReconnectFailed((_) {
      log('❌ Failed to reconnect to socket server after all attempts');
    });

    // Listen for both event name formats for compatibility
    socket.on('receive_message', (data) {
      log("📩 receive_message event received");
      log("Data: $data");
      _handleIncomingMessage(data);
    });


    socket.on('message_response', (data) {
      log("📩 message_response event received");
      log("Data: $data");
      _handleIncomingMessage(data);
    });

    // Add error listener for debugging
    socket.on('error', (data) {
      log("❌ Socket error: $data");
    });

    // Add generic listener to catch all events for debugging
    socket.onAny((event, data) {
      log("Socket event received:$event");
      log("Event data: $data");

    socket.on('editMessage', (data) {
      try {
        final messageData = data is String ? jsonDecode(data) : data;
        final editedMessage = GroupMessage.fromJson(messageData);

        _handleMessageEdit(editedMessage);
      } catch (e) {
        print('Error handling editMessage socket event: $e');
      }
    });

    socket.on('deleteMessage', (data) {
      try {
        final messageData = data is String ? jsonDecode(data) : data;
        final deletedMessageId = messageData['messageId'] as int?;

        if (deletedMessageId != null) {
          _handleMessageDelete(deletedMessageId);
        }
      } catch (e) {
        print('Error handling deleteMessage socket event: $e');
      }
    });


    socket.on('message_read', (data) {
      _updateMessageDeliveryStatus(data['messageId'], isRead: true);
    });

    socket.on('typing', (data) {
      log('Typing typing event$data');
      _handleTypingEvent(data);
    });

    socket.on('typing_response', (data) {
      log('Typing event :typing_response $data');
      _handleTypingEvent(data);
    });

    socket.on('stop_typing_response', (data) {
      log('Stop Typing event$data');
      _handleStopTypingEvent(data);
    });

  }

  void startTyping({
    required int senderId,
    required String senderName,
    required int receiverId,
    required int? groupId,
    required bool isGroupChat,
  }) {
    final typingData = {
      'senderID': senderId,
      'senderName': senderName,
      'receiverID': receiverId,
      'groupID': groupId,
      'isGroupChat': isGroupChat,
    };

    log('📝 Sending typing event: $typingData');
    socket.emit('typing', typingData);
  }

  void stopTyping({
    required int senderId,
    required String senderName,
    required int receiverId,
    required int? groupId,
    required bool isGroupChat,
  }) {
    final typingData = {
      'senderID': senderId,
      'senderName': senderName,
      'receiverID': receiverId,
      'groupID': groupId,
      'isGroupChat': isGroupChat,
    };

    log('📝 Sending stop_typing event: $typingData');
    socket.emit('stop_typing', typingData);
  }



  void _handleTypingEvent(dynamic data) {
    print("_handleTypingEvent");
    try {
      Map<String, dynamic> typingData;

      if (data is String) {
        typingData = Map<String, dynamic>.from(jsonDecode(data));
      } else if (data is Map<String, dynamic>) {
        typingData = data;
      } else if (data is Map) {
        typingData = Map<String, dynamic>.from(data);
      } else {
        log('❌ Unexpected typing data type: ${data.runtimeType}');
        return;
      }

      final bool isGroupChat = typingData['isGroupChat'] ?? false;
      final int senderId = typingData['senderID'] ?? typingData['senderId'] ?? 0;
      final String senderName = typingData['senderName'] ?? '';

      if (isGroupChat) {
        final int? groupId = typingData['groupID'] ?? typingData['groupId'];
        if (groupId == state.currentGroupId) {
          state = state.copyWith(
            typingStatus: 'Typing...',
            typingUserId: senderId,
          );
        }
      } else {
        final int? receiverId = typingData['receiverID'];
        final String? currentChatId = state.currentChatId;



        // Check if this typing is for the current chat
        if (receiverId == state.currentUserId) {
          print("$senderName is typing...");

          state = state.copyWith(
            typingStatus: 'Typing...',
            typingUserId: senderId,
          );
        }
      }
    } catch (e) {
      log('Error handling typing event: $e');
    }
  }

  void _handleStopTypingEvent(dynamic data) {
    print("call_handleStopTypingEvent");
    try {
      Map<String, dynamic> typingData;

      if (data is String) {
        typingData = Map<String, dynamic>.from(jsonDecode(data));
      } else if (data is Map<String, dynamic>) {
        typingData = data;
      } else if (data is Map) {
        typingData = Map<String, dynamic>.from(data);
      } else {
        log('❌ Unexpected stop typing data type: ${data.runtimeType}');
        return;
      }

      final bool isGroupChat = typingData['isGroupChat'] ?? false;
      final int senderId = typingData['senderID'] ?? typingData['senderId'] ?? 0;

      if (isGroupChat) {
        final int? groupId = typingData['groupID'] ?? typingData['groupId'];
        if (groupId == state.currentGroupId) {
          state = state.copyWith(
            typingStatus: "",
            typingUserId: null,
          );
        }
      } else {
        final int? receiverId = typingData['receiverID'];
        if (receiverId == state.currentUserId) {
          print("InnCheck");
          state = state.copyWith(
            typingStatus: "",
            typingUserId: null,
          );
        }
      }
    } catch (e) {
      log('Error handling stop typing event: $e');
    }
  }

  @override
  void dispose() {
    leaveChat();
    // state = state.copyWith(typingStatus: "",);
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
          ? (data['groupReceiversKeys'] as List)
              .map((e) => Map<String, String>.from(e))
              .toList()
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
      chatID: data['ChatID'] ?? data['chatID'] ?? data['groupID'] ?? data['GroupID'] ?? 0,
      senderID: data['SenderID'] ?? data['senderID'] ?? 0,
      receiverID: data['ReceiverID'] ?? data['receiverID'],
      attachment: data['attachment'] ?? '',
      uploadedUrls: data['uploadedUrls'] ?? [],
      content: data['Content'] ?? data['content'] ?? '',
      sentAt: data['SentAt'] != null ? DateTime.parse(data['SentAt']) : data['sentAt'] != null ? DateTime.parse(data['sentAt']) : DateTime.now(),
      isDeleted: data['IsDeleted'] ?? data['isDeleted'] ?? false,
      isPinned: data['IsPinned'] ?? data['isPinned'] ?? false,
      isSeenBySender: data['IsSeenBySender'] ?? data['isSeenBySender'] ?? true,
      isSeenByReceiver: data['IsSeenByReceiver'] ?? data['isSeenByReceiver'] ?? false,
      groupID: data['groupID'] ?? data['GroupID'] ?? 0,
      isSeenAll: data['isSeenAll'] ?? data['IsSeenAll'] ?? 0,
      author: data['author'] ?? data['Author'] ?? 'Unknown',
      iv: data['iv'],
      encryptedAesKeyForSender: data['encryptedAesKeyForSender'],
      groupReceivers: data['groupReceiversKeys'] != null ? (data['groupReceiversKeys'] as List)
          .map((e) => (e as Map).map((key, value) => MapEntry(key.toString(), value.toString())))
          .toList()
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

  void _handleIncomingMessage(dynamic data) async {
    print("_handleIncomingMessage$data");
    try {
      log("📩 ========== RECEIVING MESSAGE ==========");
      log("Raw data type: ${data.runtimeType}");
      log("Raw data: $data");

      // Validate data
      if (data == null) {
        log('❌ Received null data, ignoring message');
        return;
      }

      final chatKeysState = ref.read(chatKeysProvider);
      final senderPrivateKey =await chatKeysState.senderKeys?.privateKey;
      final currentUserId = state.currentUserId;

      if (senderPrivateKey == null) {
        log('❌ Missing sender private key. Cannot decrypt message.');
        return;
      }

      if (currentUserId == null) {
        log('❌ Missing current user ID. Cannot decrypt message.');
        return;
      }

      // Convert data to Map
      Map<String, dynamic> messageMap;

      if (data is String) {
        log('📝 Data is String, parsing as JSON...');
        try {
          messageMap = Map<String, dynamic>.from(jsonDecode(data));
          log('✅ Successfully parsed JSON');
        } catch (e) {
          log('❌ Failed to parse message string as JSON: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        log('📝 Data is already Map<String, dynamic>');
        messageMap = data;
      } else if (data is Map) {
        log('📝 Data is Map, converting to Map<String, dynamic>');
        messageMap = Map<String, dynamic>.from(data);
      } else {
        log('❌ Unexpected message data type: ${data.runtimeType}');
        return;
      }

      log("📋 Message Map: $messageMap");

      // Check if this is a group message or individual message
      final isGroupChat = messageMap['isGroupChat'] ?? messageMap['isGroup'] ?? false;
      log("📋 Is Group Chat: $isGroupChat");

      if (isGroupChat) {
        log("👥 Handling as GROUP message");

        await _handleGroupMessageData(messageMap, senderPrivateKey, currentUserId);
      } else {
        log("👤 Handling as INDIVIDUAL message");
        await _handleIndividualMessageData(messageMap, senderPrivateKey, currentUserId);
      }

      log("✅ ========== MESSAGE PROCESSED SUCCESSFULLY ==========");
    } catch (e, stackTrace) {
      log('❌ ========== ERROR RECEIVING MESSAGE ==========');
      log('Error: $e');
      log('Stack trace: $stackTrace');
      log('Raw data: $data');
      log('============================================');
      state = state.copyWith(
        error: 'Failed to process incoming message: ${e.toString()}',
      );
    }
  }

  Future<void> _handleIndividualMessageData(
      Map<String, dynamic> messageMap,
      String senderPrivateKey,
      int currentUserId
      ) async {
    try {
      Message message = Message.fromJson(messageMap);
      log("✅ Individual Message object created successfully");
      log("Message ID: ${message.messageID}");
      log("Sender ID: ${message.senderID}");
      log("Receiver ID: ${message.receiverID}");

      var decryptedContent;

      // Check if message is encrypted
      final isEncrypted = message.iv != null &&
          (message.encryptedAesKeyForSender != null ||
              message.encryptedAesKeyForReceiver != null);

      if (!isEncrypted) {
        log('🔓 Individual message is not encrypted, using original content');
        decryptedContent = {'text': message.content};
      } else {
        log('🔐 Individual message is encrypted, decrypting...');
        decryptedContent = await EncryptServices.decryptMessage(
          message,
          senderPrivateKey,
          currentUserId,
        );
        log('✅ Individual message decrypted');
      }

      // Ensure decryptedContent has the expected format
      if (decryptedContent == null ||
          (decryptedContent is Map && decryptedContent['text'] == null)) {
        log('⚠️ Individual message decryption failed or returned null content');
        decryptedContent = {'text': '[Decryption Failed]'};
      }

      log("📝 Individual message decrypted content: ${decryptedContent['text']}");

      // Update message with decrypted content
      final decryptedMessage = Message(
        messageID: message.messageID,
        senderID: message.senderID,
        receiverID: message.receiverID,
        content: decryptedContent['text'] ?? message.content,
        attachment: message.attachment,
        uploadedUrls: message.uploadedUrls,
        sentAt: message.sentAt,
        isDeleted: message.isDeleted,
        isPinned: message.isPinned,
        isSeenBySender: message.isSeenBySender,
        isSeenByReceiver: message.isSeenByReceiver,
        chatID: message.chatID,
        type: message.type,
        isGroup: false, // Explicitly set to false for individual messages
        iv: message.iv,
        encryptedAesKeyForSender: message.encryptedAesKeyForSender,
        encryptedAesKeyForReceiver: message.encryptedAesKeyForReceiver,
        groupReceivers: message.groupReceivers,
        isSending: false,
        error: null,
      );

      // Add to individual messages state
      _addMessageToState(decryptedMessage, prepend: true);

    } catch (e, stackTrace) {
      log('Error processing individual message data: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _handleGroupMessageData(
      Map<String, dynamic> messageMap,
      String senderPrivateKey,
      int currentUserId
      ) async {
    print("senderPrivateKey$senderPrivateKey");
    try {
      // Convert to GroupMessage format
      GroupMessage groupMessage = _mapToGroupMessage(messageMap);
      log("✅ Group Message object created successfully");
      log("Group Message ID: ${groupMessage.messageID}");
      log("Group ID: ${groupMessage.groupID}");
      log("Sender ID: ${groupMessage.senderID}");

      var decryptedContent;

      // Check if message is encrypted
      final isEncrypted = groupMessage.iv != null &&
          (groupMessage.encryptedAesKeyForSender != null ||
              groupMessage.groupReceivers != null);

      if (!isEncrypted) {
        log('🔓 Group message is not encrypted, using original content');
        decryptedContent = {'text': groupMessage.content};
      } else {
        log('🔐 Group message is encrypted, decrypting...');

        // Create a Message object for decryption (since decryptMessageGroup expects Message type)
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
          groupReceivers: groupMessage.groupReceivers?.map((e) => Map<String, String>.from(e)).toList(),
        );

        decryptedContent = await EncryptServices.decryptMessageGroup(
          messageData: messageForDecryption,
          privateKeyRef: senderPrivateKey,
          currentUserId: currentUserId,
        );
        log('✅ Group message decrypted');
      }

      // Ensure decryptedContent has the expected format
      if (decryptedContent == null ||
          (decryptedContent is Map && decryptedContent['text'] == null)) {
        log('⚠️ Group message decryption failed or returned null content');
        decryptedContent = {'text': '[Decryption Failed]'};
      }

      log("📝 Group message decrypted content: ${decryptedContent['text']}");

      // Update group message with decrypted content
      final decryptedGroupMessage = GroupMessage(
        messageID: groupMessage.messageID,
        chatID: groupMessage.chatID,
        senderID: groupMessage.senderID,
        receiverID: groupMessage.receiverID,
        attachment: groupMessage.attachment,
        uploadedUrls: groupMessage.uploadedUrls,
        content: decryptedContent['text'] ?? groupMessage.content,
        sentAt: groupMessage.sentAt,
        isDeleted: groupMessage.isDeleted,
        isPinned: groupMessage.isPinned,
        isSeenBySender: groupMessage.isSeenBySender,
        isSeenByReceiver: groupMessage.isSeenByReceiver,
        groupID: groupMessage.groupID,
        isSeenAll: groupMessage.isSeenAll,
        author: groupMessage.author,
        iv: groupMessage.iv,
        encryptedAesKeyForSender: groupMessage.encryptedAesKeyForSender,
        groupReceivers: groupMessage.groupReceivers,
      );

      // Add to group messages state
      _addGroupMessageToState(decryptedGroupMessage);

    } catch (e, stackTrace) {
      log('Error processing group message data: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    }
  }


  Future<void> loadMessages(String chatId, int userId) async {
    if (state.chatMsgLoading && state.currentChatId == chatId) {
      final previousMessages = state.messages;
      state = state.copyWith(
        messages:previousMessages,
      );
      log('Already loading messages for chat $chatId, skipping...');
      return;
    }

    _currentChatId = chatId;
    state = state.copyWith(
      messages:[],
      chatMsgLoading: true,
      currentChatId: chatId,
      error: null,
    );

    try {
      // Non-blocking socket join
      _joinChatInBackground(chatId);

      final response = await ApiService().post('/chat/messages/singlelist', {
        "SelectedUserId": userId,
        // "beforeSentAt": "2025-12-01T10:30:00.000Z"
        // "beforeSentAt":   DateTime.now().toUtc().toIso8601String(),
      }).timeout(const Duration(seconds: 15)); // Add timeout

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
      print("APIResponse${result}");
      final chatKeysState = ref.read(chatKeysProvider);
      print("chatKeysState.senderKeys?.privateKey${chatKeysState.senderKeys?.privateKey}");
      if (result != null && result is List) {
        List<dynamic> rawMessages = result;

        List<Message> messagesList = rawMessages.map((m) {
          if (m is Message) {
            return m; // Already a Message object
          } else if (m is Map<String, dynamic>) {
            return Message.fromJson(m); // Convert from JSON
          } else {
            throw FormatException('Invalid message format: $m');
          }
        }).toList();

        // Process messages in batches for smoother UI
        List<Message> decryptedMessages = await _processMessagesInBatches(
          messagesList,
          chatKeysState.senderKeys?.privateKey,
        );

        // Sort by latest first
        decryptedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

        // Update state with new messages
        state = state.copyWith(
          messages: decryptedMessages,
          chatMsgLoading: false,
          error: null,
        );

        // Background operation for marking as read
        // _markMessagesAsReadInBackground(chatId);
      } else {
        throw Exception('Failed to decrypt response data');
      }
    } catch (error) {
      log('Error loading messages: $error');
      // Restore previous messages on error to maintain UI state
      state = state.copyWith(
        // messages: previousMessages,
        chatMsgLoading: false,
        error: 'Failed to load messages: ${error.toString()}',
      );
    }
  }

// Process messages in batches to keep UI responsive
  Future<List<Message>> _processMessagesInBatches(
    List<Message> messages,
    String? privateKey,
  ) async {
    final List<Message> decryptedMessages = [];
    const int batchSize = 5; // Smaller batches for better responsiveness

    for (int i = 0; i < messages.length; i += batchSize) {
      final end =
          i + batchSize > messages.length ? messages.length : i + batchSize;
      final batch = messages.sublist(i, end);

      // Process current batch
      final batchResults = await Future.wait(
        batch
            .map((message) => _decryptMessageWithFallback(message, privateKey)),
      );

      decryptedMessages.addAll(batchResults);

      // Small delay to allow UI updates between batches
      if (end < messages.length) {
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Optional: Update UI progressively (uncomment if you want progressive loading)
      // _updateMessagesProgressively(decryptedMessages);
    }

    return decryptedMessages;
  }

  Future<Message> _decryptMessageWithFallback(
      Message message, String? privateKey) async {
    try {
      final decryptedContent = await EncryptServices.decryptMessage(
        message,
        privateKey,
        state.currentUserId,
      );

      log("Decrypted content: ${decryptedContent['text']}");

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
      log('Decryption failed for message ${message.messageID}, using original: $e');
      // Return original message but mark as processed
      return message.copyWith(isSending: false);
    }
  }

// Non-blocking socket join
  void _joinChatInBackground(String chatId) {
    Future.microtask(() {
      try {
        log('🚪 Attempting to join chat room: $chatId');
        log('User ID: $_currentUserId');
        log('Socket connected: ${socket.connected}');

        // Server expects 'join_room' with just the room ID (chatId)
        // Based on server code: socket.on("join_room", (room) => { socket.join(room); });

        socket.emit('join_room', chatId);
        log('✅ Emitted join_room (snake_case) with chatId: $chatId');

        log('✅ Successfully joined chat room: $chatId');
      } catch (e) {
        log('❌ Socket join error: $e');
      }
    });
  }

// Background mark as read
  void _markMessagesAsReadInBackground(String chatId) {
    Future.microtask(() {
      try {
        markMessagesAsRead(chatId);
      } catch (e) {
        log('Background mark as read failed: $e');
      }
    });
  }

  void _addMessageToState(Message message, {bool prepend = true}) {
    if (message.chatID == null && !message.isGroup) {
      return;
    }

  void _addMessageToState(Message message, {bool prepend = true}) {
    final existingMessageIndex = state.messages.indexWhere((m) => m.messageID == message.messageID);
    final updatedMessages = List<Message>.from(state.messages);

    if (existingMessageIndex != -1) {
      updatedMessages[existingMessageIndex] = message;
    } else {
      // Binary search for optimal insertion in descending order
      int low = 0;
      int high = updatedMessages.length;

      while (low < high) {
        int mid = (low + high) ~/ 2;
        if (message.sentAt.isAfter(updatedMessages[mid].sentAt)) {
          high = mid;
        } else {
          low = mid + 1;
        }
      }
      updatedMessages.insert(low, message);
    }
    state = state.copyWith(messages: updatedMessages);
  }

  void _addGroupMessageToState(GroupMessage message) {
    final existingIndex =
        state.groupMessages.indexWhere((m) => m.messageID == message.messageID);

    if (existingIndex != -1) {
      // Update existing message
      updatedMessages[existingIndex] = message;
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      state = state.copyWith(groupMessages: updatedMessages);
    } else {
      // Binary search to insert in descending order (newest first)
      int low = 0;
      int high = updatedMessages.length;

      while (low < high) {
        int mid = (low + high) ~/ 2;
        if (message.sentAt.isAfter(updatedMessages[mid].sentAt)) {
          low = mid + 1; // Go to right half for descending order
        } else {
          high = mid;    // Go to left half
        }
      }
      updatedMessages.insert(low, message);
    }

    state = state.copyWith(groupMessages: updatedMessages);
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


// Fixed send message methods
  Future<void> sendMessage({
    required String author,
    required List<dynamic> uploadUrl,
    required String content,
    required int receiverId,
    required int chatId,
    MessageType type = MessageType.text,
    List<PlatformFile>? selectedFiles,
  }) async {
    try {
      await _getCurrentUserId();

      List<Map<String, dynamic>>? formDataList;
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        formDataList = await _prepareFiles(selectedFiles);
      }

      // Generate a temporary message ID for optimistic UI
      final tempMessageId = DateTime.now().millisecondsSinceEpoch;

      final messageData = {
        "author": author,
        "receiverID": receiverId,
        "groupID": '',
        "SenderID": _currentUserId,
        "Content": content,
        "SentAt": DateTime.now().toIso8601String(),
        "IsDeleted": false,
        "IsPinned": false,
        "isGroupChat": false,
        "uploadedUrls": uploadUrl,
        "error": '',
        // Add temporary ID for state management
        "messageID": tempMessageId,
        "chatID": chatId,
      };

      print("messageData$messageData");

      // Create temporary message for optimistic UI
      final tempMessage = Message(
        messageID: tempMessageId,
        chatID: chatId,
        senderID: state.currentUserId!,
        receiverID: receiverId,
        attachment: '',
        content: content,
        sentAt: DateTime.now(),
        isDeleted: false,
        isPinned: false,
        uploadedUrls: uploadUrl.cast<String>(),
      );

      // Add to state immediately for optimistic UI
      _addMessageToState(tempMessage);

      // Emit socket event
      socket.emit('send_message', messageData);

    } catch (error) {
      log('Send message error: $error');
      state = state.copyWith(
        error: 'Failed to send message: ${error.toString()}',
      );
      rethrow;
    }
  }

  Future<void> sendGroupMessage({
    required String author,
    required List<dynamic> uploadUrl,
    required String content,
    required int groupId,
    MessageType type = MessageType.text,
    List<PlatformFile>? selectedFiles,
  }) async {
    try {
      await _getCurrentUserId();

      List<Map<String, dynamic>>? formDataList;
      if (selectedFiles != null && selectedFiles.isNotEmpty) {
        formDataList = await _prepareFiles(selectedFiles);
      }

      // Generate a temporary message ID for optimistic UI
      final tempMessageId = DateTime.now().millisecondsSinceEpoch;

      final messageData = {
        "author": author,
        "receiverID": _currentUserId,
        "groupID": groupId,
        "SenderID": _currentUserId,
        "Content": content,
        "SentAt": DateTime.now().toIso8601String(),
        "IsDeleted": false,
        "IsPinned": false,
        "isGroupChat": true,
        "uploadedUrls": uploadUrl ?? [],
        "error": '',
        // Add temporary ID for state management
        "messageID": tempMessageId,
      };

      // Create temporary message for optimistic UI
      final tempMessage = GroupMessage(
        messageID: tempMessageId,
        groupID: groupId,
        senderID: state.currentUserId!,
        content: content,
        sentAt: DateTime.now(),
        isDeleted: false,
        isPinned: false,
        uploadedUrls: (uploadUrl ?? []).cast<String>(),
        author: author,
        attachment: '',
        isSeenAll: 0,
        isSeenByReceiver: false,
        isSeenBySender: false,
        chatID: 0,
        receiverID: _currentUserId,
      );

      // Add to state immediately for optimistic UI
      _addGroupMessageToState(tempMessage);

      // Emit socket event
      socket.emit('send_message', messageData);

    } catch (error) {
      log('Send group message error: $error');
      state = state.copyWith(
        error: 'Failed to send group message: ${error.toString()}',
      );
      rethrow;
    }
  }

  Future<List<GroupPublicKey>> _getGroupPublicKeys(int groupId) async {
    print("groupId: $groupId");
    try {
      // Ensure members are loaded
      if (state.groupMembers.isEmpty) {
        await loadGroupMembers(groupId);
      }

      final keys = <GroupPublicKey>[];
      final chatKeysNotifier = ref.read(chatKeysProvider.notifier);
      final chatKeysState = ref.read(chatKeysProvider);

      for (final member in state.groupMembers) {
        final memberId = member.userID;

        // Convert memberId to both string and int for lookup
        final memberIdInt = memberId;
        final memberIdStr = memberId.toString();

        print("member.userID: $memberId (type: ${memberId.runtimeType})");
        String? key;

        // Try to get key using string ID
        key = chatKeysState.receiverKeys[memberIdStr]?.publicKey;
        print("key found in receiverKeys[$memberIdStr]: $key");

        // If not found, try to get by integer ID
        if (key == null) {
          key = chatKeysState.receiverKeys[memberIdInt]?.publicKey;
          print("key found in receiverKeys[$memberIdInt]: $key");
        }

        // If still not found, fetch it
        if (key == null) {
          try {
            print("Fetching key for member $memberIdInt (int)");
            await chatKeysNotifier.getReceiverChatKeys(memberIdInt);

            // Re-read state after update
            final updatedState = ref.read(chatKeysProvider);

            // Try both string and int keys again
            key = updatedState.receiverKeys[memberIdStr]?.publicKey ??
                updatedState.receiverKeys[memberIdInt]?.publicKey;

            print("key after fetching: $key");
          } catch (e) {
            log('Failed to fetch key for member $memberIdInt: $e');
          }
        }

        if (key != null) {
          keys.add(GroupPublicKey(
            userId: memberIdInt, // Store as int
            publicKey: key,
          ));
        } else {
          print("⚠️ No key found for member $memberIdInt");
        }
      }

      print("Total keys collected: ${keys.length}");
      return keys;
    } catch (e) {
      log('Error getting group public keys: $e');
      return [];
    }
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

      final decrypted = ApiService().decryptData(encryptedData, iv);

      if (decrypted != null) {
        // Handle different response formats
        List<Message> messagesList = [];

        if (decrypted is List) {
          // Direct list of messages
          messagesList = (decrypted as List).map((m) => Message.fromJson(m)).toList();
        } else if (decrypted is Map<String, dynamic>) {
          // Check for common response structures
          if (decrypted['data'] is List) {
            // Response with 'data' key containing the list
            messagesList = (decrypted['data'] as List).map((m) => Message.fromJson(m)).toList();
          } else if (decrypted['messages'] is List) {
            // Response with 'messages' key containing the list
            messagesList = (decrypted['messages'] as List).map((m) => Message.fromJson(m)).toList();
          } else if (decrypted['result'] is List) {
            // Response with 'result' key containing the list
            messagesList = (decrypted['result'] as List).map((m) => Message.fromJson(m)).toList();
          } else {
            // Try to parse the entire map as a single message or look for other structures
            throw Exception('Unexpected response format: ${decrypted.keys}');
          }
        } else {
          throw Exception('Unexpected decrypted data type: ${decrypted.runtimeType}');
        }

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
    required String? author,
    required List<dynamic> uploadUrl,
    required String content,
    required MessageType type,
    List<PlatformFile>? selectedFiles,
    int? receiverId,
    int? groupId,
    int? chatId,
    required int currentUserId,
  }) async {
    print("author$author");
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
      final senderPublicKey =await chatKeysState.senderKeys?.publicKey;
      final senderPrivateKey =await chatKeysState.senderKeys?.privateKey;

      if (senderPublicKey == null || senderPrivateKey == null) {
        throw Exception('Missing sender keys');
      }


      Map<String, dynamic> messageData = {
        "author": author,
        if (!isGroupChat) "receiverID": receiverId,
        "groupID": isGroupChat ? groupId : '',
        "SenderID": currentUserId,
        "Content": combinedContent,
        "SentAt": DateTime.now().toIso8601String(),
        "IsDeleted": false,
        "IsPinned": false,
        "isGroupChat": isGroupChat,
        "uploadedUrls": uploadUrl,
        "error": "",
        if (!isGroupChat && chatId != null) "chatID": chatId,
      };

      print("Initial messageData: $messageData");

      // Handle encryption based on message type
      if (!isGroupChat) {
        var receiverKey =await chatKeysState.receiverKeys[receiverId.toString()]?.publicKey;
        print("receiverKey$receiverKey");
        if (receiverKey == null) {
          await ref.read(chatKeysProvider.notifier).getReceiverChatKeys(receiverId);
          receiverKey = ref.read(chatKeysProvider).receiverKeys[receiverId.toString()]?.publicKey;
        }

        if (receiverKey == null) {
          throw Exception('Missing receiver public key');
        }

        final encrypted = await EncryptServices.encryptMessage(
          content: combinedContent,
          publicKeyRef: senderPublicKey,
          receiverPubKeyRef: receiverKey,
          senderId: currentUserId,
          receiverId: receiverId,
        );

        messageData['Content'] = encrypted.encryptedText;
        messageData['iv'] = encrypted.iv;
        messageData['encryptedAesKeyForSender'] =
            encrypted.encryptedAesKeyForSender;
        messageData['encryptedAesKeyForReceiver'] =
            encrypted.encryptedAesKeyForReceiver;
      } else {
        // Group Chat
        final groupKeys = await _getGroupPublicKeys(groupId);
        if (groupKeys.isEmpty) {
          print('Warning: No other group members found with keys');
        }

        final encrypted = await EncryptServices.encryptMessageGroup(
          content: combinedContent,
          publicKeyRef: senderPublicKey,
          groupReceivers: groupKeys,
          senderId: currentUserId,
          groupId: groupId.toString(),
        );

        messageData['Content'] = encrypted.encryptedText;
        messageData['iv'] = encrypted.iv;
        messageData['encryptedAesKeyForSender'] =await encrypted.encryptedAesKeyForSender;
        messageData['groupReceiversKeys'] =await encrypted.groupReceivers;
      }


      log("Full Message Data: $messageData");

      // Emit with both event names for compatibility
      socket.emit('send_message', messageData);
      uploadUrl.clear();
    } catch (error) {
      state = state.copyWith(
        error: 'Failed to send message: ${error.toString()}',
      );
      rethrow;
    }finally{
      uploadUrl.clear();
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

  void _handleMessageSentConfirmation(dynamic data) {
    try {
      print("Message sent confirmation received: $data");

      // Handle different data formats
      Map<String, dynamic> confirmationData;

      if (data is String) {
        try {
          confirmationData = Map<String, dynamic>.from(jsonDecode(data));
        } catch (e) {
          print('Failed to parse confirmation data as JSON: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        confirmationData = data;
      } else if (data is Map) {
        confirmationData = Map<String, dynamic>.from(data);
      } else {
        print('Unexpected confirmation data type: ${data.runtimeType}');
        return;
      }

      // Try different field name formats
      final serverMessageId = confirmationData['MessageID'] ??
          confirmationData['messageID'] ??
          confirmationData['messageId'];
      final tempMessageId = confirmationData['tempMessageId'] ??
          confirmationData['TempMessageId'];

      print(
          "Server message ID: $serverMessageId, Temp message ID: $tempMessageId");

      if (serverMessageId != null && tempMessageId != null) {
        final updatedMessages = state.messages.map((message) {
          if (message.messageID == tempMessageId) {
            print("Updating message $tempMessageId to $serverMessageId");
            return message.copyWith(
              messageID: serverMessageId,
              isSending: false,
              error: null,
            );
          }
          return message;
        }).toList();

        state = state.copyWith(messages: updatedMessages);
        print("Message confirmation processed successfully");
      } else {
        print("Missing serverMessageId or tempMessageId in confirmation");
      }
    } catch (e, stackTrace) {
      log('Error handling message sent confirmation: $e');
      log('Stack trace: $stackTrace');
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
          message.receiverID == _currentUserId &&
          !message.isSeenByReceiver) {
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
  Future<GroupChat> _processGroupData(Map<String, dynamic> groupData) async {
    try {
      if (groupData['lastMessage'] != null &&
          groupData['lastMessage'] is String &&
          (groupData['lastMessage'] as String).isNotEmpty &&
          groupData['lastMessageIV'] != null) {
        final chatKeysState = ref.read(chatKeysProvider);
        final senderPrivateKey = chatKeysState.senderKeys?.privateKey;
        final currentUserId = state.currentUserId;

        if (senderPrivateKey != null && currentUserId != null) {
          final groupReceivers = groupData['lastMessageGroupReceiversKeys'];
          List<Map<String, String>>? parsedReceivers;

          if (groupReceivers != null) {
            if (groupReceivers is List) {
              parsedReceivers = groupReceivers
                  .map((e) => Map<String, String>.from(e))
                  .toList();
            } else if (groupReceivers is String) {
              try {
                final parsed = jsonDecode(groupReceivers);
                if (parsed is List) {
                  parsedReceivers =
                      parsed.map((e) => Map<String, String>.from(e)).toList();
                }
              } catch (_) {}
            }
          }

          final message = Message(
            messageID: 0,
            senderID: groupData['lastMessageSenderId'] ??
                groupData['LastMessageSenderId'] ??
                0,
            receiverID: 0,
            content: groupData['lastMessage'],
            attachment: '',
            uploadedUrls: [],
            sentAt: DateTime.now(),
            isDeleted: false,
            isPinned: false,
            isSeenBySender: false,
            isSeenByReceiver: false,
            type: MessageType.text,
            isGroup: true,
            iv: groupData['lastMessageIV'],
            encryptedAesKeyForSender:
                groupData['lastMessageEncryptedAesKeyForSender'],
            groupReceivers: parsedReceivers,
            isSending: false,
          );

          final decryptedContent = await EncryptServices.decryptMessageGroup(
            messageData: message,
            privateKeyRef: senderPrivateKey,
            currentUserId: currentUserId,
          );

          if (decryptedContent['text'] != null) {
            final updatedGroupData = Map<String, dynamic>.from(groupData);
            updatedGroupData['lastMessage'] = decryptedContent['text'];
            return GroupChat.fromJson(updatedGroupData);
          }
        }
      }
    } catch (e) {
      log('Error decrypting last message for group: $e');
    }
    return GroupChat.fromJson(groupData);
  }

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
          final groupListRaw = response.data['groupList'] as List;
          final groups = await Future.wait(
              groupListRaw.map((g) => _processGroupData(g)).toList());
          state = state.copyWith(
            groups: groups,
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
          final groupListRaw = decrypted['groupList'] as List;
          final groups = await Future.wait(
              groupListRaw.map((g) => _processGroupData(g)).toList());
          state = state.copyWith(
            groups: groups,
            grpListLoading: false,
            error: null,
          );
        } else {
          // Try direct list parsing if possible, or throw
          throw Exception(
              'Unexpected group response format: Map without groupList');
        }
      } else if (decrypted is List) {
        final groups = await Future.wait(
            decrypted.map((g) => _processGroupData(g)).toList());
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
        final updatedGroups = List<GroupChat>.from(state.groups)..insert(0, newGroup);
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
      groupMessages: [],
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
        } else if (decryptedData is Map &&
            decryptedData.containsKey('messages')) {
          messagesData = decryptedData['messages'] as List;
        } else if (decryptedData is List) {
          messagesData = decryptedData;
        } else {
          throw Exception(
              'Unexpected response format: ${decryptedData.runtimeType}');
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
        final senderPrivateKey =await chatKeysState.senderKeys?.privateKey;
        final currentUserId = state.currentUserId;

        print("grpMembersenderPrivateKey$senderPrivateKey");

        // Decrypt each group message
        List<GroupMessage> decryptedMessages = await Future.wait(
          messagesList.map((groupMessage) async {
            try {
              // Check if message needs decryption
              final isEncrypted = groupMessage.iv != null &&
                  (groupMessage.encryptedAesKeyForSender != null ||
                      groupMessage.groupReceivers != null);

              if (!isEncrypted) {
                print(
                    'Group message ${groupMessage.messageID} is not encrypted');
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
              print(
                  'Encrypted AES Key: ${groupMessage.encryptedAesKeyForSender}');
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

              final decryptedContent =
                  await EncryptServices.decryptMessageGroup(
                messageData: messageForDecryption,
                privateKeyRef: senderPrivateKey,
                currentUserId: currentUserId,
              );

              if (decryptedContent['text'] != null) {
                print(
                    'Successfully decrypted group message: ${decryptedContent['text']}');
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

  Future<dynamic> uploadImage(files) async {
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

        if (resultData['Data'] != null && resultData['Data'] is List && resultData['Data'].isNotEmpty) {
          final imageUrls = resultData['Data'];
          state = state.copyWith(isUpload: false);

          print("ImagesUrls${resultData['Data']}");

          Fluttertoast.showToast(
            msg: "Sent",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          return imageUrls;
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


  Future<void> editMessage({
    required int messageId,
    required String newContent,
    required int receiverId,
    required bool isGroup,
  }) async {
    try {
      log('📝 Editing message: $messageId');

      // Update locally immediately for instant feedback
      final updatedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            content: newContent,
            isEdited: true,
            editedAt: DateTime.now(),
          );
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);

      // Prepare payload
      final payload = {
        'Content': newContent,
        'MessageID': messageId,
        'receiverID': receiverId,
        'isGroupChat': isGroup,
      };

      // Call API to update on server
      final response = await ApiService().post(
        '/chat/messages/edit',
        payload,
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      dynamic decryptedData;
      if (encryptedData != null && iv != null) {
        decryptedData = ApiService().decryptData(encryptedData, iv);
      } else {
        decryptedData = response.data;
      }

      final updatedMessage = Message.fromJson(decryptedData);

      // Update with server response
      final finalMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return updatedMessage;
        }
        return message;
      }).toList();

      state = state.copyWith(messages: finalMessages);

      // Emit socket event for real-time update
      socket.emit('editMessage', {
        'MessageID': updatedMessage.messageID,
        'Content': updatedMessage.content,
        'receiverID': receiverId,
        'isGroupChat': isGroup,
        'editedAt': DateTime.now().toIso8601String(),
      });

      log('✅ Message edited successfully');
    } catch (e, stackTrace) {
      log('❌ Error editing message: $e');
      log('Stack trace: $stackTrace');

      // Revert local changes on error
      final revertedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            // isEdited: false,
            editedAt: null,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(
        messages: revertedMessages,
        error: 'Failed to edit message: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteMessage({
    required int messageId,
    required int receiverId,
    required bool isGroup,
    required bool deleteForEveryone,
  }) async {
    try {
      log('🗑️ Deleting message: $messageId');

      // Update locally immediately for instant feedback
      final updatedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
            deleteForEveryone: deleteForEveryone,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);

      // Prepare payload
      final payload = {
        'MessageID': messageId,
        'deleteForEveryone': deleteForEveryone,
        'receiverID': receiverId,
        'isGroupChat': isGroup,
      };

      // Call API to delete on server
      final response = await ApiService().post(
        '/chat/messages/delete',
        payload,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message on server');
      }

      // Emit socket event for real-time update
      socket.emit('deleteMessage', {
        'MessageID': messageId,
        'deleteForEveryone': deleteForEveryone,
        'receiverID': receiverId,
        'isGroupChat': isGroup,
      });

      log('✅ Message deleted successfully');
    } catch (e, stackTrace) {
      log('❌ Error deleting message: $e');
      log('Stack trace: $stackTrace');

      // Revert local changes on error
      final revertedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            isDeleted: false,
            deletedAt: null,
            deleteForEveryone: false,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(
        messages: revertedMessages,
        error: 'Failed to delete message: ${e.toString()}',
      );
      rethrow;
    }
  }

  void _handleMessageEdited(dynamic data) {
    try {
      Map<String, dynamic> messageData;

      if (data is String) {
        messageData = Map<String, dynamic>.from(jsonDecode(data));
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        return;
      }

      final messageId = messageData['MessageID'] ?? messageData['messageID'];
      final newContent = messageData['Content'] ?? messageData['content'];
      // final editedAt = messageData['editedAt'] != null
      //     ? DateTime.parse(messageData['editedAt'])
      //     : DateTime.now();

      // Update the message in state
      final updatedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            content: newContent,
            // isEdited: true,
            // editedAt: editedAt,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      log('Error handling message edit: $e');
    }
  }

  void _handleMessageDeleted(dynamic data) {
    try {
      Map<String, dynamic> messageData;

      if (data is String) {
        messageData = Map<String, dynamic>.from(jsonDecode(data));
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is Map) {
        messageData = Map<String, dynamic>.from(data);
      } else {
        return;
      }

      final messageId = messageData['MessageID'] ?? messageData['messageID'];
      final deleteForEveryone = messageData['deleteForEveryone'] ?? false;

      // Update the message in state
      final updatedMessages = state.messages.map((message) {
        if (message.messageID == messageId) {
          return message.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
            deleteForEveryone: deleteForEveryone,
          );
        }
        return message;
      }).toList();

      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      log('Error handling message delete: $e');
    }
  }

}


final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return ChatNotifier(ref, socketService);
});
