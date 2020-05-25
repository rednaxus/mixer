import 'dart:convert';
import 'package:http/http.dart';
import 'exchanges.dart';

/* fetches balances and formats them */

fetchBinance(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];

  final binance = new Binance(APIKEY, SECRET);
  var balances = await binance.getBalance();
  if (balances == null) {
    return null;
  }

  var wallets = [];

  for (var balance in balances) {
    wallets.add({
      'currency': balance['asset'],
      'amount': balance['free'],
    });
  }

  var data = {'balances': wallets, 'value': 0};
  data = await _calculateAmount(data, fiat);

  return data;
}

fetchCoinbase(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];

  final coinbase = new Coinbase(APIKEY, SECRET);
  var balances = await coinbase.getBalance();
  if (balances == null) {
    return null;
  }

  var wallets = [];

  for (var balance in balances) {
    wallets.add({
      'currency': balance['currency'],
      'amount': balance['amount'],
    });
  }

  var data = {'balances': wallets, 'value': 0};

  data = await _calculateAmount(data, fiat);
  print(data);

  return data;
}

fetchCoinbasePro(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];
  final PASSPHRASE = exchange['pass_phrase'];

  final coinbasePro = new CoinbasePro(APIKEY, SECRET, PASSPHRASE);
  var balances = await coinbasePro.getBalance();
  if (balances == null) {
    return null;
  }

  var wallets = [];

  for (var balance in balances) {
    wallets.add({
      'currency': balance['currency'],
      'amount': balance['balance'],
    });
  }

  var data = {'balances': wallets, 'value': 0};

  data = await _calculateAmount(data, fiat);

  return data;
}

fetchBittrex(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];

  final bittrex = new Bittrex(APIKEY, SECRET);
  var balances = await bittrex.getBalance();
  if (balances == null) {
    return null;
  }

  var wallets = [];

  for (var balance in balances) {
    //print(balance['Balance']);
    wallets.add({
      'currency': balance['Currency'],
      'amount': balance['Balance']
          .toStringAsFixed(9), //represents amount with 9 digits
    });
  }

  var data = {'balances': wallets, 'value': 0};

  data = await _calculateAmount(data, fiat);

  return data;
}

fetchHitBtc(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];

  final hitBtc = new HitBtc(APIKEY, SECRET);
  var balances = await hitBtc.getBalance();
  if (balances == null) {
    return null;
  }

  print(balances);

  var wallets = [];

  for (var balance in balances) {
    //print(balance['Balance']);
    wallets.add({
      'currency': balance['currency'],
      'amount': balance['available'],
    });
  }

  var data = {'balances': wallets, 'value': 0};

  data = await _calculateAmount(data, fiat);

  return data;
}

fetchKraken(exchange, fiat) async {
  final APIKEY = exchange['api_key'];
  final SECRET = exchange['secret'];
  print('***fetching kraken');
  final kraken = new Kraken(APIKEY, SECRET);
  var balances = await kraken.getBalance();
  print('*** got kraken');

  if (balances == null) {
    return null;
  }

  print(balances);

  var wallets = [];

  for (var balance in balances) {
    //print(balance['Balance']);
    wallets.add({
      'currency': balance['currency'],
      'amount': balance['available'],
    });
  }

  var data = {'balances': wallets, 'value': 0};

  data = await _calculateAmount(data, fiat);

  return data;
}

fetchMercatox(exchange, fiat) async {
  var balances = exchange['data']['balances'];
  var wallets = [];

  try {
    for (var balance in balances) {
      if (balance['currency'] == '' || balance['amount'] == '') return null;

      //print(balance['Balance']);
      wallets.add({
        'currency': balance['currency'],
        'amount': balance['amount'],
      });
    }

    var data = {'balances': wallets, 'value': 0};

    data = await _calculateAmount(data, fiat);

    return data;
  } on Exception {
    return null;
  }
}


/*calculates value of of all currencies in wallet in EUR */

_calculateAmount(data, fiat) async {
  var coingecko = await get('https://api.coingecko.com/api/v3/coins/list')
      .then((res) => json.decode(res.body));
  var id;
  //var result = [];
  double result = 0;
  var wallets = data['balances'];

  try {
    for (var wallet in wallets) {
      var currency = wallet['currency'];
      var amount = double.parse(wallet['amount']);

      double currencyPrice = 0;

      double eur;

      var icon;
      if (currency == 'EUR' || currency == 'USD' || currency == 'GBP') {
        if (currency == fiat) {
          eur = amount;
          wallet['value'] = eur.toStringAsFixed(2);
        } else {
          var exchangeRate = await get(
                  'https://api.exchangeratesapi.io/latest?base=$currency&symbols=$fiat')
              .then((res) => json.decode(res.body)['rates'][fiat]);
          eur = amount * exchangeRate;
          wallet['value'] = eur.toStringAsFixed(2);
        }

        icon = _fetchIcons(currency);
      } else {
        for (int i = 0; i < coingecko.length; i++) {
          if (currency == coingecko[i]['symbol'].toUpperCase()) {
            id = coingecko[i]['id'];
            break;
          }
        }

        var response = await get(
                'https://api.coingecko.com/api/v3/coins/markets?vs_currency=${fiat.toLowerCase()}&ids=$id')
            .then((res) => json.decode(res.body));

        currencyPrice = double.parse(response[0]['current_price'].toString());

        eur = currencyPrice * amount;
        wallet['value'] = eur.toStringAsFixed(2);
        icon = response[0]['image'];
      }
      result += eur;
      print(result);
      print(icon);
      wallet['icon'] = icon;
    }

    data['value'] = result.toStringAsFixed(2);

    return data;
  } on Exception {
    return null;
  }
}

_fetchIcons(id) {
  if (id == 'EUR')
    return 'http://cdn.onlinewebfonts.com/svg/img_408170.png';
  else if (id == 'GBP')
    return 'http://cdn.onlinewebfonts.com/svg/img_221173.png';
  else if (id == 'USD') {
    return 'http://cdn.onlinewebfonts.com/svg/img_455423.png';
  }
}
