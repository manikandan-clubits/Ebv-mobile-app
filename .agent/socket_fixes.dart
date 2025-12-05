import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../models/chat_model.dart';
import '../models/group_model.dart';
import '../services/api_service.dart';
import '../services/encrption_service.dart';
import '../services/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_services.dart';
import 'package:flutter/material.dart';
import 'chat_encrpt_provider.dart';
import '../services/encryptions.dart';

// ADD THIS HELPER METHOD TO ChatNotifier class (around line 180)
// This method helps debug socket connection status
void logSocketStatus() {
  log('=== SOCKET STATUS DEBUG ===');
  log('Socket Connected: ${socket.connected}');
  log('Socket ID: ${socket.id ?? "null"}');
  log('State isConnected: ${state.isConnected}');
  log('Current User ID: $_currentUserId');
  log('Current Chat ID: $_currentChatId');
  log('===========================');
}

// REPLACE the connectToSocket() method starting at line 137 with this enhanced version:
void connectToSocket() {
  socket = IO.io(
    'https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net',
    <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    },
  );

  socket.onConnect((_) {
    log('✅ Socket Connected to server successfully');
    log('Socket ID: ${socket.id}');
    state = state.copyWith(isConnected: true);

    if (_currentUserId != null) {
      log('Emitting join_user with userId: $_currentUserId');
      socket.emit('join_user', {'userId': _currentUserId});
    } else {
      log('⚠️ Warning: _currentUserId is null, cannot join user');
    }
  });

  socket.onDisconnect((_) {
    log('❌ Socket Disconnected from server');
    state = state.copyWith(isConnected: false);
  });

  socket.onConnectError((error) {
    log('❌ Socket Connection Error: $error');
    state = state.copyWith(isConnected: false, error: 'Socket connection error: $error');
  });

  socket.on('receive_message', (data) {
    log('📩 Received message from socket');
    log('Message data type: ${data.runtimeType}');
    log('Message data: $data');
    try {
      _handleIncomingMessage(data);
      log('✅ Message handled successfully');
    } catch (e, stackTrace) {
      log('❌ Error in receive_message handler: $e');
      log('Stack trace: $stackTrace');
    }
  });

  socket.on('message_sent', (data) {
    log('✅ Message sent confirmation received: $data');
    try {
      _handleMessageSentConfirmation(data);
    } catch (e) {
      log('❌ Error in message_sent handler: $e');
    }
  });

  socket.on('message_delivered', (data) {
    log('📬 Message delivered: $data');
    try {
      _updateMessageDeliveryStatus(data['messageId'], isDelivered: true);
    } catch (e) {
      log('❌ Error in message_delivered handler: $e');
    }
  });

  socket.on('message_read', (data) {
    log('👁️ Message read: $data');
    try {
      _updateMessageDeliveryStatus(data['messageId'], isRead: true);
    } catch (e) {
      log('❌ Error in message_read handler: $e');
    }
  });

  // Add error event listener
  socket.on('error', (error) {
    log('❌ Socket error event: $error');
    state = state.copyWith(error: 'Socket error: $error');
  });

  // Add connect_error listener for more detailed error info
  socket.on('connect_error', (error) {
    log('❌ Socket connect_error event: $error');
  });
}

// REPLACE the section in sendMessage() around line 887-904 with this:
// (This is the part just before the catch block, after encryption)

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
      log('Message data keys: ${messageData.keys.toList()}');
      log('Is group chat: ${messageData['isGroupChat']}');
      log('Receiver ID: ${messageData['receiverID']}');
      log('Sender ID: ${messageData['SenderID']}');
      
      // Emit the message
      socket.emit('send_message', messageData);
      log('✅ Message emitted to socket successfully');
      
      // Add a small delay to ensure the message is sent
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (error, stackTrace) {
      log('❌ Error sending message: $error');
      log('Stack trace: $stackTrace');

      // Update the temporary message to show error state
      if (isGroupChat) {
        final updatedMessages = state.groupMessages.map((message) {
          if (message.messageID == tempMessageId) {
            return message.copyWith(
              error: error.toString(),
            );
          }
          return message;
        }).toList();
        state = state.copyWith(groupMessages: updatedMessages);
      } else {
        final updatedMessages = state.messages.map((message) {
          if (message.messageID == tempMessageId) {
            return message.copyWith(
              isSending: false,
              error: error.toString(),
            );
          }
          return message;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
      }

      state = state.copyWith(
        error: 'Failed to send message: ${error.toString()}',
      );
      
      // Show error to user
      Fluttertoast.showToast(
        msg: 'Failed to send message. Please check your connection.',
        toastLength: Toast.LENGTH_LONG,
      );
      
      rethrow;
    }
