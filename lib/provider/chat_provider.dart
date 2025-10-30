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
      log(data.toString());
      if (data['isGroupChat'] == true) {
        _handleIncomingGroupMessage(data);
      } else {
        _handleIncomingMessage(data);
      }
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
    // final uploadedUrls = (data['uploadedUrls'] as List?) ?? [];

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

  void _handleIncomingGroupMessage(dynamic data) {
    try {
      final groupMessage = _mapToGroupMessage(data);
      _addGroupMessageToState(groupMessage);
    } catch (e, stackTrace) {
      log('Error processing received group message: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = _mapToMessage(data);
      _addMessageToState(message, prepend: true);
    } catch (e, stackTrace) {
      log('Error processing received message: $e');
      log('Stack trace: $stackTrace');
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

  void _addMessageToState(Message message, {bool prepend = true}) {
    if (message.chatID == null) {
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

  void _insertMessageChronological(List<GroupMessage> messages, GroupMessage newMessage) {
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

  Future<void> loadMessages(String chatId, int userId) async {
    _currentChatId = chatId;
    state = state.copyWith(
        chatMsgLoading: true, currentChatId: chatId, error: null);

    try {
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

      final res = ApiService().decryptData(encryptedData, iv);

      if (res != null) {
        final messagesList =
            (res as List).map((m) => Message.fromJson(m)).toList();
        messagesList.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        state = state.copyWith(
            messages: messagesList, chatMsgLoading: false, error: null);
        markMessagesAsRead(chatId);
      } else {
        throw Exception('Failed to decrypt response data');
      }
    } catch (error) {
      log('Error loading messages: $error');
      state = state.copyWith(
          chatMsgLoading: false,
          error: 'Failed to load messages: ${error.toString()}');
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
      };

      socket.emit('send_message', messageData);
    } catch (error) {
      log('Send group message error: $error');
      state = state.copyWith(
        error: 'Failed to send group message: ${error.toString()}',
      );
      rethrow;
    }
  }


  typingMessage(){

    final messageData = {
      "senderID": _currentUserId,
      "senderName": "",
      "receiverID": _currentUserId,
      "receiverName": "",
      "groupID": null,
      "isGroupChat": false,
    };
   socket.emit('typing',messageData);

  }


  stopTypingMessage({ required String author,
    required List<dynamic> uploadUrl,
    required String content,
    required int receiverId,
    required int chatId
  }){

    final messageData = {
      "senderID": _currentUserId,
      "senderName": author,
      "receiverID": receiverId,
      "receiverName": "",
      "groupID": null,
      "isGroupChat": false,
    };


  }


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
      };

      print("messageData$messageData");

      socket.emit('send_message', messageData);
      // _addMessageToState(tempMessage);
    } catch (error) {
      log('Send message error: $error');
      state = state.copyWith(
        error: 'Failed to send message: ${error.toString()}',
      );
      rethrow;
    }
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
        return Message(
          messageID: message.messageID,
          senderID: message.senderID,
          receiverID: message.receiverID,
          content: message.content,
          attachment: message.attachment,
          uploadedUrls: [],
          sentAt: message.sentAt,
          isDeleted: message.isDeleted,
          isPinned: message.isPinned,
          isSeenBySender: message.isSeenBySender,
          isSeenByReceiver: true,
          chatID: message.chatID,
          type: message.type,
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
        grpMsgLoading: true, currentGroupId: groupId, error: null);

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

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }

      final res = ApiService().decryptData(encryptedData, iv);

      if (res != null) {
        final messagesList =
        (res as List).map((m) => GroupMessage.fromJson(m)).toList();
        messagesList.sort((a, b) => a.sentAt.compareTo(b.sentAt));

        state = state.copyWith(
            groupMessages: messagesList, isLoading: false, error: null);
      } else {
        throw Exception('Failed to decrypt response data');
      }
    } catch (error) {
      log('Error loading group messages: $error');
      state = state.copyWith(
          groupMessages: [],
          grpMsgLoading: false,
          error: 'Failed to load group messages: ${error.toString()}');
    } finally {
      state = state.copyWith(
        grpMsgLoading: false,
      );
    }
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

      updatedMessages[messageIndex] = Message(
        messageID: oldMessage.messageID,
        senderID: oldMessage.senderID,
        receiverID: oldMessage.receiverID,
        content: oldMessage.content,
        attachment: oldMessage.attachment,
        uploadedUrls: [],
        sentAt: oldMessage.sentAt,
        isDeleted: oldMessage.isDeleted,
        isPinned: oldMessage.isPinned,
        isSeenBySender:
            isDelivered || isRead ? true : oldMessage.isSeenBySender,
        isSeenByReceiver: isRead ? true : oldMessage.isSeenByReceiver,
        chatID: oldMessage.chatID,
        type: oldMessage.type,
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
    print("files$files");
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
