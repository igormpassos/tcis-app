import 'package:flutter/material.dart';
import '../../styles.dart';
import 'package:tcis_app/constants.dart';
import 'package:flutter/cupertino.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  Widget _BuildPasswordInput() {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(150),
            borderSide: BorderSide(width: 0)),
        focusedBorder: kBorderInput,
        hintText: 'Senha',
        hintStyle: TextStyle(fontWeight: FontWeight.w300),
        prefixIcon: Icon(Icons.lock),
        prefixIconColor: colorPrimary,
      ),
    );
  }

  Widget _BuildUserInput() {
    return TextField(
        decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(150),
          borderSide: BorderSide(width: 0)),
      focusedBorder: kBorderInput,
      hintText: 'Usuário',
      hintStyle: TextStyle(fontWeight: FontWeight.w300),
      prefixIcon: Icon(Icons.person),
      prefixIconColor: colorPrimary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: colorPrimary,
        useMaterial3: true,
        primaryColor: colorPrimary,
        hintColor: colorPrimary,
        focusColor: colorSecondary,
        indicatorColor: colorPrimary,
        textSelectionTheme: TextSelectionThemeData(cursorColor: colorPrimary),
      ),
      title: 'Login',
      home: Scaffold(
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.all(15),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo-tcis-branca.png', width: 150),
                  SizedBox(height: 60),
                  SizedBox(height: 30),
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BuildUserInput(),
                      SizedBox(height: 10),
                      _BuildPasswordInput(),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            //singIn(context);
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorSecondary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(25),
                                bottomRight: Radius.circular(25),
                                bottomLeft: Radius.circular(25),
                              ),
                            ),
                          ),
                          label: const Text("Entrar",
                              style: TextStyle(color: Colors.white)),
                          icon: const Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     print('login feito');
                      //     Navigator.pushReplacementNamed(context, '/home');
                      //   },
                      //   style: ButtonStyle(
                      //       minimumSize:
                      //           MaterialStateProperty.all(Size(200, 50)),
                      //       backgroundColor:
                      //           MaterialStateProperty.all(colorSecondary)),
                      //   child: Text('Entrar',
                      //       style:
                      //           TextStyle(color: Colors.white, fontSize: 18)),
                      // ),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
