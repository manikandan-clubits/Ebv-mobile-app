import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  late IO.Socket socket;
  bool get isConnected => socket?.connected ?? false;

  void connect() {
    socket = IO.io('http://192.168.0.182:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.onError((error) {
      print('Socket error: $error');
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    socket.off(event, callback);
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void joinChat(String chatId) {
    emit('join_chat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    emit('leave_chat', {'chatId': chatId});
  }
}