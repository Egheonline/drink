import 'package:flutter/material.dart';

void main() {
  runApp(Login());
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Icon(Icons.cancel)],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Securely login to your account",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: "egheonline007@gmail.com",
                    prefixIcon: Icon(
                      Icons.email,
                      color: Color.fromRGBO(98, 205, 250, 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                        color: Color.fromRGBO(98, 205, 250, 1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                        color: Color.fromRGBO(98, 205, 250, 1),
                      ),
                    ),
                    fillColor: const Color.fromARGB(255, 237, 235, 235),
                    filled: true,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Color.fromRGBO(98, 205, 250, 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                        color: Color.fromRGBO(98, 205, 250, 1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                        color: Color.fromRGBO(98, 205, 250, 1),
                      ),
                    ),
                    fillColor: const Color.fromARGB(255, 237, 235, 235),
                    filled: true,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color.fromRGBO(98, 205, 250, 1),
                    fixedSize: Size(325, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(4),
                    ),
                  ),
                  child: Text("Log in", style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password",
                    style: TextStyle(color: Color.fromRGBO(15, 128, 253, 1)),
                  ),
                ),
                SizedBox(height: 16),
                Text("OR continue with"),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Implement Apple sign up if needed
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(98, 205, 250, 1),
                        foregroundColor: Colors.black,
                        side: BorderSide(),
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/google.png"),
                          SizedBox(width: 8),
                          Text(
                            "Google",
                            style: TextStyle(fontWeight: FontWeight.w200),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Implement Google sign up if needed
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(98, 205, 250, 1),
                        foregroundColor: Colors.black,
                        side: BorderSide(),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/facebook.png",
                            width: 15,
                            height: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Facebook",
                            style: TextStyle(fontWeight: FontWeight.w200),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Create An Account"),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Signup",
                        style: TextStyle(
                          color: Color.fromRGBO(15, 128, 253, 1),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "By clicking Continue, you agree to our",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: " Terms of Service ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color.fromRGBO(15, 128, 253, 1),
                            ),
                          ),
                          TextSpan(
                            text: "and",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          TextSpan(
                            text: " Privacy Policy",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color.fromRGBO(15, 128, 253, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
