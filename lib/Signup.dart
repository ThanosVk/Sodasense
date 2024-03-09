import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:thesis/Login.dart';
import 'package:thesis/main.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'Introduction.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  SignupState createState() => SignupState();
}

class SignupState extends State<Signup> {

  //user_txtController for the username field, mail_txtController for the email field,pass_txtController for the password field, confpass_txtController for the confirmation field
  final user_txtController = TextEditingController(),mail_txtController = TextEditingController(),pass_txtController = TextEditingController(),confpass_txtController = TextEditingController();
  //user_value for getting value from username listener,mail_value for getting value from email listener,pass_value for getting value from password listener,conf_value for getting value from conf listener
  String user_value = '',mail_value = '',pass_value = '',conf_value = '';
  //user_validate for changed username textfield, mail_validate for email validate textfield,pass_validate for password validate textfield, conf_validate for confirm password validate textfield
  //user_check to know if username field contains something, mail_check to know if the email textfield contains something, pass_check to know if username field contains something, conf_check to know if confirmatn textfield contains something
  bool user_validate = true,mail_validate = true,pass_validate = true,conf_validate = true, user_check = false,mail_check = false ,pass_check = false,conf_check = false;
  bool pass_hidden = true, conf_hidden = true; //pass_hidden for view on password textfield, conf_hidden for view on confirmation password textfield
  bool hasInternet =false;//for checking if the device is connected to the internet
  var connectivityresult;//variable for checking if the wifi or the cellular of the device is enabled

  @override
  void initState(){
    super.initState();

    //Start listening to changes with listeners
    user_txtController.addListener(uservalue);
    mail_txtController.addListener(mailvalue);
    pass_txtController.addListener(passvalue);
    confpass_txtController.addListener(confvalue);
  }

  @override
  void dispose(){

    //Clean controllers when the widget is removed from the
    //widget tree and removes the values of listeners
    user_txtController.dispose();
    mail_txtController.dispose();
    pass_txtController.dispose();
    confpass_txtController.dispose();
    super.dispose();
  }

  //Function for getting string from username controller
  String uservalue(){
    return user_value;
  }

  //Function for getting string from email controller
  String mailvalue(){
    return mail_value;
  }

  //Function for getting string from password controller
  String passvalue(){
    return pass_value;
  }

  //Function for getting string from confirmation controller
  String confvalue(){
    return conf_value;
  }

  //Function for displaying the correct error message on username textfield
  String? User_Textfield_check(){
    String user_msg='';
    if(user_txtController.text.isEmpty==true){
      user_msg='Username can\'t be empty';
      print(user_msg);
      user_check=false;
      return user_msg;
    }
    else if(user_txtController.text.isEmpty==false){
      user_check=true;
      user_msg='Valid username';
      print(user_msg);
    }
    return null;
  }

  //Function for displaying the correct error message on email textfield
  String? Mail_Textfield_check(){
    String mail_msg='';
    if(mail_txtController.text.isEmpty==true){
      mail_msg='Email can\'t be empty';
      print(mail_msg);
      mail_check=false;
      return mail_msg;
    }
    else if(EmailValidator.validate(mail_txtController.text)==false){
      mail_msg='Enter a valid Email';
      print(mail_msg);
      mail_check=false;
      return mail_msg;
    }
    else if(EmailValidator.validate(mail_txtController.text)==true){
      mail_check=true;
      mail_msg='Valid email';
      print(mail_msg);
    }
    return null;
  }

  //Function for displaying the correct error message on password textfield
  String? Pass_Textfield_check(){
    String pass_msg='';
    if(pass_txtController.text.isEmpty==true){
      pass_msg='Password can\'t be empty';
      print(pass_msg);
      pass_check=false;
      return pass_msg;
    }
    else if(pass_txtController.text.isEmpty==false){
      if(pass_txtController.text.length < 10 || pass_txtController.text.contains(new RegExp(r'(?=.*[!@#$%^&*])')) == false){
        pass_msg='Password must be at least 10 letters\nand contain special characters (!@#\$%^&*)';
        pass_check=false;
        return pass_msg;
      }
      else if(pass_txtController.text.length > 16 || pass_txtController.text.contains(new RegExp(r'(?=.*[!@#$%^&*])')) == false){
        pass_msg='Password must be maximum 16 letters\nand contain special characters (!@#\$%^&*)';
        pass_check=false;
        return pass_msg;
      }
      else{
        pass_check=true;
        pass_msg='Valid password';
        print(pass_msg);
      }
    }
    return null;
  }

