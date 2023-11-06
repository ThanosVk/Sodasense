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

  final txtController = TextEditingController();
  String lat_value='';
  bool validate=true,proceed=false;//validate for changed textfield, procced for sending email to database

  @override
  void initState() {
    super.initState();

    //Start listening to changes with listener.
    txtController.addListener(latestvalue);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    txtController.dispose();
    super.dispose();
  }

  //Function for getting string from listener
  String latestvalue(){
    return lat_value;
  }

  //function for displaying the correct error message
  String? Textfield_check(){
    String _msg='';
    if(txtController.text.isEmpty==true){
      _msg='Email can\'t be empty';
      print(_msg);
      return _msg;
    }
    else if(EmailValidator.validate(txtController.text)==false){
      _msg='Enter a valid Email';
      print(_msg);
      return _msg;
    }
    else if(EmailValidator.validate(txtController.text)==true){
      proceed=true;
      _msg='Valid email';
      print(_msg);
    }
  }

  //Function for testing if textfield is changed for the first time
  bool error_msg(){
    if(Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }



  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset : false,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                SizedBox(height: size.height * 0.1),

                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
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
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: txtController,
                    decoration: InputDecoration(
                      labelText: "Enter Email",
                      errorText: validate ? null : Textfield_check(),
                    ),
                    onChanged: (text) => setState(() {
                      validate = error_msg();
                    }),
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                Container(
                    alignment: Alignment.centerRight,
                    margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        if(proceed==false){
                          Fluttertoast.showToast(msg: 'Please enter your email',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                        }
                        else{
                          final response = await http.post(
                            Uri.parse('https://api.sodasense.uop.gr/v1/userPasswordResetApp'),
                            headers: <String, String> {
                              'Content-Type' : 'application/json; charset=UTF-8'
                            },
                            body: jsonEncode(<String,String>{
                              'email' : txtController.text,
                            })
                          );
                          if (response.statusCode == 200) {
                            Fluttertoast.showToast(
                                msg: 'An email with new password\nhas been sent to your email.',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM
                            );
                            // Push to the new screen
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                            Fluttertoast.showToast(msg: 'An email with new password\nhas been sent to your email.',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                          } else {
                            // If the server did not return a 200 OK response, throw an exception.
                            throw Exception('Failed to load response');
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
                        child: Text(
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
      );
    }
}

