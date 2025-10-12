import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'signup_page.dart';
import 'voter_home.dart';
import 'admin_dashboard.dart'; // import the dashboard page
import 'agent_dashboard.dart'; // make sure this file exists
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String identifier = _identifierController.text.trim();
      String password = _passwordController.text.trim();

      try {
        // 🌐 Backend URL — adjust as per your setup
        const String baseUrl = "https://voting-backend-6px8.onrender.com/api/auth"; // Android emulator localhost

        // Step 1️⃣ Login Request
        final loginResponse = await http.post(
          Uri.parse("$baseUrl/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"identifier": identifier, "password": password}),
        );

        final loginData = jsonDecode(loginResponse.body);

        if (loginResponse.statusCode == 200) {
          String token = loginData["token"];
          var user = loginData["user"];

          // Save token & user info locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("auth_token", token);
          await prefs.setString("user_id", user["id"]);
          await prefs.setString("user_email", user["email"]);

          Future<void> saveLogin(String token, String role) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await prefs.setString('role', role);
          }

          Fluttertoast.showToast(
            msg: "Login successful",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Step 2️⃣ Fetch Roles using token
          final rolesResponse = await http.get(
            Uri.parse("$baseUrl/roles"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json"
            },
          );

          if (rolesResponse.statusCode == 200) {
            final rolesData = jsonDecode(rolesResponse.body);
            List roles = rolesData["roles"];

            if (roles.isEmpty) {
              Fluttertoast.showToast(
                msg: "No role assigned to this user",
                backgroundColor: Colors.orange,
              );
              return;
            }

            String userRole = roles.first.toLowerCase(); // pick the first assigned role

            // Save token & role locally
            await saveLogin(token, userRole);

            // Step 3️⃣ Redirect Based on Role
            if (userRole == "admin") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            } else if (userRole == "agent") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AgentDashboard()),
              );
            } else if (userRole == "voter") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VoterHomePage()),
              );
            }
            else {
              Fluttertoast.showToast(
                msg: "Unknown role: $userRole",
                backgroundColor: Colors.red,
              );
            }
          } else {
            Fluttertoast.showToast(
              msg: "Failed to fetch roles",
              backgroundColor: Colors.red,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: loginData["error"] ?? "Invalid credentials",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error: ${e.toString()}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        setState(() => _isLoading = false);
      }
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
