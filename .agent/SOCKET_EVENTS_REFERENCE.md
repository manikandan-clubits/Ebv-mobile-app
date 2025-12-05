# Socket Events Quick Reference

## Events the Mobile App EMITS (Sends to Server)

| Event Name (snake_case) | Event Name (camelCase) | When | Data |
|------------------------|----------------------|------|------|
| `join_user` | - | On socket connect | `{userId: int}` |
| `join_chat` | `joinChat` | When opening a chat | `{chatId: string, userId: int}` |
| `send_message` | `sendMessage` | When sending a message | See below |
| `typing` | - | When user is typing | `{senderID, receiverID, groupID, isGroupChat}` |
| `message_read` | - | When marking messages as read | `{chatId, messageIds[], readerId}` |
| `leave_chat` | - | When leaving a chat | `{chatId, userId}` |

### send_message / sendMessage Data Structure
```dart
{
  "author": string,
  "receiverID": int (or currentUserId for groups),
  "groupID": int (or '' for individual),
  "SenderID": string,
  "Content": string (encrypted),
  "SentAt": ISO8601 string,
  "IsDeleted": bool,
  "IsPinned": bool,
  "isGroupChat": bool,
  "uploadedUrls": array,
  "error": string,
  "tempMessageId": int,
  "chatID": int (optional, for individual chats),
  "type": string (text/image/video/document/audio),
  "iv": string (encryption IV),
  "encryptedAesKeyForSender": string,
  "encryptedAesKeyForReceiver": string (individual),
  "groupReceiversKeys": array (group)
}
```

---

## Events the Mobile App LISTENS FOR (Receives from Server)

| Event Name | Alternative Names | Purpose | Expected Data |
|-----------|------------------|---------|---------------|
| `receive_message` | `receiveMessage`, `message_response` | Receive new messages | Message object |
| `message_sent` | `messageSent` | Confirmation of sent message | `{MessageID, tempMessageId}` |
| `message_delivered` | - | Message delivery status | `{messageId}` |
| `message_read` | - | Message read status | `{messageId}` |
| `error` | - | Socket errors | Error object |
| **ANY** | - | Catch-all for debugging | Any data |

---

## Connection Flow

```
1. App starts
   ↓
2. 🔌 Initialize socket connection
   ↓
3. ✅ Connected to server
   ↓
4. 👤 Emit 'join_user' with userId
   ↓
5. User opens a chat
   ↓
6. 🚪 Emit 'join_chat' / 'joinChat' with chatId and userId
   ↓
7. Ready to send/receive messages!
```

---

## Message Send Flow

```
1. User types and sends message
   ↓
2. Create temporary message (for instant UI update)
   ↓
3. Add to local state (message appears immediately)
   ↓
4. Encrypt message content
   ↓
5. 📤 Emit 'sendMessage' and 'send_message'
   ↓
6. Wait for confirmation...
   ↓
7. ✅ Receive 'message_sent' or 'messageSent'
   ↓
8. Update message ID from temp to server ID
   ↓
9. Message marked as sent ✓
```

---

## Message Receive Flow

```
1. Server emits message event
   ↓
2. 📩 Receive 'receive_message' or 'receiveMessage'
   ↓
3. Validate data format
   ↓
4. Parse message object
   ↓
5. Check if encrypted
   ↓
6. Decrypt content (if encrypted)
   ↓
7. Add to local state
   ↓
8. Message appears in UI ✓
```

---

## Debugging Checklist

When messages aren't working, check these in order:

- [ ] Socket is connected (`Socket connected: true`)
- [ ] User joined with `join_user` event
- [ ] Chat room joined with `join_chat` / `joinChat`
- [ ] Message emitted with both `sendMessage` and `send_message`
- [ ] Check `🔔 Socket event received` logs for ALL events
- [ ] Verify event names match what server expects
- [ ] Check encryption/decryption is working
- [ ] Verify chatId and userId are correct
- [ ] Check server logs to see if message was received
- [ ] Verify both clients are in the same chat room

---

## Log Emoji Guide

| Emoji | Meaning |
|-------|---------|
| 🔌 | Socket initialization |
| ✅ | Success |
| ❌ | Error |
| 📩 | Incoming message |
| 📤 | Outgoing message |
| 📨 | Message sent successfully |
| 📬 | Message delivered |
| 👁️ | Message read |
| 🚪 | Joining chat room |
| 👤 | User operation |
| 🔄 | Reconnection |
| 🔔 | Generic socket event (catch-all) |
| ⚠️ | Warning |

---

## Testing Commands

### Test Socket Connection
1. Open app
2. Look for: `✅ Connected to socket server successfully!`
3. Look for: `Socket ID: <id>`

### Test Message Send
1. Send message
2. Look for: `📤 Preparing to send message...`
3. Look for: `✅ Emitted 'sendMessage' (camelCase)`
4. Look for: `✅ Emitted 'send_message' (snake_case)`
5. Look for: `✅ message_sent confirmation received`

### Test Message Receive
1. Send from web client
2. Look for: `📩 receive_message event received` OR `📩 receiveMessage event received`
3. Look for: `Decrypted message content: <text>`

### See All Events
Look for: `🔔 Socket event received: <event-name>`
This shows EVERY event, even ones we're not listening for!
