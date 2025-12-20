import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopping_app/add_product.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/checkout_page.dart';
import 'package:shopping_app/home_page.dart';
import 'package:shopping_app/main_shopping_page.dart';
import 'package:shopping_app/message_user.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ViewProductPage extends StatefulWidget {
  final String id;
  const ViewProductPage({super.key, required this.id});

  @override
  State<ViewProductPage> createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  bool _isFavorite = false;
  bool _isOwnProduct = false;
  bool _isProductPurchased = false;
  bool _isLoading = true;
  bool _isProductInCart = false;
  bool _isProductRated = false;
  late final DocumentSnapshot<Map<String, dynamic>> productDoc;
  Map<String, dynamic>? _productData;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.id)
          .get();

      if (productDoc.exists) {
        setState(() {
          _productData = productDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });

        final ratingInfo = await FirebaseFirestore.instance
            .collection("products")
            .doc(widget.id)
            .collection("ratings")
            .where(FieldPath.documentId, isEqualTo: currentUser?.uid)
            .get();

        if (ratingInfo.docs.isNotEmpty) {
          _isProductRated = true;
        }

        _checkProduct();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkProduct() async {
    if (_productData == null) return;

    await UserRepository.refreshUserData();
    final userData = UserRepository.userData;
    if (userData == null) return;
    final userId = UserRepository.currentUser?.uid;
    final sellerId = _productData!['sellerId'];
    final favoriteProducts = userData['favoriteProducts'] as List<dynamic>;
    final cartProducts = userData['cartProducts'] as List<dynamic>;

    setState(() {
      _isOwnProduct = (userId == sellerId);
      _isProductPurchased = (userData['purchasedProducts'] as List<dynamic>)
          .contains(widget.id);
      _isFavorite = favoriteProducts.contains(widget.id);
      _isProductInCart = cartProducts.contains(widget.id);
    });
  }

  Future<void> _handleRefresh() async {
    await _loadProductData();
    await Future.delayed(Duration(milliseconds: 500));
  }

  Widget _buildCommentSection() {
    final firestore = FirebaseFirestore.instance;
    final data = firestore
        .collection('products')
        .doc(widget.id)
        .collection('ratings');

    return FutureBuilder(
      future: data.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error loading comments', textAlign: TextAlign.center);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No comments yet', textAlign: TextAlign.center);
        }

        final data = snapshot.data!.docs;

        return ListView.builder(
          itemCount: data.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final rating = data[index];
            return FutureBuilder(
              future: firestore.collection('users').doc(rating.id).get(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return Text("...");
                }

                if (asyncSnapshot.hasError) {
                  return Text(
                    'Error loading comment',
                    textAlign: TextAlign.center,
                  );
                }

                final authorData = asyncSnapshot.data;
                final authorName = authorData!['displayName'] ?? "Unknown User";
                final initials = authorName[0].toString().toUpperCase();
                String? profilePicture;
                try {
                  profilePicture = authorData['pfp'] as String?;
                } catch (e) {
                  profilePicture = null;
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CircleAvatar(
                          child: (profilePicture == null)
                              ? Text(initials)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(100.0),
                                  child: Base64Image(
                                    base64String: profilePicture,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    authorName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RatingBar.builder(
                                    initialRating: rating['rating'],
                                    minRating: 0,
                                    glow: true,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 20,
                                    itemPadding: EdgeInsets.symmetric(
                                      horizontal: 1.0,
                                    ),
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {},
                                    ignoreGestures: true,
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                ),
                                child: Text(
                                  rating['comment'],
                                  style: TextStyle(fontSize: 18),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleDeleteProduct() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Are you sure you want to delete this product?"),
          content: Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.id)
                    .delete();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomAppBar() {
    if (_isLoading) {
      return Container(padding: EdgeInsets.all(16), child: Container());
    }

    if (_isOwnProduct) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _handleDeleteProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Delete Product",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    void toggleFavorite() async {
      UserRepository.refreshUserData();
      final userData = UserRepository.userData;
      if (userData == null) return;

      final userId = UserRepository.currentUser?.uid;
      final favoriteProducts = userData['favoriteProducts'] as List<dynamic>;
      List<dynamic> updatedFavorites = List.from(favoriteProducts);

      if (updatedFavorites.contains(widget.id)) {
        updatedFavorites.remove(widget.id);
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {"favoriteProducts": updatedFavorites},
        );
        setState(() {
          _isFavorite = false;
        });
      } else {
        updatedFavorites.add(widget.id);
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {"favoriteProducts": updatedFavorites},
        );
        setState(() {
          _isFavorite = true;
        });
      }
    }

    void addToCart() async {
      UserRepository.refreshUserData();
      final userData = UserRepository.userData;
      if (userData == null) return;

      final userId = UserRepository.currentUser?.uid;
      final cartProducts = userData['cartProducts'] as List<dynamic>;
      List<dynamic> updatedCart = List.from(cartProducts);
      updatedCart.add(widget.id);

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "cartProducts": updatedCart,
      });

      setState(() {
        _isProductInCart = true;
      });
    }

    void handleRateProduct(bool isEdit) {
      double currentRating = 0;
      String commentText = "";
      String editted = isEdit ? "updated" : "added";
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Rate Product"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text("Star rating: "),
                    RatingBar.builder(
                      initialRating: 0,
                      minRating: 0,
                      glow: true,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 16,
                      itemPadding: EdgeInsets.symmetric(horizontal: 1.0),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) => currentRating = rating,
                      ignoreGestures: false,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  maxLines: 5,
                  minLines: 2,
                  onChanged: (value) => commentText = value,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: "Comment (optional)",
                    labelStyle: TextStyle(fontSize: 24),
                    border: OutlineInputBorder(),
                    hintText: "Comments are much appreciated",
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    final firestore = FirebaseFirestore.instance;
                    await firestore
                        .collection("products")
                        .doc(widget.id)
                        .collection("ratings")
                        .doc(currentUser?.uid)
                        .set({"rating": currentRating, "comment": commentText});

                    await firestore
                        .collection('products')
                        .doc(widget.id)
                        .collection('ratings')
                        .get()
                        .then((querySnapshot) async {
                          double sum = 0;
                          double count = 0;
                          for (var doc in querySnapshot.docs) {
                            final docData = doc.data();
                            sum += docData['rating'];
                            count++;
                          }
                          await firestore
                              .collection('products')
                              .doc(widget.id)
                              .update({"rating": sum / count});
                        });
                    setState(() {
                      _isProductRated = true;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Rating $editted succesfully."),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    });
                  } catch (e) {
                    debugPrint("Error rating product $e");
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("An error occured."),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text("Submit"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
            ],
          );
        },
      );
    }

    if (_isProductPurchased) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_isProductRated) {
                    handleRateProduct(true);
                  } else {
                    handleRateProduct(false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  (_isProductRated) ? "Edit Rating" : "Rate Product",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: IconButton(
                icon: (_isFavorite)
                    ? const Icon(Icons.favorite, color: Colors.red)
                    : const Icon(Icons.favorite_border, color: Colors.black),
                onPressed: toggleFavorite,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_isProductInCart) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        productId: widget.id,
                        productData: _productData,
                      ),
                    ),
                  ).then((shouldRefresh) async {
                    if (shouldRefresh) {
                      setState(() {
                        _isProductPurchased = true;
                        _handleRefresh();
                      });
                    }
                  });
                } else {
                  addToCart();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                (_isProductInCart) ? "Proceed to Checkout" : "Add to Cart",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: IconButton(
              icon: (_isFavorite)
                  ? const Icon(Icons.favorite, color: Colors.red)
                  : const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Product Details")),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_productData == null)
          ? Center(child: Text("Product not found!"))
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              child: _buildProductContent(screenWidth, screenHeight),
            ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildProductContent(double screenWidth, double screenHeight) {
    final productName = _productData!['name'];
    final productPrice = _productData!['price']?.toString();
    final productRating = _productData!['rating'] + 0.0;
    final sellerId = _productData!['sellerId'];
    final productDescription = _productData!['description'];
    final imageBase64s = _productData!['imageUrls'] as List<dynamic>?;

    PageController pageController = PageController(initialPage: 0);
    final List<Widget> pages = (imageBase64s == null)
        ? [Container()]
        : imageBase64s
              .map((img) => Base64Image(base64String: img, fit: BoxFit.contain))
              .toList();

    Future<String> getSellerName(String sellerId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return data['displayName'];
        }
        return 'Unknown Seller';
      } catch (e) {
        return 'Error loading seller';
      }
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (currentUser?.uid == sellerId)
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "You are the owner of this product.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        "Seller: ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<String>(
                        future: getSellerName(sellerId),
                        builder: (context, sellerSnapshot) {
                          if (sellerSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text("...");
                          }

                          if (sellerSnapshot.hasError) {
                            return Text(
                              'Error loading seller',
                              style: TextStyle(fontSize: 18),
                            );
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MessageUser(otherUserId: sellerId),
                                ),
                              );
                            },
                            child: Text(
                              sellerSnapshot.data ?? 'Unknown Seller',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.8,
                height: screenHeight * 0.6,
                child: PageView(controller: pageController, children: pages),
              ),
            ),
          ),
          Center(
            child: SmoothPageIndicator(
              controller: pageController,
              count: pages.length,
              onDotClicked: (index) => pageController.jumpToPage(index),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Product Name", style: headerStyle()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(productName, style: textStyle()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Product Price", style: headerStyle()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "\$$productPrice",
              style: TextStyle(fontSize: 24, color: Colors.green[700]),
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Rating: ", style: headerStyle()),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: RatingBar.builder(
                  initialRating: productRating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 30,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {},
                  ignoreGestures: true,
                ),
              ),
              Text(
                "(${productRating.toStringAsFixed(2)}/5)",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Product Description", style: headerStyle()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(productDescription, style: textStyle()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Comments", style: headerStyle()),
          ),
          _buildCommentSection(),
        ],
      ),
    );
  }
}

TextStyle headerStyle() {
  return TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
}

TextStyle textStyle() {
  return TextStyle(fontSize: 24);
}