  //Function for displaying the correct error message on confirmation password textfield
  String? Conf_Textfield_check(){
    String conf_msg='';
    if(confpass_txtController.text.isEmpty==true){
      conf_msg='Password can\'t be empty';
      print(conf_msg);
      conf_check=false;
      return conf_msg;
    }
    else if(confpass_txtController.text.isEmpty==false){
      if(confpass_txtController.text.compareTo(pass_txtController.text) != 0){
        conf_check=false;
        conf_msg='Password isn\'t same as the one above';
        return conf_msg;
      }
      else{
        conf_check=true;
        conf_msg='Valid username';
        print(conf_msg);
      }
    }
    return null;
  }

  //Function for testing if username textfield is changed for the first time
  bool user_error_msg(){
    if(User_Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }

  //Function for testing if mail textfield is changed for the first time
  bool mail_error_msg(){
    if(Mail_Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }

  //Function for testing if password textfield is changed for the first time
  bool pass_error_msg(){
    if(Pass_Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }

  //Function for testing if confirm password textfield is changed for the first time
  bool conf_error_msg(){
    if(Conf_Textfield_check()?.isNotEmpty==true){
      return false;
    }
    else{
      return true;
    }
  }

  //Function for changing the icon view next to password textfield
  void ChangeView(){
    setState(() {
      pass_hidden = !pass_hidden;
    });
  }

  //Function for changing the icon view next to confirmation textfield
  void ChangeViewConf(){
    setState(() {
      conf_hidden = !conf_hidden;
    });
  }

  //Function for creating hash for the given password
  HashPassword(String password, String salt) {
    var codec = Utf8Codec();
    var key = codec.encode(password);//encode password to Utf8
    var saltBytes = codec.encode(salt);//encode salt to Utf8
    var hmacSha256 = Hmac(sha256, key);//hashing password with sha256 cryptalgorith
    var digest = hmacSha256.convert(saltBytes);//add salt to hashed password
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset : true,
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
                  "REGISTER",
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
                  controller: user_txtController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    errorText: user_validate ? null : User_Textfield_check(),
                  ),
                  onChanged: (text) => setState(() {
                    user_validate = user_error_msg();
                  }),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: mail_txtController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    errorText: mail_validate ? null : Mail_Textfield_check(),
                  ),
                  onChanged: (text) => setState(() {
                    mail_validate = mail_error_msg();
                  }),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: pass_txtController,
                  decoration: InputDecoration(
                      labelText: "Password",
                      errorText: pass_validate ? null : Pass_Textfield_check(),
                      suffix: InkWell(
                        onTap: ChangeView,
                        child: Icon(pass_hidden ? Icons.visibility_off : Icons.visibility),
                      )
                  ),
                  onChanged: (text) => setState(() {
                    pass_validate = pass_error_msg();
                  }),
                  obscureText: pass_hidden,
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: confpass_txtController,
                  decoration: InputDecoration(
                      labelText: "Confirm Password",
                      errorText: conf_validate ? null : Conf_Textfield_check(),
                      suffix: InkWell(
                        onTap: ChangeViewConf,
                        child: Icon(conf_hidden ? Icons.visibility_off : Icons.visibility),
                      )
                  ),
                  onChanged: (text) => setState(() {
                    conf_validate = conf_error_msg();
                  }),
                  obscureText: conf_hidden,
                ),
              ),

              SizedBox(height: size.height * 0.05),

