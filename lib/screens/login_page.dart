import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:validators/validators.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String identifier = _identifierController.text.trim();
      String password = _passwordController.text.trim();

      // Determine type of identifier
      String type;
      if (isEmail(identifier)) {
        type = 'email';
      } else if (isNumeric(identifier) && identifier.length >= 10) {
        type = 'phone';
      } else {
        type = 'uuid';
      }

      // Call your API here with type, identifier, password
      // Example:
      // API.login(type: type, identifier: identifier, password: password);

      Fluttertoast.showToast(
          msg: "Logging in using $type...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Voting Management Login",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700]),
                ),
                SizedBox(height: 40),

                // Identifier Field (Email / Phone / UUID)
                TextFormField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: "Email / Phone / UUID",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your identifier";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Login",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Navigate to forgot password page
                  },
                  child: Text("Forgot Password?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
