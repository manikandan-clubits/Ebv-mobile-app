
import 'package:ebv/screens/chats/single_chat_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../provider/chat_provider.dart';
import 'package:intl/intl.dart';


class ChatListItem extends ConsumerWidget {
  final ChatUser chat;

  const ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    // Get messages for this specific chat
    final chatMessages = chatState.messages.where((m) {
      final messageChatId = m.chatID?.toString() ?? '';
      final currentChatId = chat.chatID?.toString() ?? '';
      return messageChatId == currentChatId;
    }).toList();

    // Sort by timestamp (newest first)
    chatMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

    final lastMessage = chatMessages.isNotEmpty ? chatMessages.first : null;
    final lastMessageContent =
        lastMessage?.content ?? chat.lastMessage ?? 'Start a conversation';
    final lastMessageTime = lastMessage?.sentAt ?? chat.lastSeen;

    // Calculate unread count
    final unreadCount = chatMessages.where((m) {
      return m.receiverID == chatState.currentChatId &&
          !m.isSeenByReceiver &&
          m.senderID != chatState.currentChatId;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chat.chatID!.toString(),
                    chatName:
                    chat.firstName.isNotEmpty ? chat.firstName : 'Unknown',
                    chat: chat,

                  ),
                ),
              );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: chat.profilePicture.toString().isNotEmpty
                              ? NetworkImage(chat.profilePicture.toString())
                              : AssetImage('assets/images/profile.png') as ImageProvider,
                        ),
                      ),
                    ),
                    if (chat.isActive)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.firstName.isNotEmpty
                                  ? '${chat.firstName}${chat.userID}'
                                  : 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessageContent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread count
                if (unreadCount > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }
}
