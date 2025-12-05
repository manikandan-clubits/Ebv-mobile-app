# Socket Connection Testing Guide

## ✅ What Was Fixed

1. **Removed duplicate `send_message` emit**
2. **Added comprehensive debugging logs** with clear sections
3. **Enhanced data format handling** for incoming messages
4. **Better error detection** and reporting

---

## 🧪 Step-by-Step Testing

### **Step 1: Verify Socket Connection**

Run the app and look for these logs in order:

```
🔌 Initializing socket connection...
✅ Connected to socket server successfully!
Socket ID: <some-socket-id>
👤 Joining user room with userId: <your-user-id>
✅ join_user event emitted
```

**✅ SUCCESS**: If you see all these logs, socket is connected!  
**❌ FAIL**: If you don't see these, check:
- Internet connection
- Server URL is correct
- Server is running

---

### **Step 2: Open a Chat**

When you open a chat conversation, look for:

```
🚪 Attempting to join chat room: <chat-id>
User ID: <your-user-id>
Socket connected: true
✅ Emitted join_chat (snake_case)
✅ Emitted joinChat (camelCase)
✅ Successfully joined chat room: <chat-id>
```

**✅ SUCCESS**: Chat room joined successfully  
**❌ FAIL**: If `Socket connected: false`, wait a few seconds for connection

---

### **Step 3: Send a Message**

Type a message and send it. Look for this detailed output:

```
📤 ========== SENDING MESSAGE ==========
Socket connected: true
Socket ID: <socket-id>
Current User ID: <user-id>
Is Group Chat: false
Receiver ID: <receiver-id>
Group ID: N/A (Individual)
Chat ID: <chat-id>
Message Content Length: <length>
Message Type: text
Full Message Data: {...}
📤 Emitting 'sendMessage' (camelCase)...
✅ Emitted 'sendMessage'
📤 Emitting 'send_message' (snake_case)...
✅ Emitted 'send_message'
📨 ========== MESSAGE SENT TO SERVER ==========
⏳ Waiting for server confirmation...
Expected events: 'message_sent' or 'messageSent'
============================================
```

**✅ SUCCESS**: Message was sent to server  
**❌ FAIL**: If you see `Socket connected: false`, the socket disconnected

---

### **Step 4: Check for Server Confirmation**

After sending, you should see ONE of these:

```
✅ message_sent confirmation received
Data: {...}
```

OR

```
✅ messageSent confirmation received (camelCase)
Data: {...}
```

**✅ SUCCESS**: Server received and confirmed the message  
**❌ FAIL**: If you don't see this, the server is NOT responding

---

### **Step 5: Receive a Message**

Send a message from the web client. You should see:

```
📩 ========== RECEIVING MESSAGE ==========
Raw data type: _Map<String, dynamic>
Raw data: {...}
📝 Data is already Map<String, dynamic>
📋 Message Map: {...}
📋 Sender ID: <sender-id>
📋 Receiver ID: <receiver-id>
📋 Content: <encrypted-content>
📋 Is Group: false
✅ Message object created successfully
Message ID: <message-id>
Sender ID: <sender-id>
Receiver ID: <receiver-id>
Is Group: false
🔐 Message is encrypted, decrypting...
👤 Decrypting individual message
Private Key available: true
Current User ID: <user-id>
✅ Individual message decrypted
📝 Decrypted content: <actual-message-text>
✅ Final decrypted message created
Final content: <actual-message-text>
➡️ Handling as individual message
✅ ========== MESSAGE RECEIVED SUCCESSFULLY ==========
```

**✅ SUCCESS**: Message was received and decrypted!  
**❌ FAIL**: If you don't see this, check the `🔔 Socket event received` logs

---

### **Step 6: Check ALL Events (Most Important!)**

Look for these logs to see EVERY event the server sends:

```
🔔 Socket event received: <event-name>
Event data: {...}
```

This will show you:
- What events the server is actually sending
- What event names are being used
- What data format is being sent

**This is the KEY to debugging!**

---

## 🔍 Common Issues & Solutions

### Issue 1: Socket Connected but No Messages Sent

**Symptoms:**
```
Socket connected: true
📤 Emitting 'sendMessage'...
✅ Emitted 'sendMessage'
✅ Emitted 'send_message'
⏳ Waiting for server confirmation...
(but no confirmation ever comes)
```

