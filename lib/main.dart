import 'package:enpiction/decrypt.dart';
import 'package:flutter/material.dart';

import 'encrypt.dart';

void main() => runApp(EnpictionApp());

class EnpictionApp extends StatelessWidget {
  static const String _title = 'Enpiction';

  @override
  Widget build(BuildContext context) {
    final _buttonWidth = 200.0;
    final _buttonHeight = 75.0;

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp(
        title: _title,
        theme: ThemeData(
          buttonTheme: ButtonThemeData(
            minWidth: _buttonWidth,
            height: _buttonHeight,
          ),
          textTheme: TextTheme(
            headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
            body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
            button: TextStyle(fontSize: 25.0)
          ),
          primarySwatch: Colors.blue,
        ),
        home: HomePage(),
        routes: {
          EncryptChoosePage.routeName: (context) => EncryptChoosePage(),
          EncryptSubmitKeyPage.routeName: (context) => EncryptSubmitKeyPage(),
          DecryptChoosePage.routeName: (context) => DecryptChoosePage(),
          DecryptResultPage.routeName: (context) => DecryptResultPage(),
        },
      ),
    );
  }

  static void returnHome(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
  }
  
  static String padEncryptionKey(String key) {
    return key.padRight(16, '0');
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enpiction')),
      body: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Select action:',
                style: Theme.of(context).textTheme.title,
              ),
              SizedBox(height: Theme.of(context).buttonTheme.height),
              RaisedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      EncryptChoosePage.routeName
                    );
                  },
                  child: Text(
                    'Encrypt',
                    style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                  ),
                ),
              SizedBox(height: Theme.of(context).buttonTheme.height  / 1.5),
              RaisedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, DecryptChoosePage.routeName);
                  },
                  child: Text(
                    'Decrypt',
                    style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
