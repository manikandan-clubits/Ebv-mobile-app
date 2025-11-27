import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

// State class
class ChatKeysState {
  final ChatKeys? senderKeys;
  final Map<String, ReceiverPublicKey> receiverKeys; // recvId -> ReceiverPublicKey
  final bool isLoading;
  final String? error;

  ChatKeysState({
    this.senderKeys,
    this.receiverKeys = const {},
    this.isLoading = false,
    this.error,
  });

  ChatKeysState copyWith({
    ChatKeys? senderKeys,
    Map<String, ReceiverPublicKey>? receiverKeys,
    bool? isLoading,
    String? error,
  }) {
    return ChatKeysState(
      senderKeys: senderKeys ?? this.senderKeys,
      receiverKeys: receiverKeys ?? this.receiverKeys,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider
class ChatKeysNotifier extends StateNotifier<ChatKeysState> {
  ChatKeysNotifier() : super(ChatKeysState());

  Future<void> verifyAuthKeys() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await ApiService().get(
        '/chat/users/verifyAuthKeys',
        {},
      );

      // Handle encrypted response if needed
      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData != null && iv != null) {
        final result = ApiService().decryptData(encryptedData, iv);
        print('Decrypted verification result: $result');
      }
      // If we reach here, verification was successful
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
    } catch (error) {
      print('Error verifying auth keys: $error');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to verify auth keys: ${error.toString()}',
      );
      rethrow;
    }
  }

  // Get sender chat keys
  Future<void> getSenderChatKeys() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response =
          await ApiService().post('/chat/users/getSenderChatKeys', {});

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }

      final result = ApiService().decryptData(encryptedData, iv);
      final currentUser = result["keys"]?['currentUser'];

      if (currentUser?['publicKey'] != null &&
          currentUser?['privateKey'] != null) {
        final senderKeys = ChatKeys(
          publicKey: currentUser['publicKey'],
          privateKey: currentUser['privateKey'],
        );

        state = state.copyWith(
          senderKeys: senderKeys,
          isLoading: false,
        );

        if (kDebugMode) {
          print('Sender keys stored successfully');
        }
      } else {
        throw Exception('Missing public/private key data in response');
      }
    } catch (error) {
      state = state.copyWith(
        error: 'Failed to fetch sender keys: ${error.toString()}',
        isLoading: false,
      );
      rethrow;
    }
  }

  // Get receiver chat keys
  Future<void> getReceiverChatKeys([int? recvId]) async {
    print("callgetReceiverChatKeys");
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ApiService()
          .post('/chat/users/getRecieversChatKeys', {'recvId': recvId});

      final encryptedData = response.data['encryptedData'];
      final iv = response.data['iv'];

      if (encryptedData == null || iv == null) {
        throw Exception('Missing encrypted data or IV');
      }

      final result = ApiService().decryptData(encryptedData, iv);

      final requestedUser = result["keys"]?['requestedUser'];
      print("requestedUser$requestedUser");

      if (requestedUser?['publicKey'] != null) {
        final receiverKey = ReceiverPublicKey(
          recvId: recvId!,
          publicKey: requestedUser['publicKey'],
        );

        print("receiverKeydata${receiverKey.publicKey}");
        // Update receiver keys map
        final updatedReceiverKeys = Map<String, ReceiverPublicKey>.from(state.receiverKeys);
        updatedReceiverKeys[recvId.toString()] = receiverKey;

        state = state.copyWith(
          receiverKeys: updatedReceiverKeys,
          isLoading: false,
        );

        if (kDebugMode) {
          print('Receiver keys stored for user: $recvId');
        }
      } else {
        // Remove if no keys found
        final updatedReceiverKeys =
            Map<String, ReceiverPublicKey>.from(state.receiverKeys);
        updatedReceiverKeys.remove(recvId.toString());

        state = state.copyWith(
          receiverKeys: updatedReceiverKeys,
          isLoading: false,
        );
        throw Exception('Missing public key data in response');
      }
    } catch (error) {
      // Remove receiver key on error
      final updatedReceiverKeys =
          Map<String, ReceiverPublicKey>.from(state.receiverKeys);
      updatedReceiverKeys.remove(recvId.toString());

      state = state.copyWith(
        receiverKeys: updatedReceiverKeys,
        error: 'Failed to fetch receiver keys: ${error.toString()}',
        isLoading: false,
      );
      rethrow;
    }
  }

  // Get receiver public key by ID
  String? getReceiverPublicKey(String recvId) {
    print("receiverKeyspublicKey$recvId${state.receiverKeys[recvId]?.publicKey}");
    return state.receiverKeys[recvId]?.publicKey;
  }

  // Get sender public key
  String? get senderPublicKey => state.senderKeys?.publicKey;

  // Get sender private key
  String? get senderPrivateKey => state.senderKeys?.privateKey;

  // Clear all keys (for logout)
  void clearAllKeys() {
    state = ChatKeysState();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider declaration
final chatKeysProvider =
    StateNotifierProvider<ChatKeysNotifier, ChatKeysState>((ref) {
  return ChatKeysNotifier();
});
