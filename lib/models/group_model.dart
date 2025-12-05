import 'dart:convert';

class GroupChat {
  final int groupID;
  final String name;
  final String? description;
  final String? profilePicture;
  final int createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final int memberCount;

  GroupChat({
    required this.groupID,
    required this.name,
    this.description,
    this.profilePicture,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.memberCount = 0,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      groupID: json['GroupID'] ?? 0,
      name: json['GroupName'] ?? 'Unknown Group',
      description: json['description'] ?? json['Description'],
      profilePicture: json['profilePicture'] ?? json['ProfilePicture'],
      createdBy: json['createdBy'] ?? json['CreatedBy'] ?? 0,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'])
              : DateTime.now(),
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : json['lastMessageTime'] != null
              ? DateTime.parse(json['lastMessageTime'])
              : null,
      unreadCount: json['unreadCount'] ?? json['UnreadCount'] ?? 0,
      memberCount: json['memberCount'] ?? json['MemberCount'] ?? 0,
    );
  }

  // Alias for name to maintain compatibility
  String get groupName => name;
}

class GroupMessage {
  final int messageID;
  final int? chatID;
  final int senderID;
  final int? receiverID;
  final String? attachment;
  final dynamic
      uploadedUrls; // Changed to dynamic to handle both String and List
  final String content;
  final DateTime sentAt;
  final bool isDeleted;
  final bool isPinned;
  final bool isSeenBySender;
  final bool isSeenByReceiver;
  final int groupID;
  final int isSeenAll;
  final String? senderName;
  final List<dynamic>? seenBy;
  final String? iv;
  final String? encryptedAesKeyForSender;
  final List<Map<String, String>>? groupReceivers;
  final String? author;

  GroupMessage({
    required this.messageID,
    this.chatID,
    required this.senderID,
    this.receiverID,
    this.attachment,
    this.uploadedUrls,
    required this.content,
    required this.sentAt,
    required this.isDeleted,
    required this.isPinned,
    required this.isSeenBySender,
    required this.isSeenByReceiver,
    required this.groupID,
    required this.isSeenAll,
    this.senderName,
    this.seenBy,
    this.iv,
    this.encryptedAesKeyForSender,
    this.groupReceivers,
    this.author,
  });

  GroupMessage copyWith({
    int? messageID,
    int? chatID,
    int? senderID,
    int? receiverID,
    String? attachment,
    final dynamic uploadedUrls,
    String? content,
    DateTime? sentAt,
    bool? isDeleted,
    bool? isPinned,
    bool? isSeenBySender,
    bool? isSeenByReceiver,
    int? groupID,
    int? isSeenAll,
    String? senderName,
    List<dynamic>? seenBy,
    String? iv,
    String? encryptedAesKeyForSender,
    List<Map<String, String>>? groupReceivers,
    String? author,
  }) {
    return GroupMessage(
      messageID: messageID ?? this.messageID,
      chatID: chatID ?? this.chatID,
      senderID: senderID ?? this.senderID,
      receiverID: receiverID ?? this.receiverID,
      attachment: attachment ?? this.attachment,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
      isSeenBySender: isSeenBySender ?? this.isSeenBySender,
      isSeenByReceiver: isSeenByReceiver ?? this.isSeenByReceiver,
      groupID: groupID ?? this.groupID,
      isSeenAll: isSeenAll ?? this.isSeenAll,
      senderName: senderName ?? this.senderName,
      seenBy: seenBy ?? this.seenBy,
      iv: iv ?? this.iv,
      encryptedAesKeyForSender:
          encryptedAesKeyForSender ?? this.encryptedAesKeyForSender,
      groupReceivers: groupReceivers ?? this.groupReceivers,
      author: author ?? this.author,
    );
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert uploadedUrls
    dynamic _parseUploadedUrls(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      if (value is String) {
        // If it's a string, try to parse it as JSON
        try {
          final parsed = jsonDecode(value);
          return parsed is List ? parsed : [value];
        } catch (e) {
          // If parsing fails, return it as a single-item list
          return [value];
        }
      }
      return [];
    }

    // Helper function to safely convert seenBy
    List<dynamic>? _parseSeenBy(dynamic value) {
      if (value == null) return null;
      if (value is List) return value;
      if (value is String) {
        // If it's a string, try to parse it as JSON
        try {
          final parsed = jsonDecode(value);
          return parsed is List ? parsed : [value];
        } catch (e) {
          // If parsing fails, return it as a single-item list
          return [value];
        }
      }
      return null;
    }

    // Helper function to safely convert groupReceivers
    List<Map<String, String>>? _parseGroupReceivers(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        try {
          return value.map((e) => Map<String, String>.from(e)).toList();
        } catch (e) {
          return null;
        }
      }
      if (value is String) {
        // If it's a string, try to parse it as JSON
        try {
          final parsed = jsonDecode(value);
          if (parsed is List) {
            return parsed.map((e) => Map<String, String>.from(e)).toList();
          }
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return GroupMessage(
      messageID: json['MessageID'] ?? json['messageID'] ?? 0,
      chatID: json['ChatID'] ?? json['chatID'],
      senderID: json['SenderID'] ?? json['senderID'] ?? 0,
      receiverID: json['ReceiverID'] ?? json['receiverID'],
      attachment: json['attachment'],
      uploadedUrls: _parseUploadedUrls(json['uploadedUrls']),
      content: json['Content'] ?? json['content'] ?? '',
      sentAt: json['SentAt'] != null
          ? DateTime.parse(json['SentAt'])
          : json['sentAt'] != null
              ? DateTime.parse(json['sentAt'])
              : DateTime.now(),
      isDeleted: json['IsDeleted'] ?? json['isDeleted'] ?? false,
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? false,
      isSeenBySender: json['IsSeenBySender'] ?? json['isSeenBySender'] ?? true,
      isSeenByReceiver:
          json['IsSeenByReceiver'] ?? json['isSeenByReceiver'] ?? false,
      groupID: json['groupID'] ?? json['GroupID'] ?? 0,
      isSeenAll: json['isSeenAll'] ?? json['IsSeenAll'] ?? 0,
      senderName: json['senderName'] ?? json['SenderName'],
      seenBy: _parseSeenBy(json['seenBy']),
      iv: json['iv'],
      encryptedAesKeyForSender: json['encryptedAesKeyForSender'],
      groupReceivers: _parseGroupReceivers(json['groupReceiversKeys']),
      author: json['author'] ?? json['Author'] ?? 'Unknown',
    );
  }
}

class GroupMember {
  final int userID;
  final String name;
  final String email;
  final String? profilePicture;
  final String role;
  final DateTime joinedAt;
  final bool isActive;

  GroupMember({
    required this.userID,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.role,
    required this.joinedAt,
    required this.isActive,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userID: json['UserID'],
      name: json['Username'],
      email: json['email'] ?? json['Email'] ?? '',
      profilePicture: json['profilePicture'] ?? json['ProfilePicture'],
      role: json['role'] ?? json['Role'] ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : json['JoinedAt'] != null
              ? DateTime.parse(json['JoinedAt'])
              : DateTime.now(),
      isActive: json['isActiveStatus'],
    );
  }
}

class GroupListResponse {
  final List<GroupChat> groupList;

  GroupListResponse({required this.groupList});

  factory GroupListResponse.fromJson(Map<String, dynamic> json) {
    final groups = (json['groupList'] as List)
        .map((group) => GroupChat.fromJson(group))
        .toList();
    return GroupListResponse(groupList: groups);
  }
}
