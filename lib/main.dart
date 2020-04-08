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
        home: HomePage(),
        routes: {
          '/encryptChoose': (context) => EncryptChoosePage(),
          '/encryptSubmitKey': (context) => EncryptSubmitKeyPage(),
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
    String text = _textController.text;

    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      _textFieldFocus.unfocus();
      if (text.length > 0)
        _textController.text = text;
    });
  }
  
  void _handleTextFieldFocusChange() {
    if (_textFieldFocus.hasFocus != _isFocusOnTextField) {
      setState(() {
        _isFocusOnTextField = _textFieldFocus.hasFocus;
      });
    }
  }

  void goBackFromQuestion() {
    setState(() {
      _encryptEntries.removeLast();
      _isEncryptButtonClicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEncryptButtonClicked) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Encrypt'),
          leading: Builder(
            builder: (BuildContext context) {
              return BackButton(
                onPressed: goBackFromQuestion,
              );
            },
          ),
        ),
        body: _encryptQuestionWidget()
      );
    } else {
      return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text('Encrypt'),
          ),
          body: _mainEncryptPageWidget()
      );
    }
  }

  Widget _mainEncryptPageWidget() {
    var _widgetStack = <Widget>[
      ListView(
        padding: const EdgeInsets.all(30),
        children: <Widget>[
          _imageWidget(),
          SizedBox(height: Theme.of(context).buttonTheme.height / 3),
          _inputTextField(_isFocusOnTextField),
          SizedBox(height: Theme.of(context).buttonTheme.height / 3),
          _encryptFloatingButton(),
        ]
      ),
    ];

    if (!_isFocusOnTextField) {
      _widgetStack.add(_bottomCornerButton(_left, 'Cancel', () => EnpictionApp.returnHome(context)));

      if (_encryptEntries.length < _maxEntries - 1) {
        _widgetStack.add(
            _bottomCornerButton(
                _right, 'Next', _isNextEnabled() ? _nextButtonAction : () => {})
        );
      }
    }

    return Stack(children: _widgetStack);
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
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                  image: AssetImage(_image.path)
                  )
                ),
              ),
            ]
          );

    return _imageContainer;
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
    void _encryptButtonAction() {
      // Need this in case that button is pressed while keyboard has focus,
      // otherwise it would not detect the change in the text field
      setState((){});

      if (_isNextEnabled()) {
        setState(() {
          _saveEncryptionEntry();
          _isEncryptButtonClicked = true;
        });
      }
    }

    return FloatingActionButton.extended(
          onPressed: _encryptButtonAction,
          label: Text('Encrypt'),
          backgroundColor: Colors.cyan,
          icon: Icon(Icons.lock),
          heroTag: null,
    );
  }

  Widget _encryptQuestionWidget() {
    final _len = _encryptEntries.length;
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
                  Navigator.pushNamed(
                    context,
                    EncryptSubmitKeyPage.routeName,
                    arguments: _encryptEntries
                  );
                },
                child: Text(
                  'Encrypt!',
                  style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(height: Theme.of(context).buttonTheme.height  / 1.5),
              RaisedButton(
                onPressed: goBackFromQuestion,
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
    return Container(
        width: 350.0,
        child: TextField(
          autofocus: hasFocus, // not working as expected
          focusNode: _textFieldFocus,
          controller: _textController,
          inputFormatters: [WhitelistingTextInputFormatter(RegExp("[\x00-\x7F]"))],
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
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
    );
  }
}

class EncryptChoosePage extends StatefulWidget {
  static const routeName = '/encryptChoose';

  @override
  EncryptChoosePageState createState() => EncryptChoosePageState();
}

class EncryptSubmitKeyPageState extends State<EncryptSubmitKeyPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Tuple2<String, String>> encryptEntries = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Encrypt')
      ),
      body: ListView(
        padding: const EdgeInsets.all(50),
        children: <Widget>[
            _inputKeyField(),
            SizedBox(height: Theme.of(context).buttonTheme.height / 1.5),
            _encryptFloatingButton(context),
          ],
        ),
    );
  }

  Widget _inputKeyField() {
    return Container(
        width: 350.0,
        child: TextField(
          autofocus: true,
          controller: _textController,
          inputFormatters: [WhitelistingTextInputFormatter(RegExp("[\x00-\x7F]"))],
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.done,
          maxLines: null,
          maxLength: 16,
          autocorrect: false,
          textAlign: TextAlign.center,
          minLines: 1,
          decoration: InputDecoration(
              border: OutlineInputBorder(
              ),
              hintText: 'Enter an encryption key:'
          ),
        )
    );
  }

  Widget _encryptFloatingButton(BuildContext context) {
    void buttonAction() {
      setState((){});

      if (_textController.text.length > 0)
        EnpictionApp.returnHome(context);
    }

    return FloatingActionButton.extended(
        onPressed: buttonAction,
        label: Text('Encrypt'),
        backgroundColor: Colors.cyan,
        icon: Icon(Icons.lock),
        heroTag: null,
      );
  }
}

class EncryptSubmitKeyPage extends StatefulWidget {
  static const routeName = '/encryptSubmitKey';

  @override
  EncryptSubmitKeyPageState createState() => EncryptSubmitKeyPageState();
}


