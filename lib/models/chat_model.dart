enum MessageType { text, image, video, document, audio }

// models/chat_keys_model.dart
class ChatKeys {
  final String publicKey;
  final String privateKey;

  ChatKeys({
    required this.publicKey,
    required this.privateKey,
  });

  factory ChatKeys.fromJson(Map<String, dynamic> json) {
    return ChatKeys(
      publicKey: json['publicKey'] ?? '',
      privateKey: json['privateKey'] ?? '',
    );
  }

  ChatKeys copyWith({
    String? publicKey,
    String? privateKey,
  }) {
    return ChatKeys(
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
    );
  }
}

class ReceiverPublicKey {
  final int recvId;
  final String publicKey;

  ReceiverPublicKey({
    required this.recvId,
    required this.publicKey,
  });

  factory ReceiverPublicKey.fromJson(Map<String, dynamic> json) {
    return ReceiverPublicKey(
      recvId: json['recvId'] ?? '',
      publicKey: json['publicKey'] ?? '',
    );
  }
}



class EncryptedMessage {
  final String encryptedText;
  final String iv;
  final String encryptedAesKeyForSender;
  final String encryptedAesKeyForReceiver;
  final String senderId;
  final String receiverId;

  EncryptedMessage({
    required this.encryptedText,
    required this.iv,
    required this.encryptedAesKeyForSender,
    required this.encryptedAesKeyForReceiver,
    required this.senderId,
    required this.receiverId,
  });
}

class GroupEncryptedMessage {
  final String encryptedText;
  final String iv;
  final String encryptedAesKeyForSender;
  final List<Map<String, String>> groupReceivers;
  final String groupId;

  GroupEncryptedMessage({
    required this.encryptedText,
    required this.iv,
    required this.encryptedAesKeyForSender,
    required this.groupReceivers,
    required this.groupId,
  });
}

class GroupPublicKey {
  final String userId;
  final String publicKey;

  GroupPublicKey({
    required this.userId,
    required this.publicKey,
  });
}




class Message {
  final int? messageID;
  final int senderID;
  final int receiverID;
  final String content;
  final String attachment;
  final List<dynamic> uploadedUrls;
  final DateTime sentAt;
  final bool isDeleted;
  final bool isPinned;
  final bool isGroup;
  final bool isSeenBySender;
  final bool isSeenByReceiver;
  final int? chatID;
  final MessageType type;

  final String? iv;
  final String? encryptedAesKeyForSender;
  final String? encryptedAesKeyForReceiver;
  final List<Map<String, String>>? groupReceivers;
  final bool isSending;
  final String? error;

  Message({
    this.messageID,
    required this.senderID,
    required this.receiverID,
    required this.content,
    required this.attachment,
    required this.uploadedUrls,
    required this.sentAt,
    this.isDeleted = false,
    this.isGroup = false,
    this.isPinned = false,
    this.isSeenBySender = false,
    this.isSeenByReceiver = false,
    this.chatID,
    this.type = MessageType.text,
    this.iv,
    this.encryptedAesKeyForSender,
    this.encryptedAesKeyForReceiver,
    this.groupReceivers,
    this.isSending = false,
    this.error,
  });


