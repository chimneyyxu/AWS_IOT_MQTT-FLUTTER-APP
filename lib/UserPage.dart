import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mya/bledata.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tes.dart';

class UserLog extends ChangeNotifier {
  SharedPreferences? prefs;
  int login = 0;
  String? name;

  UserLog() {
    SharedPreferences.getInstance().then((value) => prefs = value);
  }

  logint(String names, String passkey) async {
    await prefs?.setString('name', names);
    await prefs?.setString('passkey', passkey);
    login = 1;
    name = names;
    notifyListeners();
  }

  logout() async {
    await prefs?.remove('name');
    await prefs?.remove('passkey');
    login = 0;
    notifyListeners();
  }

  get() async {
    prefs ??= await SharedPreferences.getInstance();
    name = prefs?.getString('name');
    if (name != null) {
      login = 1;
      notifyListeners();
    }
  }
}

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserLog>(builder: ((context, userlog, child) {
      if (userlog.login == 1) {
        return User(userlog: userlog);
      } else {
        userlog.get();
        return LogPage();
      }
    }));
  }
}

class LogPage extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String?> _recoverPassword(String name) {
    debugPrint('Name: $name');
    return Future.delayed(loginTime).then((_) {
      // if (!users.containsKey(name)) {
      //   return 'User not exists';
      // }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<String?> _authUser(LoginData data) {
      debugPrint('Name: ${data.name}, Password: ${data.password}');
      return Future.delayed(loginTime).then((_) async {
        var url = Uri.https(
            '4ejceyu3shifvhawypw3yfvbrq0expbl.lambda-url.us-east-1.on.aws');
        var response = await http.post(url,
            body:
                '{"user_name":"${data.name}","passkey":"${data.password}","id":"","table":"user"}');
        if (response.statusCode != 200) {
          return 'User not exists';
        } else {
          print("sing succe");
          var devlist = Provider.of<Cou>(context, listen: false).get();
          List slist = await get();
          String dev = '';
          for (var j = 0; j < slist.length; j++) {
            bool re = false;
            for (var i = 0; i < devlist.length; i++) {
              if (slist[j]['deviced_id'] == devlist[i]['deviced_id']) {
                re = true;
                print('same');
                break;
              }
            }
            if (re == false) {
              print('dff');
              devlist.add(slist[j]);
              BleData a = BleData.fromJson(slist[j]);
              DBManager().saveData(a);
            }
          }
          print('devlist.length:${devlist.length}');
          for (var i = 0; i < devlist.length; i++) {
            dev = '${dev}"devcid$i":${json.encode(devlist[i])},';
          }
          var urls = Uri.https(
              '7pakgjr5vudpkdoroqhuheuoky0oikfv.lambda-url.us-east-1.on.aws');
          var responses = await http.post(urls,
              body:
                  '{"user_name":"${data.name}","passkey":"${data.password}",$dev"devnum":"${devlist.length}","id":"","table":"user"}');
          print(responses.statusCode);
          Provider.of<UserLog>(context, listen: false)
              .logint(data.name, data.password);
          return null;
        }
      });
    }

    Future<String?> _signupUser(SignupData data) {
      debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
      return Future.delayed(loginTime).then((_) async {
        var devlist = Provider.of<Cou>(context, listen: false).get();
        String dev = '';
        for (var i = 0; i < devlist.length; i++) {
          dev = '${dev}"devcid$i":${json.encode(devlist[i])},';
        }

        var url = Uri.https(
            'isvvrv2smqqpqgrobppq7t4hkq0midra.lambda-url.us-east-1.on.aws');

        var response = await http.post(url,
            body:
                '{"user_name":"${data.name}","nickname":"${data.name}","passkey":"${data.password}",$dev"devnum":"${devlist.length}","id":"","table":"user"}');
        print(response.statusCode);
        Provider.of<UserLog>(context, listen: false)
            .logint(data.name!, data.password!);
        return null;
      });
    }

    return FlutterLogin(
      title: 'ST',
      logo: AssetImage('lib/assets/ecorp.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      userValidator: (value) {
        // if (!value!.contains('@') || !value.endsWith('.com')) {
        //   return "Email must contain '@' and end with '.com'";
        // }
        if (value!.isEmpty) {
          return 'Password is empty';
        }
        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return 'Password is empty';
        }
        return null;
      },
      loginProviders: <LoginProvider>[
        LoginProvider(
          icon: FontAwesomeIcons.google,
          label: 'Google',
          callback: () async {
            debugPrint('start google sign in');
            await Future.delayed(loginTime);
            debugPrint('stop google sign in');
            return null;
          },
        ),
        LoginProvider(
          icon: FontAwesomeIcons.facebookF,
          label: 'Facebook',
          callback: () async {
            debugPrint('start facebook sign in');
            await Future.delayed(loginTime);
            debugPrint('stop facebook sign in');
            return null;
          },
        ),
        LoginProvider(
          icon: FontAwesomeIcons.linkedinIn,
          callback: () async {
            debugPrint('start linkdin sign in');
            await Future.delayed(loginTime);
            debugPrint('stop linkdin sign in');
            return null;
          },
        ),
        LoginProvider(
          icon: FontAwesomeIcons.githubAlt,
          callback: () async {
            debugPrint('start github sign in');
            await Future.delayed(loginTime);
            debugPrint('stop github sign in');
            return null;
          },
        ),
      ],
      onSubmitAnimationCompleted: () {
        // Navigator.of(context).pushReplacement(MaterialPageRoute(
        //   builder: (context) => DashboardScreen(),
        // ));
      },
      onRecoverPassword: _recoverPassword,
      userType: LoginUserType.name,
      // theme: LoginTheme(
      //   primaryColor: Colors.teal,
      //   accentColor: Colors.yellow,
      //   errorColor: Colors.deepOrange,
      //   pageColorLight: Color.fromARGB(255, 3, 36, 204),
      //   pageColorDark: Color.fromARGB(255, 120, 134, 211),
      //   logoWidth: 0.30,
      //   titleStyle: TextStyle(
      //     color: Colors.greenAccent,
      //     fontFamily: 'Quicksand',
      //     letterSpacing: 4,
      //     fontSize: 10,
      //   ),
      //   beforeHeroFontSize: 50,
      //   afterHeroFontSize: 20,
      //   bodyStyle: TextStyle(
      //     fontStyle: FontStyle.italic,
      //     decoration: TextDecoration.underline,
      //   ),
      //   textFieldStyle: TextStyle(
      //     color: Color.fromARGB(255, 30, 18, 211),
      //     shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
      //   ),
      //   buttonStyle: TextStyle(
      //     fontWeight: FontWeight.w800,
      //     color: Colors.yellow,
      //   ),
      //   cardTheme: CardTheme(
      //     clipBehavior: Clip.none,
      //     color: Colors.white,
      //     elevation: 10,
      //     margin: EdgeInsets.only(top: 10),
      //     shape: ContinuousRectangleBorder(
      //         borderRadius: BorderRadius.circular(20.0)),
      //   ),
      //   inputTheme: InputDecorationTheme(
      //     filled: true,
      //     fillColor: Color.fromARGB(255, 189, 179, 190).withOpacity(.1),
      //     contentPadding: EdgeInsets.zero,
      //     errorStyle: TextStyle(
      //       backgroundColor: Color.fromARGB(255, 235, 234, 232),
      //       color: Color.fromARGB(255, 233, 28, 28),
      //     ),
      //     labelStyle: TextStyle(fontSize: 12),
      //     enabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade700, width: 4),
      //       borderRadius: BorderRadius.circular(16),
      //     ),
      //     focusedBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade400, width: 5),
      //       borderRadius: BorderRadius.circular(16),
      //     ),
      //     errorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade700, width: 7),
      //       borderRadius: BorderRadius.circular(16),
      //     ),
      //     focusedErrorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade400, width: 8),
      //       borderRadius: BorderRadius.circular(16),
      //     ),
      //     disabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.grey, width: 5),
      //       borderRadius: BorderRadius.circular(16),
      //     ),
      //   ),
      //   buttonTheme: LoginButtonTheme(
      //     splashColor: Color.fromARGB(255, 239, 234, 240),
      //     backgroundColor: Color.fromARGB(255, 71, 56, 204),
      //     highlightColor: Colors.lightGreen,
      //     elevation: 5.0,
      //     highlightElevation: 6.0,
      //     // shape: BeveledRectangleBorder(
      //     //   borderRadius: BorderRadius.circular(5),
      //     // ),
      //     shape:
      //         RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      //     // shape: CircleBorder(side: BorderSide(color: Colors.green)),
      //     // shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
      //   ),
      // ),
      messages: LoginMessages(
        userHint: 'User',
        passwordHint: 'Pass',
        confirmPasswordHint: 'Confirm',
        loginButton: 'LOG IN',
        signupButton: 'SINGUP',
        forgotPasswordButton: 'Forgot huh?',
        recoverPasswordButton: 'HELP ME',
        goBackButton: 'GO BACK',
        confirmPasswordError: 'Not match!',
        recoverPasswordDescription:
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
        recoverPasswordSuccess: 'Password rescued successfully',
      ),
    );
  }
}

