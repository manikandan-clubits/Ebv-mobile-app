enum MessageType { text, image, video, document, audio }

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
  final bool isSeenBySender;
  final bool isSeenByReceiver;
  final int? chatID;
  final MessageType type;


  Message({
    this.messageID,
    required this.senderID,
    required this.receiverID,
    required this.content,
    required this.attachment,
    required this.uploadedUrls,
    required this.sentAt,
    this.isDeleted = false,
    this.isPinned = false,
    this.isSeenBySender = false,
    this.isSeenByReceiver = false,
    this.chatID,
    this.type = MessageType.text,
  });

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
      isPinned: json['IsPinned'] == true,
      isSeenBySender: json['IsSeenBySender'] == true,
      isSeenByReceiver: json['IsSeenByReceiver'] == true,
      chatID: _parseInt(json['ChatID']),
      type: MessageType.text,
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
    };
  }

  bool isSentBy(int userId) => senderID == userId;
  bool get isSeen => isSeenBySender && isSeenByReceiver;
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
  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
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

  // Helper method to get display name
  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return username;
  }

  // Helper method to get profile picture URL or placeholder
  String get profilePictureUrl {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return ''; // Return empty or placeholder image URL
    }
    return profilePicture!;
  }

  // Helper method to get unread count as integer
  int get unreadCountAsInt {
    if (unreadCount == null) return 0;
    if (unreadCount is int) return unreadCount;
    if (unreadCount is String) {
      return int.tryParse(unreadCount) ?? 0;
    }
    if (unreadCount is List) {
      // If unreadCount is a list, return its length or parse accordingly
      return unreadCount.length;
    }
    return 0;
  }
}