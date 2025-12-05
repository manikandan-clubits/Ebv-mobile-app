# Socket Communication Debugging Guide

## Issues Identified in chat_provider.dart

### 1. **Socket Connection Not Checked Before Sending Messages**
**Location**: Line 889 in `sendMessage()` method

**Problem**: The code emits `send_message` without verifying if the socket is connected. This causes messages to fail silently.

**Current Code**:
```dart
socket.emit('send_message', messageData);
```

**Fix Needed**:
```dart
// Check socket connection before sending
if (!socket.connected) {
  log('❌ Socket not connected. Connection status: ${state.isConnected}');
  log('Attempting to reconnect...');
  socket.connect();
  
  // Wait briefly for connection
  await Future.delayed(const Duration(milliseconds: 500));
  
  if (!socket.connected) {
    throw Exception('Socket is not connected. Please check your internet connection.');
  }
}

log('📤 Sending message via socket...');
log('Socket connected: ${socket.connected}');
log('Socket ID: ${socket.id}');
log('Message data: $messageData');

// Emit the message
socket.emit('send_message', messageData);
log('✅ Message emitted to socket successfully');
```

### 2. **Insufficient Logging in Socket Event Handlers**
**Location**: Lines 146-180 in `connectToSocket()` method

**Problem**: Minimal logging makes it difficult to debug socket connection and message reception issues.

**Fixes Needed**:

#### onConnect Handler:
```dart
socket.onConnect((_) {\n  log('✅ Socket Connected to server successfully');\n  log('Socket ID: ${socket.id}');\n  state = state.copyWith(isConnected: true);\n\n  if (_currentUserId != null) {\n    log('Emitting join_user with userId: $_currentUserId');\n    socket.emit('join_user', {'userId': _currentUserId});\n  } else {\n    log('⚠️ Warning: _currentUserId is null, cannot join user');\n  }\n});
```

#### onDisconnect Handler:
```dart
socket.onDisconnect((_) {\n  log('❌ Socket Disconnected from server');\n  state = state.copyWith(isConnected: false);\n});
```

#### onConnectError Handler:
```dart
socket.onConnectError((error) {\n  log('❌ Socket Connection Error: $error');\n  state = state.copyWith(isConnected: false, error: 'Socket connection error: $error');\n});
```

#### receive_message Handler:
```dart
socket.on('receive_message', (data) {\n  log('📩 Received message from socket: $data');\n  try {\n    _handleIncomingMessage(data);\n    log('✅ Message handled successfully');\n  } catch (e, stackTrace) {\n    log('❌ Error in receive_message handler: $e');\n    log('Stack trace: $stackTrace');\n  }\n});
```

#### Additional Error Listeners:
```dart
// Add error event listener
socket.on('error', (error) {\n  log('❌ Socket error event: $error');\n  state = state.copyWith(error: 'Socket error: $error');\n});

// Add connect_error listener for more detailed error info
socket.on('connect_error', (error) {\n  log('❌ Socket connect_error event: $error');\n});
```

### 3. **Insufficient Error Handling in _handleIncomingMessage**
**Location**: Lines 287-377 in `_handleIncomingMessage()` method

**Problem**: Limited logging makes it hard to identify where message processing fails.

**Enhanced Logging Needed**:
```dart
Future<void> _handleIncomingMessage(dynamic data) async {
  try {
    log('🔍 Processing incoming message...');
    log('Raw data type: ${data.runtimeType}');
    log('Raw data: ${data.toString()}');
    
    final chatKeysState = ref.read(chatKeysProvider);
    final senderPrivateKey = chatKeysState.senderKeys?.privateKey;
    final currentUserId = state.currentUserId;

    log('Current user ID: $currentUserId');
    log('Sender private key available: ${senderPrivateKey != null}');

    if (senderPrivateKey == null) {
      log('❌ Missing sender private key. Cannot decrypt message.');
      log('Available keys: ${chatKeysState.receiverKeys.keys.toList()}');
      return;
    }

    if (currentUserId == null) {
      log('❌ Missing current user ID. Cannot decrypt message.');
      return;
    }

    // Validate data format
    if (data is! Map) {
      log('❌ Invalid data format. Expected Map, got ${data.runtimeType}');
      return;
    }
    
    final Map<String, dynamic> messageMap = Map<String, dynamic>.from(data);
    log('📝 Message map keys: ${messageMap.keys.toList()}');
    log('📝 Message map: $messageMap');

    Message message;
    try {
      message = Message.fromJson(messageMap);
      log('✅ Message object created successfully');
      log('Message ID: ${message.messageID}');
      log('Sender ID: ${message.senderID}');
      log('Receiver ID: ${message.receiverID}');
      log('Is Group: ${message.isGroup}');
    } catch (e) {
      log('❌ Failed to parse message from JSON: $e');
      return;
    }
    
    // Rest of the method with enhanced logging...
  } catch (e, stackTrace) {
    log('❌ Error processing received message: $e');
    log('Stack trace: $stackTrace');
    state = state.copyWith(
      error: 'Failed to process incoming message: ${e.toString()}',
    );
  }
}
```

