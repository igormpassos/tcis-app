import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../styles.dart';
import 'package:tcis_app/constants.dart';
import 'package:flutter/cupertino.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/data_controller.dart';
import '../home/home_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _validateLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final dataController = Provider.of<DataController>(context, listen: false);
    
    final success = await authController.login(
      _userController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Carrega dados após login bem-sucedido
      await dataController.loadAllData();
      
      // Navega para home usando Navigator.pushReplacement sem named route
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  Widget _buildPasswordInput() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite sua senha';
        }
        return null;
      },
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
    return TextFormField(
      controller: _userController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite seu usuário';
        }
        return null;
      },
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
    return Consumer<AuthController>(
      builder: (context, authController, child) {
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo-tcis-branca.png', width: 150),
                          SizedBox(height: 60),
                          _buildUserInput(),
                          SizedBox(height: 10),
                          _buildPasswordInput(),
                          if (authController.errorMessage != null) ...[
                            SizedBox(height: 10),
                            Text(
                              authController.errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton.icon(
                              onPressed: authController.isLoading ? null : _validateLogin,
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
                              label: authController.isLoading 
                                ? const Text("Entrando...", style: TextStyle(color: Colors.white))
                                : const Text("Entrar", style: TextStyle(color: Colors.white)),
                              icon: authController.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(CupertinoIcons.arrow_right, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}