              Container(
                alignment: Alignment.centerRight,
                margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: ElevatedButton(
                  onPressed: () async {
                    connectivityresult = await Connectivity().checkConnectivity();
                    hasInternet = await InternetConnectionChecker().hasConnection;
                    print(connectivityresult);
                    if((connectivityresult == ConnectivityResult.mobile || connectivityresult == ConnectivityResult.wifi) && hasInternet == true){
                      if(user_check == false || mail_check == false || pass_check == false || conf_check == false){
                        Fluttertoast.showToast(msg: 'Please check your credentials',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                      }
                      else{
                        // mongo.Db db = mongo.Db('mongodb://10.0.2.2:27017/App');
                        // await db.open();
                        // mongo.DbCollection users = db.collection('users');
                        // print('Connected to database!');
                        // var rand = Random.secure();//Generate a random salt
                        // var saltBytes = List<int>.generate(32, (_) => rand.nextInt(256));//Generates a list of 32 integers between 0 and 256
                        // var salt = base64.encode(saltBytes);//Convertion of list to a base64 string
                        // String hashed_pass = HashPassword(pass_txtController.text, salt);
                        // var existing_mail = await users.findOne(mongo.where.eq('e-mail',mail_txtController.text));
                        // if(existing_mail?.containsValue(mail_txtController.text) == true){
                        //   Fluttertoast.showToast(msg: 'E-mail already exists, please enter another', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                        // }
                        // else{
                        //   await users.insertOne({
                        //     'username': user_txtController.text,
                        //     'e-mail' : mail_txtController.text,
                        //     'Hashed password': hashed_pass,
                        //     'Salt':salt
                        //   });
                        var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/userRegister'),
                            body: jsonEncode(<String, String>{
                              "email":mail_txtController.text,
                              "username":user_txtController.text,
                              "lastname":user_txtController.text,
                              "firstname":user_txtController.text,
                              "password":pass_txtController.text
                            }));
                        print('Status code: ${response.statusCode}');
                        print('Response body: ${response.body}');
                        print('Reason phrase: ${response.reasonPhrase}');
                        if(response.body.contains('User exists with same username') == true){
                          print('Unsuccessful registration!!');
                          Fluttertoast.showToast(msg: 'Username already in use', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                        }
                        else if(response.body.contains('User exists with same email') == true){
                          print('Unsuccessful registration!!');
                          Fluttertoast.showToast(msg: 'Email already in use', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                        }
                        else if(response.statusCode == 200 && response.reasonPhrase == 'OK' && response.body.contains('User exists with same username') == false && response.body.contains('User exists with same email') == false){
                          print('Successful registration!!');

                          var responsee= await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/userLogin'),
                              body: jsonEncode(<String, String>{
                                "username": mail_txtController.text,
                                "password": pass_txtController.text
                              }));

                          var box = Hive.box('user');
                          var token_parts = responsee.body.split('.');
                          Map<String, dynamic> map = jsonDecode(responsee.body);
                          // print(map);
                          String access_token = map['access_token'].toString();
                          // print(access_token);
                          //Base64 requires string multiple of 4 in order to have 0 remainder with mod division
                          if(token_parts[1].length % 4 == 1){
                            token_parts[1] = token_parts[1] + '===';
                          }
                          else if(token_parts[1].length % 4 == 2){
                            token_parts[1] = token_parts[1] + '==';
                          }
                          else if(token_parts[1].length % 4 == 3){
                            token_parts[1] = token_parts[1] + '=';
                          }
                          var jsontext = base64.decode(token_parts[1]);
                          Map<String,dynamic> decoded_token= jsonDecode(utf8.decode(jsontext));

                          // print(decoded_token);
                          await box.put('email',mail_txtController.text);
                          await box.put('pass',pass_txtController.text);
                          await box.put('userid', decoded_token['sub']);
                          await box.put('access_token', access_token);
                          await box.put('passed', 0); //passed for checking if the user has signed on the application for the first time

                          //to check the first login after signup so that the user requires a tutorial or not
                          if(box.get('passed')==0){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => OnBoardingPage()));
                          }else{
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                          }
                        }
                        // }
                      }
                    }
                    else{
                      Fluttertoast.showToast(msg: 'Please connect to the internet', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
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
                      "SIGN UP",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                alignment: Alignment.centerRight,
                margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: GestureDetector(
                  onTap: () => {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()))
                  },
                  child: Text(
                    "Already Have an Account? Sign in",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2661FA)
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}