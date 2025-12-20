import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopping_app/add_product.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _editNameController = TextEditingController();
  @override
  void dispose() {
    _editNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('User data not found'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return _buildProfilePage(userData, uid);
      },
    );
  }

  Widget _buildProfilePage(Map<String, dynamic> userData, String? uid) {
    String displayName = userData['displayName'];
    String? profilePicture = userData['pfp'];
    String initials = displayName[0].toUpperCase();

    Future<void> _pickImage(ImageSource source) async {
      try {
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 50,
        );

        if (pickedFile != null) {
          final File? img = File(pickedFile.path);
          if (img != null) {
            final bytes = await img.readAsBytes();
            String base64String = base64Encode(bytes);
            String dataUri = 'data:image/jpeg;base64,$base64String';
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'pfp': dataUri});
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Profile picture has been changed"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Error while changing pfp: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          _pickImage(ImageSource.gallery);
                        },
                        child: CircleAvatar(
                          radius: 42,
                          child: (profilePicture == null)
                              ? Text(initials, style: TextStyle(fontSize: 30))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(100.0),
                                  child: Base64Image(
                                    base64String: profilePicture,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'pfp': FieldValue.delete()});
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Profile picture removed"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Text("Display Name", style: headerStyle()),
                  IconButton(
                    onPressed: () {
                      _showEditNameDialog(uid);
                    },
                    icon: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                (displayName == "") ? "Not set" : displayName,
                style: textStyle(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  Text("Listed Products", style: headerStyle()),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      _addProduct();
                    },
                    icon: const Icon(Icons.add, size: 32),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(height: 480, child: _buildListedProducts()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListedProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(
            height: 100,
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildPlaceholder(
            height: 100,
            child: Text(
              'Error loading products',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPlaceholder(
            height: 100,
            child: Text(
              'No products listed yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28),
            ),
          );
        }

        final products = snapshot.data!.docs;

        return SizedBox(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final doc = products[index];
              final productData = doc.data() as Map<String, dynamic>;
              final imageBase64s = productData['imageUrls'] as List<dynamic>?;
              final firstImageBase64 =
                  imageBase64s != null && imageBase64s.isNotEmpty
                  ? imageBase64s[0]
                  : null;
              final productName = productData['name'];
              final productPrice = productData['price'];
              final productRating = productData['rating'] + 0.0;

              return InkWell(
                onTap: () {},
                child: Container(
                  width: 250,
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: firstImageBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Base64Image(
                                base64String: firstImageBase64,
                                width: 250,
                                height: 200,
                                fit: BoxFit.fill,
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    productName,
                                    style: TextStyle(fontSize: 24),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 4,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  "\$${productPrice.toString()}",
                                  style: TextStyle(fontSize: 22),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: RatingBar.builder(
                                  initialRating: productRating,
                                  minRating: 0,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 20,
                                  itemPadding: EdgeInsets.symmetric(
                                    horizontal: 1.0,
                                  ),
                                  itemBuilder: (context, _) =>
                                      Icon(Icons.star, color: Colors.amber),
                                  onRatingUpdate: (rating) {},
                                  ignoreGestures: true,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({required double height, required Widget child}) {
    return SizedBox(
      height: height,
      child: Center(child: child),
    );
  }

  void _showEditNameDialog(String? uid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editNameController,
                decoration: InputDecoration(labelText: 'Display Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editNameController.text = "";
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateDisplayName(uid);
                Navigator.pop(context);
                _editNameController.text = "";
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage()),
    );
  }

  Future<void> _updateDisplayName(String? uid) async {
    try {
      final newName = _editNameController.text.trim();

      if (newName.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Display name cannot be empty')));
        return;
      }

      // Update in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': newName,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update display name: $e')),
      );
    }
  }
}

TextStyle headerStyle() {
  return TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
}

TextStyle textStyle() {
  return TextStyle(fontSize: 24);
}
