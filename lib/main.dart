import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './views/exchange_select.dart';
import './views/wallet_information.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import './utility/fetch_exchange_data.dart';
import 'package:page_transition/page_transition.dart';

void main() => runApp(MaterialApp(
    title: "Mixer",
    home: CryptoPortfolio(),
    theme: ThemeData(
        backgroundColor: Color.fromRGBO(64, 75, 96, 1),
        appBarTheme: AppBarTheme(color: Color.fromRGBO(64, 75, 96, .9)))));

class CryptoPortfolio extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CryptoPortfolioState();
  }
}

class CryptoPortfolioState extends State<CryptoPortfolio> {
  var exchangesList;
  double totalValue;
  bool _isLoadingInitial = true;
  bool _isLoading;
  var fiatListDrop = [
    PopupMenuItem(
      child: Text("USD \$"),
      value: "USD",
    ),
    PopupMenuItem(
      child: Text("EUR €"),
      value: "EUR",
    ),
    PopupMenuItem(
      child: Text("GBP £"),
      value: "GBP",
    )
  ];
  String _fiatCurrencySymbol = '€';
  String _fiatCurrency = 'EUR';

  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  _deleteInfo(exchange, index) {
    _scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text('Removed ${exchange['name']}'),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          setState(() {
            this.exchangesList.insert(index, exchange);
            this.totalValue += double.parse(exchange['data']['value']);
          });
          _updateStorage();
        },
      ),
    ));
  }

  _getFiatCurrency(fiat) async {
    setState(() {
      this._isLoadingInitial = true;
    });
    var fiatSymbol;
    switch (fiat) {
      case 'USD':
        fiatSymbol = "\$";
        break;
      case 'EUR':
        fiatSymbol = "€";
        break;
      case 'GBP':
        fiatSymbol = "£";
        break;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('fiatCurrency', fiat);
    prefs.setString('fiatCurrencySymbol', fiatSymbol);

    this._loadExchangesList();
  }

  _handleError() {
    _scaffoldState.currentState.showSnackBar(SnackBar(
      content: Text(
        'Check network or keys!',
      ),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () {
          _loadExchangesList();
        },
      ),
    ));
  }

  _loadExchangesList() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String exchangesString = prefs.getString('exchangesList') ?? '[]';

    setState(() {
      this._fiatCurrency = prefs.getString('fiatCurrency') ?? 'EUR';
      this._fiatCurrencySymbol = prefs.getString('fiatCurrencySymbol') ?? '€';
    });
    this.exchangesList = json.decode(exchangesString);

    print(this._fiatCurrency);
    /* displays totalValue and then updates its value */

    double _total = 0;

    for (var i = 0; i < this.exchangesList.length; i++) {
      var exchange = this.exchangesList[i];
      _fetchExchange(Function fetcher, fiat) async {
        var data = await fetcher(exchange, fiat);
        if (data != null && data is! String) {
          exchange['data'] = data;
          _total += double.parse(data['value']);
        } else _handleError();
      }

      switch (exchange['name']) {
        case 'Coinbase':
          await _fetchExchange(fetchCoinbase, this._fiatCurrency);
          break;
        case 'Coinbase Pro':
          await _fetchExchange(fetchCoinbasePro, this._fiatCurrency);
          break;
        case 'Bittrex':
          await _fetchExchange(fetchBittrex, this._fiatCurrency);
          break;
        case 'Binance':
          await _fetchExchange(fetchBinance, this._fiatCurrency);
          break;
        case 'Mercatox':
          await _fetchExchange(fetchMercatox, this._fiatCurrency);
          break;
        case 'HitBTC':
          await _fetchExchange(fetchHitBtc, this._fiatCurrency);
          break;
      }
    }

    setState(() {
      _isLoadingInitial = false;
      _isLoading = false;
      this.exchangesList = this.exchangesList;
      this.totalValue = _total;
    });
    exchangesString = json.encode(this.exchangesList);
    prefs.setString('exchangesList', exchangesString);
  }

  _updateStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var exchangesString = json.encode(this.exchangesList);
    prefs.setString('exchangesList', exchangesString);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExchangesList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      key: _scaffoldState,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Mixer"),
        actions: <Widget>[
          PopupMenuButton(
            itemBuilder: (context) => fiatListDrop,
            onSelected: (value) {
              this._getFiatCurrency(value);
            },
            icon: Icon(Icons.attach_money),
          )
        ],
      ),
      floatingActionButton: Container(
        width: 90,
        height: 90,
        padding: EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ExchangeSelect()))
              .then((val) => _loadExchangesList());
          },
        )),
      body: _isLoadingInitial
        ? Center(child: CircularProgressIndicator())
        : this.exchangesList.length < 1
        ? Center(
        child: Text(
          'No exchanges added',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ))
        : LiquidPullToRefresh(
        height: 100.0,
        showChildOpacityTransition: false,
        springAnimationDurationInMilliseconds: 500,
        onRefresh: () {
          return _loadExchangesList();
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 100,
              backgroundColor: Colors.transparent,
              flexibleSpace: Card(
                elevation: 10,
                color: Colors.transparent,
                margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(172, 35, 96, 0.9),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: ListView(
                    children: [
                      Center(
                        child: Text( "${this.totalValue.toStringAsFixed(2)} ${this._fiatCurrencySymbol}",
                          style: TextStyle( fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold )
                        )
                      ),
                      Text('Bitcoin balance: 5011', style: Theme.of(context).textTheme.subtitle1),
                      Text('Monero balance: 5.012', style: Theme.of(context).textTheme.subtitle1)
                    ],
                  )
                )
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                var exchange = this.exchangesList[i];
                return _createBalanceCard(exchange, i);
              }, childCount: this.exchangesList.length),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                var exchange = this.exchangesList[i];
                return _createBalanceCard(exchange, i);
              }, childCount: this.exchangesList.length),
            )
          ],
        )));
  }

  _createBalanceCard(exchange, index) {
    final makeListTile = ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: new BoxDecoration(
          border: new Border(
            right: new BorderSide(width: 1.0, color: Colors.white24))),
        child: Image.asset(
          exchange['icon'],
          height: 40,
          width: 40,
        ),
      ),
      title: Text(
        exchange['name'],
        style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.account_balance_wallet,
            color: Colors.yellowAccent,
            size: 15,
          ),
          exchange['data'] != null && exchange['data']['value'] != null ? Text(
            " Amount: ${exchange['data']['value']} ${this._fiatCurrencySymbol}",
            style: TextStyle(color: Colors.white))
          : Container(
            margin: EdgeInsets.only(left: 10),
            child: CircularProgressIndicator(),
            height: 10,
            width: 10,
          )
        ],
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0)
    );

    var makeCard;

    makeCard = Dismissible(
      key: Key(exchange['name']),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteInfo(exchange, index);
          setState(() {
            this.exchangesList.remove(exchange);
            _updateStorage();
            if (this.exchangesList.length >= 1)
              this.totalValue -= double.parse(exchange['data']['value']);
            else
              this.totalValue = 0;
          });
        }
      },
      direction: DismissDirection.endToStart,
      background: Container(
        padding: EdgeInsets.only(right: 20),
        alignment: AlignmentDirectional.centerEnd,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      child: Card(
        elevation: 10,
        color: Colors.transparent,
        margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: InkWell(
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 75, 96, 0.9),
              borderRadius: BorderRadius.circular(20)),
            child: makeListTile,
          ),
          onTap: () {
            if (exchange['data'] != null && exchange['data']['value'] != null)
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: WalletInformation(
                    exchange: exchange,
                    fiatSymbol: this._fiatCurrencySymbol)));
          },
          borderRadius: BorderRadius.circular(20),
        ),
      )
    );

    return makeCard;
  }
}
