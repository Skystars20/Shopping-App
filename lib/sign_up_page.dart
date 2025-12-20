import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/main_shopping_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  String? _emailErrorMessage;
  String? _displayNameErrorMessage;
  String? _passwordErrorMessage;
  String? _confirmPasswordErrorMessage;
  bool passwordVisibility = true;
  bool confirmPasswordVisibility = true;
  String fullNameValue = "";
  String emailValue = "";
  String passwordValue = "";
  String displayNameValue = "";
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
                          onChanged: (value) => {displayNameValue = value},
                          style: TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: "Display Name",
                            labelStyle: TextStyle(fontSize: 24),
                            border: OutlineInputBorder(),
                            errorText: _displayNameErrorMessage,
                          ),
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
                        child: TextField(
                          obscureText: confirmPasswordVisibility,
                          onChanged: (value) => {confirmPasswordValue = value},
                          style: TextStyle(fontSize: 20),
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            labelStyle: TextStyle(fontSize: 24),
                            border: OutlineInputBorder(),
                            errorText: _confirmPasswordErrorMessage,
                            suffixIcon: IconButton(
                              onPressed: () {
                                toggleConfirmPasswordVisibility();
                              },
                              icon: Icon(
                                confirmPasswordVisibility
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
                              "Create Account",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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
    if (displayNameValue.isEmpty) {
      _displayNameErrorMessage = "Please input a display name.";
    } else {
      _displayNameErrorMessage = null;
    }
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
    if (confirmPasswordValue.isEmpty) {
      _confirmPasswordErrorMessage = "Please input your password again.";
    } else if (confirmPasswordValue != passwordValue) {
      _confirmPasswordErrorMessage =
          "Confirm password does not match your password.";
    } else {
      _confirmPasswordErrorMessage = null;
    }

    setState(() {});

    if (_emailErrorMessage == null &&
        _confirmPasswordErrorMessage == null &&
        _displayNameErrorMessage == null &&
        _passwordErrorMessage == null) {
      await createUserWithEmailAndPassword(emailValue, passwordValue);
      setState(() {});
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
        final name = userCredential.user?.displayName.toString ?? "Not set";
        displayNameValue = name as String;
        await addUserToDatabase(
          userCredential.user?.uid.toString() ?? "",
          userCredential.user?.email.toString() ?? "",
        );
        if (mounted) {
          Navigator.push(
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

  Future<void> addUserToDatabase(String uid, String email) async {
    try {
      final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        final userData = {
          "email": email,
          "displayName": displayNameValue,
          "photoUrl": "",
          "joinedDate": DateTime.now().millisecondsSinceEpoch,
          "listedProducts": [],
          "purchasedProducts": [],
          "cartProducts": [],
          "favoriteProducts": [],
        };
        await docRef.set(userData);
        // await docRef.collection('chats').doc('init').set({
        //   'initialized': true,
        //   'timestamp': DateTime.now().millisecondsSinceEpoch,
        // });
        await FirebaseFirestore.instance.collection("users").doc(uid).set(userData);
        await UserRepository.refreshUserData();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await addUserToDatabase(
        userCredential.user?.uid.toString() ?? "",
        userCredential.user?.email.toString() ?? "",
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainShoppingPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password is too weak.",
              style: TextStyle(color: Colors.black),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.yellow,
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Account already exists.",
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
