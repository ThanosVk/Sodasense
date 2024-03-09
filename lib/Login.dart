import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:thesis/Signup.dart';
import 'package:thesis/main.dart';
import 'package:thesis/PassReset.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:email_validator/email_validator.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {

  final mail_txtController = TextEditingController(),pass_txtController=TextEditingController();//mail_txtController for the email field, pass_txtController for the password field
  String mail_value = '',pass_value = ''; //mail_value for getting value from email listener,pass_value for getting value from password listener
  //mail_validate for email validate textfield, pass validate for password validate textfield, user_check to know if username field contains something, pass_check to know if username field contains something
  bool mail_validate = true, pass_validate = true, mail_check = false, pass_check = false;
  bool pass_hidden = true;//for view on password textfield
  //bool is_checked = false;//for the checkbox of remember me
  bool hasInternet =false;//for checking if the device is connected to the internet
  var connectivityresult;//variable for checking if the wifi or the cellular of the device is enabled
  mongo.Db db = mongo.Db('mongodb://10.0.2.2:27017/App');//Target Database
  String access_token='';


  @override
  void initState(){
    super.initState();

    //Start listening to changes with listeners
    mail_txtController.addListener(mailvalue);
    pass_txtController.addListener(passvalue);
  }

  @override
  void dispose(){
    //Clean controllers when the widget is removed from the widget tree
    //and removes the values of both listeners
    mail_txtController.dispose();
    pass_txtController.dispose();
    super.dispose();
  }

  //Function for getting string from email controller
  String mailvalue(){
    return mail_value;
  }

  //Function for getting string from pass controller
  String passvalue(){
    return pass_value;
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
      print(pass_check);
      pass_check=false;
      return pass_msg;
    }
    else if(pass_txtController.text.isEmpty==false){
      pass_check=true;
      pass_msg='Valid password';
      print(pass_msg);
    }
    return null;
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

  //Function for changing the icon view next to password textfield
  void ChangeView(){
    setState(() {
      pass_hidden = !pass_hidden;
    });
  }

  //showWarning for showing show dialog to exit the app
  Future<bool?> showWarning(BuildContext context) async => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit'),
      content: const Text('Are you sure you want to exit the app?'),
      actions: [
        ElevatedButton(onPressed: () => {
          Navigator.pop(context)
        },child: const Text('No')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context, true);
        }, child: const Text('Yes'))
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    ),
    barrierDismissible: false,
  );

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    //WillPopScope is a method for handling back button
    return WillPopScope(
      onWillPop: () async {
        final shouldCloseApp = await showWarning(context);
        return shouldCloseApp ?? false;
      },
      child: Scaffold(
          resizeToAvoidBottomInset : true,
          body: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  SizedBox(height: size.height * 0.1),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: const Text(
                      "LOGIN",
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
                    margin: const EdgeInsets.symmetric(horizontal: 40),
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

                  //σε περιπτωση που χρειαστω remember me
                  // Container(
                  //   alignment: Alignment.centerRight,
                  //   margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  //   child: Row(
                  //     children: [
                  //       Text('Remember me',
                  //           style: TextStyle(
                  //               fontSize: 12,
                  //               fontWeight: FontWeight.bold,
                  //               color: Color(0xFF2661FA))
                  //       ),
                  //       Checkbox(
                  //         value: is_checked,
                  //         onChanged: (value){
                  //           setState(() {
                  //             is_checked = !is_checked;
                  //           });
                  //         },
                  //       ),
                  //       Spacer(flex: 3),
                  //       GestureDetector(
                  //         onTap: () => {
                  //           Navigator.push(context, MaterialPageRoute(builder: (context) => PassReset()))
                  //         },
                  //         child: Text(
                  //           "Forgot your password?",
                  //           style: TextStyle(
                  //               fontSize: 12,
                  //               fontWeight: FontWeight.bold,
                  //               color: Color(0xFF2661FA)
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: GestureDetector(
                      onTap: () => {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PassReset()))
                      },
                      child: const Text(
                        "Forgot your password?",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2661FA)
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        connectivityresult = await Connectivity().checkConnectivity();
                        hasInternet = await InternetConnectionChecker().hasConnection;
                        print(connectivityresult);
                        if((connectivityresult == ConnectivityResult.mobile || connectivityresult == ConnectivityResult.wifi) && hasInternet == true){
                          if(mail_check==false || pass_check==false){
                            Fluttertoast.showToast(msg: 'Please check your credentials',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                          }
                          // else{
                          //   await db.open();
                          //   mongo.DbCollection users = db.collection('users');
                          //   print('Connected to database!');
                          //   var logeduser = await users.findOne(mongo.where.eq('e-mail',mail_txtController.text));
                          //   if(logeduser != null){
                          //     var salt = logeduser['Salt'];
                          //     var hashed_pass = SignupState().HashPassword(pass_txtController.text, salt);
                          //
                          //     if(hashed_pass == logeduser['Hashed password']){
                          //       var box = Hive.box('user');
                          //       StartScreen().user.email = mail_txtController.text;
                          //       box.put('email',StartScreen().user.email);
                          //       box.put('pass',pass_txtController.text);
                          //       Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                          //     }
                          //     else{
                          //       Fluttertoast.showToast(msg: 'Incorrect email or password', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                          //     }
                          //   }
                          // }
                          else{
                            //response is for connecting with keycloak and sending the username and password
                            var response = await http.post(Uri.parse('https://api.sodasense.uop.gr/v1/userLogin'),
                                body: jsonEncode(<String, String>{
                                  "username": mail_txtController.text,
                                  "password": pass_txtController.text
                                }));
                            print('Status code: ${response.statusCode}');
                            print('Response body: ${response.body}');
                            print('Reason phrase: ${response.reasonPhrase}');
                            if(response.body.contains('Invalid user credentials') == true){
                              print('Unsuccessful login!!');
                              Fluttertoast.showToast(msg: 'Invalid email or password', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                            }
                            else if(response.statusCode == 200 && response.reasonPhrase == 'OK' && response.body.contains('Invalid user credentials') == false){
                              print('Successful login!!');

                              var box = Hive.box('user');
                              box.put('email',mail_txtController.text);
                              box.put('pass',pass_txtController.text);

                              var token_parts = response.body.split('.');

                              Map<String, dynamic> map = jsonDecode(response.body);
                              print(map);
                              List<String> tmp = token_parts[2].split(',');
                              tmp[0] = tmp[0].replaceAll('"', '');
                              access_token = map['access_token'].toString();
                              print('Ti tipos einai to token $access_token');
                              // access_token = access_token.replaceAll('{"access_token":"', '');
                              //Base64 requires string multiple of 4 in order to have 0 remainder with mod division
                              if(token_parts[1].length % 4 == 1){
                                token_parts[1] = '${token_parts[1]}===';
                              }
                              else if(token_parts[1].length % 4 == 2){
                                token_parts[1] = '${token_parts[1]}==';
                              }
                              else if(token_parts[1].length % 4 == 3){
                                token_parts[1] = '${token_parts[1]}=';
                              }
                              var jsontext = base64.decode(token_parts[1]);
                              Map<String,dynamic> decoded_token= jsonDecode(utf8.decode(jsontext));
                              box.put('userid', decoded_token['sub']);
                              // print(box.get('userid'));

                              // access_token = access_token.replaceAll('}', '');
                              // print(access_token.length);
                              // print(response.body.length);
                              await box.put('access_token', access_token);
                              // print('Akolouthei to token 0');
                              // print(token_parts[0]);
                              // print('Akolouthei to token 1');
                              // print(token_parts[1]);
                              // print('Akolouthei to token 2');
                              // print(token_parts[2]);
                              print('Akolouthei to diko mou');
                              print(access_token);
                              print('To access_token einai styl ${access_token.runtimeType}');
                              // print(tmp2.length);
                              print(access_token.length);
                              // print('Decode tokens:');
                              // print(decoded_token);
                              print('.'.allMatches(response.body).length);
                              print('olo to response body');
                              for(int i=0; i<token_parts.length;i++){
                                print('$i, ${token_parts[i]}');
                              }
                              print('O arithmos ton meron tou token_parts[2]');
                              print(','.allMatches(token_parts[2]).length);
                              print('olo to token_part[2]');
                              for(int i=0; i<tmp.length;i++){
                                print('$i, ${tmp[i]}');
                              }
                              print('NAIIIIIIIIIIIIIII');
                              print(box.get('access_token'));
                              // print('SKETO $jsontext');
                              // print('OXI SKETO ${utf8.decode(jsontext)}');
                              // if(newe['sub'] =='c91b50ed-44a9-45ca-ba85-85d0567dac8b'){
                              //   print('NAI EINAI IDIO222');
                              //   print(newe['sub']);
                              //   print(token_parts[0]);
                              //   print(token_parts[1]);
                              // }

                              // mongo.Db db = mongo.Db('mongodb://root:soda-Popsicle-2022@sodasense.uop.gr/Sodasense?authSource=admin');
                              // await db.open();
                              // print(db.isConnected);
                              // if (db.isConnected == true){
                              //   print('Connected to database!');
                              // }
                              // else{
                              //   print('Not connected to the database');
                              // }
                              // mongo.DbCollection users = db.collection('users');
                              // await users.insertOne({
                              //   "username" : mail_txtController.text,
                              //   "password" : pass_txtController.text
                              // });

                              // var newww = await users.insertOne({
                              //   "username" : "tns",
                              //   "Sdgsfdgdf": "Sfdgsfdgsdf"
                              // });
                              //
                              // if (newww.isSuccess == false) {
                              //   print('Error detected in record insertion');
                              // }
                              //
                              // print('${newww.writeError},${newww.errmsg}');
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                            }
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
                        child: const Text(
                          "LOGIN",
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
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: GestureDetector(
                      onTap: () => {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Signup()))
                      },
                      child: const Text(
                        "Don't Have an Account? Sign up",
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
          )
      ),
    );
  }
}