**Diagnosis:**
- Socket is connected ✅
- Message is being emitted ✅
- Server is NOT responding ❌

**Solutions:**
1. Check server logs to see if it received the message
2. Look at `🔔 Socket event received` logs to see what the server IS sending
3. The server might be using a different event name
4. The server might not be set up to handle these events

---

### Issue 2: Socket Connected but No Messages Received

**Symptoms:**
- Web client sends message
- No `📩 RECEIVING MESSAGE` logs appear
- But you see `🔔 Socket event received: <some-event>`

**Diagnosis:**
- Socket is connected ✅
- Server IS sending events ✅
- But using a different event name ❌

**Solutions:**
1. Look at the `🔔` logs to see the actual event name
2. If the event name is different, add a listener for it
3. Example: If you see `🔔 Socket event received: new_message`, add:
   ```dart
   socket.on('new_message', (data) {
     _handleIncomingMessage(data);
   });
   ```

---

### Issue 3: Messages Received but Not Decrypted

**Symptoms:**
```
📩 RECEIVING MESSAGE
...
❌ Missing sender private key. Cannot decrypt message.
```

**Diagnosis:**
- Message received ✅
- Encryption keys missing ❌

**Solutions:**
1. Check if encryption keys are loaded
2. Verify the chatKeysProvider has keys
3. May need to fetch keys first

---

### Issue 4: Server Using Different Event Names

**Symptoms:**
```
🔔 Socket event received: message
Event data: {...}
```
(But no `📩 RECEIVING MESSAGE` logs)

**Diagnosis:**
- Server is emitting `message` instead of `receive_message` or `receiveMessage`

**Solutions:**
Add a listener for the actual event name:
```dart
socket.on('message', (data) {
  log("📩 'message' event received");
  _handleIncomingMessage(data);
});
```

---

## 📊 What the Logs Tell You

| Log Pattern | Meaning | Action |
|------------|---------|--------|
| `Socket connected: true` | Socket is connected | ✅ Good to go |
| `Socket connected: false` | Socket disconnected | ❌ Wait or reconnect |
| `✅ Emitted 'sendMessage'` | Message sent to server | ✅ Message sent |
| `⏳ Waiting for confirmation` | Waiting for server response | ⏳ Check if confirmation arrives |
| `✅ message_sent confirmation` | Server confirmed receipt | ✅ Server got it! |
| `📩 RECEIVING MESSAGE` | Incoming message detected | ✅ Receiving works |
| `🔔 Socket event received: X` | Server sent event X | 📝 Note the event name |
| `❌ ERROR` | Something went wrong | 🔍 Read the error details |

---

## 🎯 Quick Diagnosis Checklist

Run through this checklist in order:

1. [ ] Socket connected? (Look for `✅ Connected to socket server`)
2. [ ] User joined? (Look for `✅ join_user event emitted`)
3. [ ] Chat room joined? (Look for `✅ Successfully joined chat room`)
4. [ ] Message sent? (Look for `✅ Emitted 'sendMessage'`)
5. [ ] Server confirmed? (Look for `✅ message_sent confirmation`)
6. [ ] Can receive? (Send from web, look for `📩 RECEIVING MESSAGE`)
7. [ ] Check all events? (Look at `🔔 Socket event received` logs)

---

## 🚨 If Nothing Works

If messages still don't work after all this:

1. **Copy ALL the logs** from the console
2. **Look for the `🔔 Socket event received` logs** - these show EVERYTHING
3. **Check what event names the server is actually using**
4. **Verify the server is:**
   - Listening for `sendMessage` or `send_message`
   - Emitting `receiveMessage` or `receive_message` or `message_response`
   - Emitting `messageSent` or `message_sent` for confirmations
   - Properly joining users to socket rooms

The comprehensive logging will tell you exactly where the problem is!

---

## 📝 Next Steps

1. Run the app
2. Try sending a message
3. Try receiving a message from web
4. **Share the console logs** if you need help
5. Focus on the `🔔 Socket event received` logs - they're the key!

The logs are now so detailed that you'll be able to pinpoint exactly where the issue is! 🎯
