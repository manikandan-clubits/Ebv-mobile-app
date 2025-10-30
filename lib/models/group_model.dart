
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
      groupID:json['GroupID'] ?? 0,
      name:  json['GroupName'] ?? 'Unknown Group',
      description: json['description'] ?? json['Description'],
      profilePicture: json['profilePicture'] ?? json['ProfilePicture'],
      createdBy: json['createdBy'] ?? json['CreatedBy'] ?? 0,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'])
          : json['CreatedAt'] != null
            ? DateTime.parse(json['CreatedAt'])
            : DateTime.now(),
      lastMessage:  json['lastMessage'],
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
  final String content;
  final DateTime sentAt;
  final String attachment;
  final bool isDeleted;
  final bool isPinned;
  final bool isSeenBySender;
  final List<dynamic> uploadedUrls;

  final bool isSeenByReceiver;
  final int groupID;
  final int isSeenAll;
  final String? author;

  GroupMessage({
    required this.messageID,
    this.chatID,
    required this.attachment,
    required this.senderID,
    this.receiverID,
    required this.content,
    required this.sentAt,
    required this.uploadedUrls,
    required this.isDeleted,
    required this.isPinned,
    required this.isSeenBySender,
    required this.isSeenByReceiver,
    required this.groupID,
    required this.isSeenAll,
    this.author,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final uploadedUrls = (json['uploadedUrls'] as List?)?.cast<String>() ?? [];
    return GroupMessage(
      messageID: json['messageID'] ?? json['MessageID'] ?? 0,
      chatID: json['chatID'] ?? json['ChatID'],
      senderID: json['senderID'] ?? json['SenderID'] ?? 0,
      receiverID: json['receiverID'] ?? json['ReceiverID'],
      uploadedUrls: uploadedUrls,
        attachment: json['attachment']?.toString() ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : json['SentAt'] != null
            ? DateTime.parse(json['SentAt'])
            : DateTime.now(),
      isDeleted: json['isDeleted'] ?? json['IsDeleted'] ?? false,
      isPinned: json['isPinned'] ?? json['IsPinned'] ?? false,
      isSeenBySender: json['isSeenBySender'] ?? json['IsSeenBySender'] ?? true,
      isSeenByReceiver: json['isSeenByReceiver'] ?? json['IsSeenByReceiver'] ?? false,
      groupID: json['groupID'] ?? json['GroupID'] ?? 0,
      isSeenAll: json['isSeenAll'] ?? json['IsSeenAll'] ?? 0,
      author: json['author'] ?? json['Author'],
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