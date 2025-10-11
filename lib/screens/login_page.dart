import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_page.dart';
import 'admin_dashboard.dart'; // import the dashboard page
import 'agent_dashboard.dart'; // make sure this file exists

// Simple validators to replace 'validators' package
bool isEmail(String input) {
  return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(input);
}

bool isNumeric(String input) {
  return double.tryParse(input) != null;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String identifier = _identifierController.text.trim();
      String password = _passwordController.text.trim();

      String type;
      if (isEmail(identifier)) {
        type = 'email';
      } else if (isNumeric(identifier) && identifier.length >= 10) {
        type = 'phone';
      } else {
        type = 'uuid';
      }

      Fluttertoast.showToast(
          msg: "Logging in using $type...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);

      setState(() => _isLoading = false);

      // Navigate to Admin Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.08),

                // Logo
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
                SizedBox(height: 20),

                // Welcome Text
                Text(
                  "Welcome to Votely",
                  style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Identifier Field
                TextFormField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: "Email / Phone / UUID",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),

                // Forgot Password aligned right
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to forgot password page
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ),

                SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                SizedBox(height: 15),


                // Temporary Agent Login Button
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Agent Dashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AgentDashboard()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // distinguishable color
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Agent Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),




                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
