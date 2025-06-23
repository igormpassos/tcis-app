import 'package:flutter/material.dart';
import '../../styles.dart';
import 'package:tcis_app/constants.dart';
import 'package:flutter/cupertino.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  void _validateLogin() {
    String user = _userController.text.trim();
    String password = _passwordController.text;

    if (user == 'tcis' && password == 'tcis') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Usuário ou senha incorretos';
      });
    }
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
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

  Widget _buildUserInput() {
    return TextField(
      controller: _userController,
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
      ),
    );
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo-tcis-branca.png', width: 150),
                    SizedBox(height: 60),
                    _buildUserInput(),
                    SizedBox(height: 10),
                    _buildPasswordInput(),
                    if (_errorMessage.isNotEmpty) ...[
                      SizedBox(height: 10),
                      Text(_errorMessage,
                          style: TextStyle(color: Colors.red, fontSize: 14)),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton.icon(
                        onPressed: _validateLogin,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}