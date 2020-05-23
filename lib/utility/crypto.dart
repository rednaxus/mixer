/* For Binance and Coinbase (HmacSHA256)*/
import "dart:typed_data";
import 'dart:convert';
import "package:hex/hex.dart";
import 'package:crypto/crypto.dart';
import "package:pointycastle/pointycastle.dart";
import "package:pointycastle/macs/hmac.dart";
import "package:pointycastle/digests/sha512.dart";

hmacSha256(String message, String secret) {
  var key = utf8.encode(secret);
  var msg = utf8.encode(message);
  var hmac = new Hmac(sha256, key);
  var signature = hmac.convert(msg).toString();

  return signature;
}

/* For Coinbase Pro (HmacSHA256 with base64 endode/decode)*/

hmacSha256Base64(String message, String secret) {
  var base64 = new Base64Codec();
  var key = base64.decode(secret);
  var msg = utf8.encode(message);
  var hmac = new Hmac(sha256, key);
  var signature = hmac.convert(msg);

  return base64.encode(signature.bytes);
}

/* For Bittrex (HmacSHA512)*/

hmacSha512(String message, String secret) {
  Uint8List hmacSHA512(Uint8List data, Uint8List key) {
    final _tmp = new HMac(new SHA512Digest(), 128)..init(new KeyParameter(key));
    return _tmp.process(data);
  }

  Uint8List msg = utf8.encode(message);
  Uint8List key = utf8.encode(secret);
  var digest = hmacSHA512(msg, key);
  var signature = HEX.encode(digest);

  return signature;
}
