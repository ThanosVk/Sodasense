import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:thesis/Login.dart';
import 'package:http/http.dart' as http;

class PassReset extends StatefulWidget {
  const PassReset({Key? key}) : super(key: key);

  @override
  _PassResetState createState() => _PassResetState();
  }

class _PassResetState extends State<PassReset> {
  final _formKey = GlobalKey<FormState>();
  final txtController = TextEditingController();

  @override
  void dispose() {
    txtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
        child: SafeArea(
        child: Form(
          key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

        SizedBox(height: size.height * 0.1),

    Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: const Text(
        "Password Reset",
        style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF2661FA),
        fontSize: 36
        ),
      textAlign: TextAlign.left,
      ),
    ),
    SizedBox(height: size.height * 0.03),

    Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: txtController,
        decoration: const InputDecoration(labelText: "Enter Email"),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email can\'t be empty';
          } else if (!EmailValidator.validate(value)) {
            return 'Enter a valid Email';
          }
          return null;
        },
      ),
    ),

    SizedBox(height: size.height * 0.05),

    Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
          final response = await http.post(
          Uri.parse('https://api.sodasense.uop.gr/v1/userPasswordResetApp'),
          headers: <String, String> {
          'Content-Type': 'application/json; charset=UTF-8'
          },
          body: jsonEncode(<String, String>{
          'email': txtController.text,
          })
        );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
        msg: 'An email with new password has been sent to your email.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
    } else {
      Fluttertoast.showToast(
      msg: 'Failed to reset password. Please try again.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM
      );
      }
    }
    },
    style: ElevatedButton.styleFrom(foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
    padding: const EdgeInsets.all(0)),
    child: Container(
      alignment: Alignment.center,
      height: 50.0,
      width: size.width * 0.5,
      padding: const EdgeInsets.all(0),
      child: const Text(
        "Reset",
        textAlign: TextAlign.center,
        style: TextStyle(
        fontWeight: FontWeight.bold
        ),
      ),
    ),
    ),
    ),
    ],
    ),
    ),
    )
    )
    );
  }
}