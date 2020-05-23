import 'dart:convert';
import 'package:http_auth/http_auth.dart';

class HitBtc {
  String _apiKey;
  String _secret;
  String _base = 'https://api.hitbtc.com';

  HitBtc(String apiKey, String secret) {
    this._apiKey = apiKey;
    this._secret = secret;
  }

  _response(request) async {
    try {
      var client = BasicAuthClient(this._apiKey, this._secret);
      var response = await client.get(this._base + request);

      return response;
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = '/api/2/account/balance';
    var response = await this._response(request);

    //print(response.body);
    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body);
      // print(result);
      var balance = [];
      for (var res in result) {
        if (double.parse(res['available']) > 0) {
          balance.add(res);
        }
      }
      return balance;
    }
    return null;

    /* return type: [{currency:currency, available:available,
                      reserved:reserved}]
       just returns those assets where balance > 0 */
  }
}
