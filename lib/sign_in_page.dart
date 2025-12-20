import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shopping_app/main_shopping_page.dart';
import 'package:shopping_app/sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  bool passwordVisibility = true;
  bool confirmPasswordVisibility = true;
  String fullNameValue = "";
  String emailValue = "";
  String passwordValue = "";
  String confirmPasswordValue = "";
  bool exit = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value) => {emailValue = value},
                          style: TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(fontSize: 24),
                            border: OutlineInputBorder(),
                            errorText: _emailErrorMessage,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          obscureText: passwordVisibility,
                          onChanged: (value) => {passwordValue = value},
                          style: TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(fontSize: 24),
                            border: OutlineInputBorder(),
                            errorText: _passwordErrorMessage,
                            suffixIcon: IconButton(
                              onPressed: () {
                                togglePasswordVisibility();
                              },
                              icon: Icon(
                                passwordVisibility
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 250,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {
                              handleSignup();
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: 20),
                          ),
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateAccountPage(),
                              ),
                            ),
                            child: Text(
                              "Create one",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text("or", style: TextStyle(fontSize: 18)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 300,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[300],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {
                              signInWithGoogle();
                            },
                            child: Row(
                              children: [
                                FaIcon(FontAwesomeIcons.google, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Sign in with Google",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  togglePasswordVisibility() {
    passwordVisibility = !passwordVisibility;
    setState(() {});
  }

  toggleConfirmPasswordVisibility() {
    confirmPasswordVisibility = !confirmPasswordVisibility;
    setState(() {});
  }

  handleSignup() async {
    if (emailValue.isEmpty) {
      _emailErrorMessage = "Please input your email.";
    } else if (!emailValue.contains('@')) {
      _emailErrorMessage = "Please ensure that your email contains '@'.";
    } else if (emailValue.lastIndexOf("@") == emailValue.length - 1) {
      _emailErrorMessage = "Please enter a part following '@'.";
    } else {
      _emailErrorMessage = null;
    }
    if (passwordValue.isEmpty) {
      _passwordErrorMessage = "Please input your password.";
    } else if (passwordValue.length < 6) {
      _passwordErrorMessage = "Password length must exceed 6 characters.";
    } else {
      _passwordErrorMessage = null;
    }
    setState(() {});
    if (_passwordErrorMessage == null && _emailErrorMessage == null) {
      setState(() {});
      await signInWithEmailAndPassword(emailValue, passwordValue);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        await addUserToDatabase(
          userCredential.user?.uid.toString() ?? "",
          userCredential.user?.email.toString() ?? "",
          userCredential.user?.displayName.toString() ?? "Not Set"
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainShoppingPage()),
          );
        }
      }

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Error: ${e.message}');
      return null;
    }
  }

  Future<void> addUserToDatabase(String uid, String email, String displayName) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        final userData = {
          "email": email,
          "displayName": displayName,
          "photoUrl": "",
          "joinedDate": DateTime.now().millisecondsSinceEpoch,
          "listedProducts": [],
          "purchasedProducts": [],
          "cartProducts": [],
          "favoriteProducts": [],
        };
        await docRef.set(userData);
        await docRef.collection('chats').doc('init').set({
          'initialized': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        FirebaseFirestore.instance.collection("users").doc(uid).set(userData);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainShoppingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Wrong email or password.",
              style: TextStyle(color: Colors.black),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.yellow,
          ),
        );
      }
    }
  }
}
