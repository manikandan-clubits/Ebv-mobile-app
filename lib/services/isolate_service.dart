
import 'dart:async';
import 'dart:isolate';

class IsolateService {
  static Future<dynamic> runInIsolate<T>(
      Future<T> Function() computation) async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    await Isolate.spawn(
      _isolateEntry,
      _IsolateMessage<T>(
        receivePort.sendPort,
        computation,
      ),
      onError: errorPort.sendPort,
      onExit: receivePort.sendPort,
    );

    final completer = Completer<T>();
    StreamSubscription<dynamic>? errorSub;

    // Handle errors
    errorSub = errorPort.listen((error) {
      errorSub?.cancel();
      completer.completeError(Exception('Isolate error: $error'));
    });

    // Handle results
    receivePort.listen((message) {
      if (message is T) {
        completer.complete(message);
      } else if (message is Exception) {
        completer.completeError(message);
      }
      receivePort.close();
      errorPort.close();
    });

    return completer.future;
  }

  static void _isolateEntry<T>(_IsolateMessage<T> message) async {
    try {
      final result = await message.computation();
      Isolate.exit(message.responsePort, result);
    } catch (e) {
      Isolate.exit(message.responsePort, Exception(e.toString()));
    }
  }
}

class _IsolateMessage<T> {
  final SendPort responsePort;
  final Future<T> Function() computation;

  _IsolateMessage(this.responsePort, this.computation);
}
