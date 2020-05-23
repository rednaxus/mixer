import 'dart:convert';
import 'package:http/http.dart';
import '../crypto.dart';

class Coinbase {
  String _apiKey;
  String _secret;
  String _base = 'https://api.coinbase.com';

  Coinbase(String apiKey, String secret) {
    this._apiKey = apiKey;
    this._secret = secret;
  }

  _response(request) async {
    try {
      var timestamp = await get('https://api.coinbase.com/v2/time')
        .then((res) => json.decode(res.body))
        .then((res) => res['data']['epoch']);
      String query = timestamp.toString() + request['method'] + request['endPoint'];
      String signature = hmacSha256(query, this._secret);
      var url = _base + request['endPoint'];

      var response = await get(url, headers: {
        'CB-ACCESS-KEY': this._apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp.toString()
      });

      return response;
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = {'method': 'GET', 'endPoint': '/v2/accounts', 'body': ''};
    var response = await this._response(request);

    //print(response.body);
    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['data'];
      //print(result);
      var balance = [];
      for (var res in result) {
        if (double.parse(res['balance']['amount']) > 0) {
          balance.add(res['balance']);
        }
      }
      return balance;
    }
    return null;

    /* return type: [{amount:amount, currency:currency}]
       just returns those assets where balance > 0 */
  }
}

class CoinbasePro {
  String _apiKey;
  String _secret;
  String _passPhrase;
  String _base = 'https://api.pro.coinbase.com';

  CoinbasePro(String apiKey, String secret, String passPhrase) {
    this._apiKey = apiKey;
    this._secret = secret;
    this._passPhrase = passPhrase;
  }

  _response(request) async {
    try {
      var timestamp = await get('https://api.coinbase.com/v2/time')
        .then((res) => json.decode(res.body))
        .then((res) => res['data']['epoch']);
      String query = timestamp.toString() +
        request['method'] +
        request['endPoint'] +
        request['body'];
      String signature = hmacSha256Base64(query, this._secret);
      var url = _base + request['endPoint'];

      var response = await get(url, headers: {
        'CB-ACCESS-KEY': this._apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp.toString(),
        'CB-ACCESS-PASSPHRASE': this._passPhrase
      });
      return response;
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = {'method': 'GET', 'endPoint': '/accounts', 'body': ''};
    var response = await this._response(request);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body);
      //print(result);
      var balance = [];
      for (var res in result) {
        if (double.parse(res['balance']) > 0) {
          balance.add(res);
        }
      }
      return balance;
    }
    return null;

    /* return type: [{id:id, currency:currency, balance:balance,
                      available:available, hold:hold, profile_id:profile_id}]
       just returns those assets where balance > 0 */
  }
}
