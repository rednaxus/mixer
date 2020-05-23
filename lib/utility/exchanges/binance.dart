import 'dart:convert';
import 'package:http/http.dart';
import '../crypto.dart';


class Binance {
  String _apiKey;
  String _secret;
  String _base;

  Binance(String apiKey, String secret, [bool usOnly = true]) {
    this._apiKey = apiKey;
    this._secret = secret;
    this._base = usOnly ? 'https://api.binance.us' : 'https://api.binance.com';
  }

  _response(request) async {
    try {
      String timestamp = "timestamp=${new DateTime.now().millisecondsSinceEpoch}";
      String query = "${request['query']}&$timestamp";
      String signature = hmacSha256(query, this._secret);
      var url = "$_base${request['endPoint']}?$query&signature=$signature";
      return request['method'] == 'GET' ? await get(url, headers: {'X-MBX-APIKEY': this._apiKey})
        : await post(url, headers: {'X-MBX-APIKEY': this._apiKey});
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = {'endPoint': '/api/v3/account', 'query': '', 'method': 'GET'};
    var response = await _response(request);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['balances'];
      var balance = [];
      for (var res in result) {
        if (double.parse(res["free"]) > 0) {
          balance.add(res);
        }
      }

      return balance;
    }
    return null;

    /* return type: [{asset:asset, free:free, locked:locked}]
       just returns those assets where balance > 0 */
  }
}
