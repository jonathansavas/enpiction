import 'dart:io';
import 'dart:async';

import 'package:enpiction/steganography/steg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';

import 'main.dart';

class DecryptChoosePage extends StatefulWidget {
  static const routeName = '/decryptChoose';

  @override
  DecryptChoosePageState createState() => DecryptChoosePageState();
}

class DecryptChoosePageState extends State<DecryptChoosePage> {
  final _messageFinder = MessageFinder();
  var _images = <File>[];
  final  _textController = TextEditingController();
  ProgressDialog busyDialog;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _isNextEnabled() {
    return _images.length > 0 && _textController.text.length > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (busyDialog == null) {
      busyDialog = ProgressDialog(context);
      busyDialog.style(message: "Decrypting...");
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('Decrypt')),
      body: _mainDecryptPageListView()
    );
  }

  Widget _mainDecryptPageListView() {
    return ListView(
      padding: EdgeInsets.all(10.0),
      children: <Widget>[
        _imageWidget(),
        SizedBox(height: Theme.of(context).buttonTheme.height / 3),
        _inputKeyField(),
        SizedBox(height: Theme.of(context).buttonTheme.height / 3),
        _decryptFloatingButton(context),
      ],
    );
  }

  Widget _imageWidget() {
    final _imageContainer = _images.length == 0
        ? Column(
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Container(
              child: FloatingActionButton.extended(
                onPressed: _getImages,
                label: Text('Choose images'),
                backgroundColor: Colors.pink,
                icon: Icon(Icons.image),
                heroTag: null,
              )
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),
        ]
    )
        : GridView.count(
      primary: false,
      shrinkWrap: true,
      padding: EdgeInsets.only(left: 50, right: 50, top: 50),
      crossAxisCount: 3,
      mainAxisSpacing: 10.0,
      crossAxisSpacing: 10.0,
      children: _buildImageGrid(_images),
    );

    return _imageContainer;
  }

  List<Widget> _buildImageGrid(List<File> images) {
    return images.map(
            (image) => Container(
                child: Image.file(
                    image,
                    fit: BoxFit.fill
                ))).toList();
  }

  Future _getImages() async {
    String text = _textController.text;

    var images = await FilePicker.getMultiFile(type: FileType.image);

    setState(() {
      _images = images;

      if (text.length > 0) {
        _textController.text = text;
      }
    });
  }

  Widget _inputKeyField() {
    return Container(
        padding: EdgeInsets.only(left: 50, right: 50),
        child: TextField(
          autofocus: false,
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
              hintText: 'Enter your encryption key:'
          ),
        )
    );
  }

  Widget _decryptFloatingButton(BuildContext context) {

    Future<void> _showFindFailureAlert() async {
      return showDialog<void> (
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text("Decoding failure"),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () { EnpictionApp.returnHome(context); },
                    child: new Text("Ok")
                )
              ],
            );
          }
      );
    }

    void buttonAction() async {
      setState((){});

      if (_isNextEnabled()) {
        busyDialog.show();

        List<String> messages = await _messageFinder.findAndValidate(
            _images.map((i) => i.path).toList(),
            _textController.text
        );

        await Future.delayed(Duration(seconds: 1)).then((v) {});
        await busyDialog.hide();

        if (messages == null || messages.isEmpty) {
          await _showFindFailureAlert();
        } else {
          Navigator.pushNamed(
            context,
            DecryptResultPage.routeName,
            arguments: messages
          );
        }
      }
    }

    return Container(
        padding: EdgeInsets.only(left: 50, right: 50),
        child: FloatingActionButton.extended(
          onPressed: buttonAction,
          label: Text('Decrypt'),
          backgroundColor: Colors.cyan,
          icon: Icon(Icons.lock_open),
          heroTag: null,
        )
    );
  }
}

class DecryptResultPage extends StatelessWidget {
  static const routeName = '/decryptResult';

  @override
  Widget build(BuildContext context) {
    List<String> results = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(
          title: Text('Decrypt'),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => EnpictionApp.returnHome(context),
              );
            },
          ),
        ),
        body: GridView.count(
          primary: false,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          crossAxisCount: 2,
          children: results.map(
              (res) => _clickToRevealResult(context, results, results.indexOf(res))
          ).toList(),
        )
    );
  }

  Widget _clickToRevealResult(BuildContext context, List<String> results, int index) {

    Future<void> _revealResult() async {
      return showDialog<void> (
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: new Text(results.elementAt(index)),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () { Navigator.of(context).pop(); },
                    child: new Text("Hide")
                )
              ],
            );
          }
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: RaisedButton(
        onPressed: () async { await _revealResult(); },
        color: Colors.teal[(index + 1) * 100],
        child: Text("Message " + (index + 1).toString()),
      ),
    );
  }

}
