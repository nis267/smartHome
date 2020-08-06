
import 'package:flutter/material.dart';

class SnackbarText {

  void showSnackBarText(BuildContext context, String text) {
    final snackBar =
        SnackBar(content: Text(text), duration: Duration(milliseconds: 2000));
    Scaffold.of(context).removeCurrentSnackBar();
    Scaffold.of(context).showSnackBar(snackBar);
  }

}