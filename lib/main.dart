/*
 * MIT License
 *
 * Copyright (c) 2020 Jonathan Savas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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
        },
      ),
    );
  }

  static void returnHome(BuildContext context) {
    Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
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
