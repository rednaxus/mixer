
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

void main1() async {
  var handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(_echoRequest);

  var server = await serve(handler, 'localhost', 8080);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

Response _echoRequest(Request request) {
  print('request from url ${request.url}');
  return Response.ok('Request for "${request.url}"');
}

void main2() async {
  var app = Router();

  app.get('/favicon.ico', (Request request) async {
    Uint8List bytes = await new File("assets/app.png").readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'Content-Type':'image/jpeg',
        'Content-Length':'${bytes.length}'
      }
    );
  });

  app.get('/hello', (Request request) {
    return Response.ok('hello-world');
  });

  app.get('/user/<user>', (Request request, String user) {
    return Response.ok('hello $user');
  });


  var server = await serve(app.handler, 'localhost', 8080);
  print('Serving at http://${server.address.host}:${server.port}');

}




void main() async {
  var server = await serve(
    proxyHandler("https://google.com"),
    'localhost',
    8080,
  );

  print('Proxying at http://${server.address.host}:${server.port}');
}
