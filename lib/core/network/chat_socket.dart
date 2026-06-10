import 'dart:async';

abstract interface class ChatSocket {
  Stream<String> get messages;

  Future<void> connect(Uri uri);

  void send(String message);

  Future<void> disconnect();
}

class InMemoryChatSocket implements ChatSocket {
  InMemoryChatSocket();

  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get messages => _controller.stream;

  @override
  Future<void> connect(Uri uri) async {}

  @override
  void send(String message) => _controller.add(message);

  @override
  Future<void> disconnect() => _controller.close();
}