  Message copyWith({
    int? messageID,
    String? content,
    String? iv,
    String? encryptedAesKeyForSender,
    String? encryptedAesKeyForReceiver,
    List<Map<String, String>>? groupReceivers,
    bool? isSending,
    String? error,
    bool? isSeenBySender,
    bool? isSeenByReceiver

  }) {
    return Message(
      messageID: messageID,
      senderID: senderID,
      receiverID: receiverID,
      content: content ?? this.content,
      attachment: attachment,
      uploadedUrls: uploadedUrls,
      sentAt: sentAt,
      isDeleted: isDeleted,
      isGroup: isGroup,
      isPinned: isPinned,
      isSeenBySender: isSeenBySender ?? this.isSeenBySender,
      isSeenByReceiver: isSeenByReceiver ?? this.isSeenByReceiver,
      chatID: chatID,
      type: type,
      iv: iv ?? this.iv,
      encryptedAesKeyForSender: encryptedAesKeyForSender ?? this.encryptedAesKeyForSender,
      encryptedAesKeyForReceiver: encryptedAesKeyForReceiver ?? this.encryptedAesKeyForReceiver,
      groupReceivers: groupReceivers ?? this.groupReceivers,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }



  factory Message.fromJson(Map<String, dynamic> json) {
    final uploadedUrls = (json['uploadedUrls'] as List?)?.cast<String>() ?? [];

    return Message(
      messageID: _parseInt(json['MessageID']),
      senderID: _parseInt(json['SenderID']) ?? 0,
      receiverID: _parseInt(json['ReceiverID']) ?? 0, // Use ReceiverID
      content: json['Content']?.toString() ?? '',
      attachment: json['attachment']?.toString() ?? '',
      uploadedUrls: uploadedUrls,
      sentAt: _parseDateTime(json['SentAt']),
      isDeleted: json['IsDeleted'] == true,
      isGroup: json['isGroup'] == true,
      isPinned: json['IsPinned'] == true,
      isSeenBySender: json['IsSeenBySender'] == true,
      isSeenByReceiver: json['IsSeenByReceiver'] == true,
      chatID: _parseInt(json['ChatID']),
      type: MessageType.text,
      iv: json['iv']?.toString(),
      encryptedAesKeyForSender: json['encryptedAesKeyForSender']?.toString(),
      encryptedAesKeyForReceiver: json['encryptedAesKeyForReceiver']?.toString(),
      groupReceivers: json['groupReceivers'] != null
          ? List<Map<String, String>>.from(json['groupReceivers'])
          : null,


    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }


  Map<String, dynamic> toJson() {
    return {
      if (messageID != null) 'MessageID': messageID,
      'SenderID': senderID,
      'ReceiverID': receiverID,
      'Content': content,
      'attachment': attachment,
      'SentAt': sentAt.toIso8601String(),
      'IsDeleted': isDeleted,
      'IsPinned': isPinned,
      'IsSeenBySender': isSeenBySender,
      'IsSeenByReceiver': isSeenByReceiver,
      if (chatID != null) 'ChatID': chatID,
      'Type': type.name, // Convert enum to string
      'isSending': isSending,
      'error': error,
    };
  }

  bool isSentBy(int userId) => senderID == userId;
  bool get isSeen => isSeenBySender && isSeenByReceiver!;
}

class ChatUser {
  final int userID;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final bool status;
  final DateTime lastSeen;
  final dynamic isMaster;
  final String? adminID;
  final bool isActive;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isSeenByReceiver;
  final bool isSeenBySender;
  final int? chatID;
  final int? receiverID;
  final int? messageID;
  final dynamic unreadCount;

  ChatUser({
    required this.userID,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.status,
    required this.lastSeen,
    this.isMaster,
    this.adminID,
    required this.isActive,
    this.lastMessage,
    this.lastMessageTime,
    required this.isSeenByReceiver,
    required this.isSeenBySender,
    this.chatID,
    this.receiverID,
    this.messageID,
    required this.unreadCount,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      userID: _parseInt(json['UserID']),
      username: _parseString(json['Username']),
      email: _parseString(json['Email']),
      firstName: _parseString(json['FirstName']),
      lastName: _parseString(json['LastName']),
      profilePicture: _parseString(json['ProfilePicture']),
      status: _parseBool(json['Status']),
      lastSeen: _parseDateTime(json['LastSeen']),
      isMaster: json['IsMaster'],
      adminID: _parseString(json['AdminID']),
      isActive: _parseBool(json['isActive']),
      lastMessage: _parseString(json['lastMessage']),
      lastMessageTime: _parseDateTime(json['lastMessageTime']),
      isSeenByReceiver: _parseBool(json['IsSeenByReceiver']),
      isSeenBySender: _parseBool(json['IsSeenBySender']),
      chatID: _parseInt(json['ChatID']),
      receiverID: _parseInt(json['receiverID']),
      messageID: _parseInt(json['MessageID']),
      unreadCount: json['unreadCount'],
    );
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'UserID': userID,
      'Username': username,
      'Email': email,
      'FirstName': firstName,
      'LastName': lastName,
      'ProfilePicture': profilePicture,
      'Status': status,
      'LastSeen': lastSeen.toIso8601String(),
      'IsMaster': isMaster,
      'AdminID': adminID,
      'isActive': isActive,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'IsSeenByReceiver': isSeenByReceiver,
      'IsSeenBySender': isSeenBySender,
      'ChatID': chatID,
      'receiverID': receiverID,
      'MessageID': messageID,
      'unreadCount': unreadCount,
    };
  }

  ChatUser copyWith({
    int? userID,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? profilePicture,
    bool? status,
    DateTime? lastSeen,
    dynamic isMaster,
    String? adminID,
    bool? isActive,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? isSeenByReceiver,
    bool? isSeenBySender,
    int? chatID,
    int? receiverID,
    int? messageID,
    dynamic unreadCount,
  }) {
    return ChatUser(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicture: profilePicture ?? this.profilePicture,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isMaster: isMaster ?? this.isMaster,
      adminID: adminID ?? this.adminID,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isSeenByReceiver: isSeenByReceiver ?? this.isSeenByReceiver,
      isSeenBySender: isSeenBySender ?? this.isSeenBySender,
      chatID: chatID ?? this.chatID,
      receiverID: receiverID ?? this.receiverID,
      messageID: messageID ?? this.messageID,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'ChatUser(userID: $userID, username: $username, email: $email, firstName: $firstName, lastName: $lastName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.userID == userID;
  }

  @override
  int get hashCode => userID.hashCode;
}