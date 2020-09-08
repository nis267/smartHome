import 'package:flutter/material.dart';
import 'package:flutter_app/services/socket.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';

class ChooseEmailPage extends StatefulWidget {
  ChooseEmailPage({Key key, this.userId, this.loginCallback}) : super(key: key);

  final VoidCallback loginCallback;
  final int userId;
  @override
  _ChooseEmailPageState createState() => _ChooseEmailPageState();
}

class _ChooseEmailPageState extends State<ChooseEmailPage> {
  final _formKey = new GlobalKey<FormState>();
  bool _isLoading;
  String _newEmail;
  String _errorMessageNewEmail;
  final injector = Injector.getInjector();
  SocketService socketService;

  @override
  void initState() {
    _isLoading = false;
    _newEmail = "";
    _errorMessageNewEmail = "";
    socketService = injector.get<SocketService>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter your email"),
      ),
      body: Stack(
          children: <Widget>[
            _showForm(context),
            _showCircularProgress(),
          ],
      )
    );
  }

  Widget _showForm(BuildContext context) {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new Column(
            // shrinkWrap: true,
            children: <Widget>[
              showEmailInput(),
              Spacer(),
              showPrimaryButton(context),
            ],
          )
        )
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.text,
        autofocus: false,
        decoration: new InputDecoration(
          labelText: 'Enter email',
        ),
        validator: (value) =>
          value.isEmpty ? 'Email can\'t be empty' : _errorMessageNewEmail.isNotEmpty ? _errorMessageNewEmail : null,
        onChanged: (value) => {
          _newEmail = value.trim()
        },
      ),
    );
  }

  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void validateAndSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessageNewEmail = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      try {
        await socketService.chooseNewUseremail(widget.userId, _newEmail);
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessageNewEmail = e.message;
        });
      }
      final form = _formKey.currentState;
      if (form.validate()) {
        _formKey.currentState.reset();
        widget.loginCallback();
      }
    }
  }

  Widget showPrimaryButton(BuildContext context) {
        return new SizedBox(
          width: double.infinity,
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text("Continue",
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              validateAndSubmit(context);
            },
          ),
        );
  }

}