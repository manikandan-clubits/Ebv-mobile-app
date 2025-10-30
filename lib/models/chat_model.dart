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
  final String adminID;
  final bool isActive;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isSeenByReceiver;
  final bool isSeenBySender;
  final int? chatID;
  final int? receiverID;
  final int? messageID;
  final dynamic unreadCount; // Can be List<Map<String, dynamic>> or int

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
    required this.adminID,
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
      userID: json['UserID'] as int,
      username: json['Username'] as String,
      email: json['Email'] as String,
      firstName: json['FirstName'] as String,
      lastName: json['LastName'] as String,
      profilePicture: json['ProfilePicture'] as String?,
      status: json['Status'] as bool,
      lastSeen: DateTime.parse(json['LastSeen'] as String),
      isMaster: json['IsMaster'],
      adminID: json['AdminID'] as String,
      isActive: json['isActive'] as bool,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      isSeenByReceiver: json['IsSeenByReceiver'] as bool,
      isSeenBySender: json['IsSeenBySender'] as bool,
      chatID: json['ChatID'] as int?,
      receiverID: json['receiverID'] as int?,
      messageID: json['MessageID'] as int?,
      unreadCount: json['unreadCount'],
    );
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
      'unreadCount': unreadCount
    };
  }
}