class User extends StatelessWidget {
  UserLog userlog;
  User({
    required this.userlog,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 50),
      children: [
        Column(
          children: [
            Image.asset(
              'lib/assets/defaultAvatarUrl.png',
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
            Text('${userlog.name}'),
            ElevatedButton(
                onPressed: (() {
                  userlog.logout();
                }),
                child: Text('LogOut'))
          ],
        ),
        Column(
          children: <Widget>[
            Card(
              child: ListTile(
                leading: Icon(Icons.abc),
                title: Text('One-line with leading widget'),
                trailing: Icon(Icons.more_vert),
                onTap: () {
                  print('aa');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.abc),
                title: Text('One-line with leading widget'),
                trailing: Icon(Icons.more_vert),
                onTap: () {
                  print('aa');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.abc),
                title: Text('One-line with leading widget'),
                trailing: Icon(Icons.more_vert),
                onTap: () {
                  print('aa');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.abc),
                title: Text('One-line with leading widget'),
                trailing: Icon(Icons.more_vert),
                onTap: () {
                  print('aa');
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: FlutterLogo(size: 56.0),
                title: Text('Two-line ListTile'),
                subtitle: Text('Here is a second line'),
                trailing: Icon(Icons.more_vert),
              ),
            ),
          ],
        )
      ],
    );
  }
}

Future<List> get() async {
  var url =
      Uri.https('4ejceyu3shifvhawypw3yfvbrq0expbl.lambda-url.us-east-1.on.aws');
  var response = await http.post(url,
      body:
          '{"user_name":"yrpo","passkey":"chimney123","id":"","table":"user"}');
  List dlist = [];
  if (response.statusCode == 200) {
    var res = jsonDecode(response.body);
    var devc = res['devcid']['S'];
    List<String> devclist = devc.split("}");
    print('devclist.length:${devclist.length}');
    for (var i = 0; i < devclist.length - 1; i++) {
      var jso = json.decode('${devclist[i].replaceAll('\'', '"')}}');
      dlist.add(jso);
      // BleData a = BleData.fromJson(jso);
      // DBManager().saveData(a);
    }
  }
  return dlist;
}
