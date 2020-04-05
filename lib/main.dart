import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      MaterialPageRoute(builder: (context) => EncryptChoosePage())
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

class EncryptChoosePageState extends State<EncryptChoosePage> {
  final _maxEntries = 5;
  final _encryptEntries = <Tuple2<String, String>>[];
  final _left = true;
  final _right = false;
  final  _textController = TextEditingController();
  FocusNode _textFieldFocus;
  bool _isFocusOnTextField = false;
  bool _isEncryptButtonClicked = false;
  File _image;
  
  @override
  void initState() {
    super.initState();
    _textFieldFocus = FocusNode();
    _textFieldFocus.addListener(_handleTextFieldFocusChange);
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  bool _isNextEnabled() {
    return _image != null && _textController.text.length > 0;
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }
  
  void _handleTextFieldFocusChange() {
    if (_textFieldFocus.hasFocus != _isFocusOnTextField) {
      setState(() {
        _isFocusOnTextField = _textFieldFocus.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Encrypt'),
      ),
      body: _isEncryptButtonClicked ? _encryptQuestionWidget() : _mainEncryptPageWidget()
    );
  }

  Widget _mainEncryptPageWidget() {
    var _widgetStack = <Widget>[
      _imageWidget(),
      _inputTextField(_isFocusOnTextField),
      _encryptFloatingButton(),
      _bottomCornerButton(_left, 'Cancel', () => Navigator.pop(context)),
    ];

    if (_encryptEntries.length < _maxEntries - 1) {
      _widgetStack.add(
          _bottomCornerButton(_right, 'Next', _isNextEnabled() ? _nextButtonAction : () => {})
      );
    }

    return ! _isFocusOnTextField
        ? Stack(
            children: _widgetStack
          )
        : Stack(
            children: <Widget>[
              _inputTextField(_isFocusOnTextField),
            ]
        );
  }

  void _saveEncryptionEntry() {
    _encryptEntries.add(Tuple2<String, String>(_image.path, _textController.text));
  }

  void _nextButtonAction() {
    setState(() {
      _saveEncryptionEntry();
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
                  heroTag: null,
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

  Widget _encryptFloatingButton() {
    return Align(
      alignment: Alignment(0.0, 0.5),
      child: FloatingActionButton.extended(
          onPressed: _isNextEnabled()
              ? _encryptButtonAction
              : () => {},
          label: Text('Encrypt'),
          backgroundColor: Colors.cyan,
          icon: Icon(Icons.lock),
          heroTag: null,
      ),
    );
  }

  void _encryptButtonAction() {
    setState(() {
      _isEncryptButtonClicked = true;
    });
  }

  Widget _encryptQuestionWidget() {
    final _len = _encryptEntries.length + 1;
    return Scaffold(
      body: Center(
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Encrypt and hide\n       ' + _len.toString() + ' entr' + (_len == 1 ? 'y' : 'ies') + '?',
                style: Theme.of(context).textTheme.title,
              ),
              SizedBox(height: Theme.of(context).buttonTheme.height),
              RaisedButton(
                onPressed: () {
                  _saveEncryptionEntry();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Encrypt!',
                  style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(height: Theme.of(context).buttonTheme.height  / 1.5),
              RaisedButton(
                onPressed: () {
                  setState(() {
                    _isEncryptButtonClicked = false;
                  });
                },
                child: Text(
                  'Go back',
                  style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputTextField(bool hasFocus) {
    return Align(
      alignment: hasFocus ? Alignment(0.0, -0.7): Alignment(0.0, 0.0),
      child: Container(
        width: 350.0,
        child: TextField(
          autofocus: hasFocus, // not working as expected
          focusNode: _textFieldFocus,
          controller: _textController,
          inputFormatters: [WhitelistingTextInputFormatter(RegExp("[\x00-\x7F]"))],
          keyboardType: TextInputType.multiline,
          maxLines: null,
          maxLength: 128,
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

class EncryptChoosePage extends StatefulWidget {
  @override
  EncryptChoosePageState createState() => EncryptChoosePageState();
}


