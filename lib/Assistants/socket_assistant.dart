import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketAssistant {
  late IO.Socket _socket;

  void init() {
    print("conig init");
    // Conecta al servidor Socket.IO
    _socket = IO.io(
      'https://venya-backend.onrender.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );


    // Escucha los eventos
    _socket.onConnect((_) {
      print('Conectado al servidor Socket.IO');
    });

    _socket.on('connect', (_) {
      print('Connected to socket server');
    });
    _socket.on('message', (data) {
      // Maneja los mensajes recibidos
      print('Mensaje recibido: $data');
    });

    _socket.onDisconnect((_) => print('Desconectado del servidor Socket.IO'));

    // Conecta al servidor
  }

  void sendMessage(dynamic message) {
    // Envía un mensaje al servidor Socket.IO
    print('Mensaje enviado: $message');

    _socket.emit('message', message);
  }

  void connect(){
    print("connect function");
    _socket.connect();
  }

  void disconnect() {
    // Cierra la conexión Socket.IO
    _socket.disconnect();
  }
}