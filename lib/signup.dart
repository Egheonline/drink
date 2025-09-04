import 'package:flutter/material.dart';

void main() {
  runApp(Signup());
}

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
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
                      "Create an account",
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
                      "Securely signup to create your account",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Full Name",
                    prefixIcon: Icon(
                      Icons.person,
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
                    suffixIcon: Icon(Icons.remove_red_eye),
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
                  child: Text("Create Account", style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("I Already Have An Account"),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Log in",
                        style: TextStyle(
                          color: Color.fromRGBO(15, 128, 253, 1),
                        ),
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
