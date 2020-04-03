import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:image_picker/image_picker.dart';

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
      home: HomePage()
      ),
    );
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EncryptPage())
                    );
                  },
                  child: Text(
                    'Encrypt',
                    style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                  ),
                ),
              SizedBox(height: Theme.of(context).buttonTheme.height  / 1.5),
              RaisedButton(
                  onPressed: () {},
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

class EncryptPageState extends State<EncryptPage> {
  final _encryptEntries = <Tuple2<String, String>>[];
  final _left = true;
  final _right = false;
  final _textController = TextEditingController();
  File _image;

  bool _isNextEnabled() {
    return _image != null && _textController.text.length > 0;
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Encrypt'),
      ),
      body: Stack(
          children: <Widget>[
            _imageWidget(),
            _inputTextField(),
            _bottomCornerButton(_left, 'Cancel', () => Navigator.pop(context)),
            _bottomCornerButton(_right, 'Next', _isNextEnabled() ? _saveEncryptionEntry : () => {}),
          ],
      )
    );
  }

  void _saveEncryptionEntry() {
    setState(() {
      _encryptEntries.add(Tuple2<String, String>(_image.path, _textController.text));
      _textController.clear();
      _image = null;
    });
  }

  Widget _imageWidget() {
    final _imageContainer = _image == null
        ? Column(
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Container(
                child: FloatingActionButton.extended(
                  onPressed: getImage,
                  label: Text('Choose an image'),
                  backgroundColor: Colors.pink,
                  icon: Icon(Icons.image),
                )
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.10),
            ]
          )
        : Column(
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                  image: AssetImage(_image.path)
                  )
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ]
          );

    return Align(
      alignment: Alignment(0.0, -0.7),
      child: _imageContainer
    );
  }

  Widget _bottomCornerButton(bool left, String text, Function buttonAction) {
    final sign = left ? -1 : 1;
    final _buttonTextTheme = Theme.of(context).textTheme.button;
    final _localButtonText = TextStyle(fontSize: _buttonTextTheme.fontSize * 2 / 3);
    final _buttonData = Theme.of(context).buttonTheme;
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment(sign * 0.9, (_height - 0.1 * _width) / _height),
      child: ButtonTheme(
        minWidth: _buttonData.minWidth * 2 / 3,
        height: _buttonData.height * 2 / 3,
        child: RaisedButton(
          onPressed: buttonAction,
          child: Text(text, style: _localButtonText),
          textColor: Colors.white,
          elevation: 5,
        )
      )
    );
  }

  Widget _inputTextField() {
    return Align(
      alignment: Alignment(0.0, 0.0),
      child: Container(
        width: 350.0,
        child: TextField(
          controller: _textController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          maxLength: 256,
          autocorrect: false,
          textAlign: TextAlign.center,
          minLines: 1,
          decoration: InputDecoration(
            border: OutlineInputBorder(
            ),
            hintText: 'Enter text to hide in this picture'
          ),
        )
      )
    );
  }
}

class EncryptPage extends StatefulWidget {
  @override
  EncryptPageState createState() => EncryptPageState();
}