### 4. **No Error Feedback to User on Send Failure**
**Location**: Lines 891-904 in `sendMessage()` catch block

**Problem**: When message sending fails, the temporary message remains in "sending" state without error indication.

**Fix Needed**:
```dart
catch (error, stackTrace) {
  log('❌ Error sending message: $error');
  log('Stack trace: $stackTrace');

  // Update the temporary message to show error state
  final updatedMessages = state.messages.map((message) {
    if (message.messageID == tempMessageId) {
      return message.copyWith(
        isSending: false,
        error: error.toString(),
      );
    }
    return message;
  }).toList();

  state = state.copyWith(
    messages: updatedMessages,
    error: 'Failed to send message: ${error.toString()}',
  );
  
  // Show error to user
  Fluttertoast.showToast(
    msg: 'Failed to send message: ${error.toString()}',
    toastLength: Toast.LENGTH_LONG,
  );
  
  rethrow;
}
```

## Testing Steps

### 1. **Check Socket Connection Status**
Add this method to check socket status:
```dart
void logSocketStatus() {
  log('=== Socket Status ===');
  log('Connected: ${socket.connected}');
  log('Socket ID: ${socket.id}');
  log('State isConnected: ${state.isConnected}');
  log('Current User ID: $_currentUserId');
  log('====================');
}
```

Call this before sending messages to verify connection.

### 2. **Monitor Console Logs**
When testing, look for these log patterns:

**Successful Connection**:
```
✅ Socket Connected to server successfully
Socket ID: <socket_id>
Emitting join_user with userId: <user_id>
```

**Successful Message Send**:
```
📤 Sending message via socket...
Socket connected: true
Socket ID: <socket_id>
Message data: {...}
✅ Message emitted to socket successfully
```

**Successful Message Receive**:
```
📩 Received message from socket: {...}
🔍 Processing incoming message...
✅ Message object created successfully
✅ Message handled successfully
```

### 3. **Common Issues and Solutions**

#### Issue: Socket not connecting
**Symptoms**: No "✅ Socket Connected" log
**Solutions**:
- Check internet connection
- Verify server URL is accessible
- Check firewall settings
- Verify WebSocket support

#### Issue: Messages not sending
**Symptoms**: "❌ Socket not connected" log
**Solutions**:
- Wait for socket to connect before sending
- Check if `_currentUserId` is set
- Verify `join_user` was emitted successfully

#### Issue: Messages not receiving
**Symptoms**: No "📩 Received message" log
**Solutions**:
- Verify sender emitted message correctly
- Check if receiver joined the chat room
- Verify encryption keys are available
- Check server-side socket emission

#### Issue: Decryption failures
**Symptoms**: "❌ Failed to decrypt" logs
**Solutions**:
- Verify sender and receiver public keys match
- Check if encryption keys are properly stored
- Verify IV and encrypted AES keys are transmitted
- Check encryption/decryption service implementation

## React Web Integration Notes

Since you mentioned "not reflected on react web using socket", here's what to check:

### 1. **Server-Side Socket Events**
Ensure your server emits events to all connected clients:
```javascript
// Server should emit to specific user or room
io.to(receiverId).emit('receive_message', messageData);
// OR
io.to(chatRoomId).emit('receive_message', messageData);
```

### 2. **React Web Socket Listener**
Ensure React web app has matching socket listeners:
```javascript
socket.on('receive_message', (data) => {
  console.log('Received message:', data);
  // Update React state with new message
});
```

### 3. **Cross-Platform Data Format**
Ensure message data format is consistent between Flutter and React:
- Use same field names (camelCase vs PascalCase)
- Ensure encryption format is compatible
- Verify timestamp formats match

### 4. **Socket Room Management**
Both Flutter and React clients must join the same room:
```dart
// Flutter
socket.emit('join_chat', {'chatId': chatId, 'userId': userId});
```

```javascript
// React
socket.emit('join_chat', {chatId: chatId, userId: userId});
```

## Quick Fix Checklist

- [ ] Add socket connection check before `socket.emit('send_message')`
- [ ] Add comprehensive logging to all socket event handlers
- [ ] Add error handling with try-catch in socket listeners
- [ ] Add user feedback (toast) on message send failure
- [ ] Update temporary message state on error
- [ ] Add socket status logging method
- [ ] Verify React web has matching socket listeners
- [ ] Ensure server emits to correct rooms/users
- [ ] Verify encryption keys are available on both platforms
- [ ] Test cross-platform message exchange

## Implementation Priority

1. **High Priority** (Do First):
   - Add socket connection check in `sendMessage()`
   - Add comprehensive logging to debug current issues
   - Add error handling in `receive_message` handler

2. **Medium Priority** (Do Next):
   - Enhance `_handleIncomingMessage()` logging
   - Add user feedback on errors
   - Update message state on send failure

3. **Low Priority** (Nice to Have):
   - Add socket status monitoring method
   - Add reconnection retry logic
   - Add message queue for offline sending
