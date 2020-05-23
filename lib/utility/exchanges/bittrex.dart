import 'dart:convert';
import 'package:http/http.dart';
import '../crypto.dart';

class Bittrex {
  String _apiKey;
  String _secret;
  String _base = 'https://api.bittrex.com/api/v1.1';

  Bittrex(String apiKey, String secret) {
    this._apiKey = apiKey;
    this._secret = secret;
  }

  _response(request) async {
    try {
      String timestamp = new DateTime.now().millisecondsSinceEpoch.toString();
      String url = "$_base$request?apikey=$_apiKey&nonce=$timestamp";
      String signature = hmacSha512(url, this._secret);

      return await get(url, headers: {
        'apisign': signature,
      });
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = '/account/getbalances';
    var response = await this._response(request);

    //print(response.body);
    if (response != null && response.statusCode == 200) {
      if (json.decode(response.body)['success'] == false) return null;
      var result = json.decode(response.body)['result'];
      // print(result);
      var balance = [];
      for (var res in result) {
        if (res['Balance'] > 0) {
          balance.add(res);
        }
      }
      return balance;
    }
    return null;

    /* return type: [{Currency:currency, Balance:balance,
                      Available:available, Pending:pending,
                      CryptoAddress:cryptoaddress, Request:request,
                      Uuid:uuid}]
       just returns those assets where balance > 0 */
  }
}
