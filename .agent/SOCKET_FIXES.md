# Socket Communication Fixes

## Issues Fixed

### 1. **send_message Event Not Working**
**Problem**: The mobile app was emitting `send_message` but the React web client was expecting `sendMessage` (camelCase).

**Solution**: 
- Modified the `sendMessage` method to emit both event names for compatibility:
  - `sendMessage` (camelCase - for web client)
  - `send_message` (snake_case - for backward compatibility)

**Location**: Line 889-891 in `chat_provider.dart`

```dart
// Emit with both event names for compatibility
socket.emit('sendMessage', messageData);
socket.emit('send_message', messageData);
```

---

### 2. **receive_message Event Not Working Properly**
**Problem**: The mobile app was only listening to `receive_message`, but the server might be emitting different event names.

**Solution**: 
- Added multiple event listeners for better compatibility:
  - `receive_message` (snake_case)
  - `receiveMessage` (camelCase)
  - `message_response` (alternative event name)
  - `message_sent` and `messageSent` (for confirmations)

**Location**: Lines 163-195 in `chat_provider.dart`

```dart
// Listen for both event name formats for compatibility
socket.on('receive_message', (data) {
  log("receive_message event received");
  _handleIncomingMessage(data);
});

socket.on('receiveMessage', (data) {
  log("receiveMessage event received");
  _handleIncomingMessage(data);
});

socket.on('message_response', (data) {
  log("message_response event received");
  _handleIncomingMessage(data);
});
```

---

### 3. **Improved Message Handling**
**Problem**: The `_handleIncomingMessage` method wasn't handling different data formats properly.

**Solution**: 
- Added support for multiple data formats:
  - JSON strings
  - `Map<String, dynamic>`
  - Generic `Map` objects
- Added null safety checks
- Improved error handling with detailed logging
- Fixed decrypted content format handling

**Location**: Lines 287-377 in `chat_provider.dart`

**Key improvements**:
```dart
// Handle different data formats
if (data is String) {
  messageMap = Map<String, dynamic>.from(jsonDecode(data));
} else if (data is Map<String, dynamic>) {
  messageMap = data;
} else if (data is Map) {
  messageMap = Map<String, dynamic>.from(data);
}

// Ensure decryptedContent has the expected format
if (decryptedContent == null || 
    (decryptedContent is Map && decryptedContent['text'] == null)) {
  decryptedContent = {'text': '[Decryption Failed]'};
}
```

---

### 4. **Improved Message Confirmation Handling**
**Problem**: The `_handleMessageSentConfirmation` method only accepted `Map<String, dynamic>` and used fixed field names.

**Solution**: 
- Modified to accept `dynamic` data type
- Added support for different field name formats:
  - `MessageID`, `messageID`, `messageId`
  - `tempMessageId`, `TempMessageId`
- Added detailed logging for debugging

**Location**: Lines 924-979 in `chat_provider.dart`

```dart
// Try different field name formats
final serverMessageId = confirmationData['MessageID'] ?? 
                        confirmationData['messageID'] ?? 
                        confirmationData['messageId'];
final tempMessageId = confirmationData['tempMessageId'] ?? 
                     confirmationData['TempMessageId'];
```

---

## Testing Recommendations

1. **Test sending messages from mobile to web**:
   - Send a text message from the mobile app
   - Verify it appears on the React web client
   - Check the browser console for the event name received

2. **Test receiving messages from web to mobile**:
   - Send a message from the React web client
   - Verify it appears on the mobile app
   - Check the mobile app logs for which event was received

3. **Test message confirmations**:
   - Send a message and verify the "sending" state changes to "sent"
   - Check that the temporary message ID is replaced with the server message ID

4. **Check encryption/decryption**:
   - Verify that encrypted messages are properly decrypted on both ends
   - Check for any "[Decryption Failed]" messages

---

## Debugging Tips

The code now includes extensive logging. Look for these log messages:

- `"receive_message event received"` - Message received via snake_case event
- `"receiveMessage event received"` - Message received via camelCase event
- `"Message emitted to server"` - Message sent successfully
- `"Decrypted message content: ..."` - Shows the decrypted content
- `"Message confirmation processed successfully"` - Confirmation handled

If issues persist, check:
1. The exact event names the server is emitting
2. The data format being sent/received
3. Network logs in both mobile and web clients
4. Server-side socket event handlers
