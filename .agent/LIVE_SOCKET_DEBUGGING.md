# Live Socket Send/Receive Debugging Guide

## Changes Made

### 1. **Enhanced Socket Connection**
- Added reconnection logic with 5 retry attempts
- Added detailed logging for all connection events
- Added `onAny` listener to catch ALL socket events for debugging

### 2. **Multiple Event Listeners**
The app now listens to multiple event name formats:
- `receive_message` / `receiveMessage` / `message_response`
- `message_sent` / `messageSent`
- `message_delivered`
- `message_read`

### 3. **Multiple Event Emitters**
The app now emits both event name formats:
- `sendMessage` (camelCase) + `send_message` (snake_case)
- `joinChat` (camelCase) + `join_chat` (snake_case)
- `join_user` (when connecting)

### 4. **Comprehensive Logging**
All socket operations now have emoji-prefixed logs:
- 🔌 Socket initialization
- ✅ Successful operations
- ❌ Errors
- 📩 Incoming messages
- 📤 Outgoing messages
- 🚪 Joining chat rooms
- 👤 User operations
- 🔄 Reconnection attempts
- 🔔 All socket events (via onAny)

---

## How to Test

### Step 1: Check Socket Connection
1. Open the app
2. Look for these logs in the console:
   ```
   🔌 Initializing socket connection...
   ✅ Connected to socket server successfully!
   Socket ID: <some-id>
   👤 Joining user room with userId: <your-user-id>
   ✅ join_user event emitted
   ```

**If you don't see these logs:**
- Check your internet connection
- Verify the server URL is correct
- Check if the server is running

### Step 2: Check Chat Room Join
1. Open a chat conversation
2. Look for these logs:
   ```
   🚪 Attempting to join chat room: <chat-id>
   User ID: <your-user-id>
   Socket connected: true
   ✅ Emitted join_chat (snake_case)
   ✅ Emitted joinChat (camelCase)
   ✅ Successfully joined chat room: <chat-id>
   ```

**If socket.connected is false:**
- The socket is not connected
- Wait a few seconds and try again
- Check the connection logs from Step 1

### Step 3: Test Sending Messages
1. Type a message and send it
2. Look for these logs:
   ```
   📤 Preparing to send message...
   Message data: {...}
   Socket connected: true
   ✅ Emitted 'sendMessage' (camelCase)
   ✅ Emitted 'send_message' (snake_case)
   📨 Message sent to server successfully
   ```

3. Then look for confirmation:
   ```
   ✅ message_sent confirmation received
   Data: {...}
   ```
   OR
   ```
   ✅ messageSent confirmation received (camelCase)
   Data: {...}
   ```

**If you don't see the confirmation:**
- The server might not be sending back a confirmation
- Check the server logs to see if it received the message
- Look for the `🔔 Socket event received:` logs to see what events are coming

### Step 4: Test Receiving Messages
1. Send a message from the web client
2. Look for these logs on mobile:
   ```
   📩 receive_message event received
   Data: {...}
   Processing incoming message: {...}
   ```
   OR
   ```
   📩 receiveMessage event received (camelCase)
   Data: {...}
   ```

3. Check for decryption logs:
   ```
   Decrypting individual message
   Decrypted message content: <message-text>
   ```

**If you don't see these logs:**
- The server might be emitting a different event name
- Check the `🔔 Socket event received:` logs to see ALL events
- The event name might be completely different

### Step 5: Check All Events (Most Important!)
Look for logs like:
```
🔔 Socket event received: <event-name>
Event data: {...}
```

This will show you **EVERY** event the server is sending, even if we're not specifically listening for it.

---

## Common Issues & Solutions

### Issue 1: Socket Not Connecting
**Symptoms:**
- No "✅ Connected to socket server" log
- `Socket connected: false` in logs

**Solutions:**
1. Check server URL is correct
2. Check server is running
3. Check firewall/network settings
4. Try restarting the app

### Issue 2: Messages Not Sending
**Symptoms:**
- See "📤 Preparing to send message" but no confirmation
- `Socket connected: false`

**Solutions:**
1. Ensure socket is connected first
2. Check if you joined the chat room
3. Look at server logs to see if message was received
4. Check the `🔔 Socket event received` logs for any error events

### Issue 3: Messages Not Receiving
**Symptoms:**
- Web client sends message but mobile doesn't receive
- No "📩 receive_message" logs

**Solutions:**
1. Check the `🔔 Socket event received` logs to see what event name the server is using
2. The server might be using a different event name
3. Check if you properly joined the chat room
4. Verify you're in the same chat room as the web client

### Issue 4: Wrong Event Names
**Symptoms:**
- See `🔔 Socket event received: some_other_event`
- Not seeing expected events

**Solutions:**
1. Note the exact event name from the `🔔` logs
2. Add a listener for that specific event name
3. Update the server to use the expected event names

---

## Server-Side Checklist

Make sure your server is:
1. ✅ Emitting `receiveMessage` or `receive_message` when a message is sent
2. ✅ Emitting `messageSent` or `message_sent` as confirmation
3. ✅ Listening for `sendMessage` or `send_message` from clients
4. ✅ Listening for `joinChat` or `join_chat` when users join rooms
5. ✅ Properly joining users to socket rooms based on chatId
6. ✅ Broadcasting messages to the correct room

---

## Next Steps

1. **Run the app** and check the logs
2. **Send a test message** from mobile
3. **Send a test message** from web
4. **Look for the `🔔` logs** to see all events
5. **Share the logs** if you need help debugging

The comprehensive logging will tell you exactly what's happening at each step!
