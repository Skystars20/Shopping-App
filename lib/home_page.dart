import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/checkout_page.dart';
import 'package:shopping_app/view_product_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    UserRepository.refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Featured Products", style: headerStyle()),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(height: 480, child: _buildListedProducts()),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Offers", style: headerStyle()),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 480,
                  child: _buildListedProducts(offer: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(String productId, bool isCurrentlyFavorite) async {
    UserRepository.refreshUserData();
    final userData = UserRepository.userData;
    if (userData == null) return;

    final userId = UserRepository.currentUser?.uid;
    final favoriteProducts = userData['favoriteProducts'] as List<dynamic>;
    List<dynamic> updatedFavorites = List.from(favoriteProducts);

    if (isCurrentlyFavorite) {
      updatedFavorites.remove(productId);
    } else {
      updatedFavorites.add(productId);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "favoriteProducts": updatedFavorites,
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error updating favorites: $e');
    }
  }

  void _addToCart(String productId) async {
    UserRepository.refreshUserData();
    final userData = UserRepository.userData;
    if (userData == null) return;

    final userId = UserRepository.currentUser?.uid;
    final cartProducts = userData['cartProducts'] as List<dynamic>;
    List<dynamic> updatedCartProducts = List.from(cartProducts);
    updatedCartProducts.add(productId);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "cartProducts": updatedCartProducts,
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error updating cart products: $e');
    }
  }

  Widget _buildListedProducts({bool offer = false}) {
    Stream<QuerySnapshot<Map<String, dynamic>>> stream = FirebaseFirestore
        .instance
        .collection('products')
        .orderBy('rating', descending: true)
        .snapshots();
    if (offer) {
      stream = FirebaseFirestore.instance
          .collection('products')
          .where(
            'offerEndDate',
            isGreaterThan: DateTime.now().millisecondsSinceEpoch,
          )
          .snapshots();
    }
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildPlaceholder(
            height: 100,
            child: Text('Error loading products', textAlign: TextAlign.center),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPlaceholder(
            height: 100,
            child: Text('No products listed yet', textAlign: TextAlign.center),
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
              final isOnOffer =
                  (productData['offerEndDate'] >
                  DateTime.now().millisecondsSinceEpoch);
              final imageBase64s = productData['imageUrls'] as List<dynamic>?;
              final firstImageBase64 =
                  imageBase64s != null && imageBase64s.isNotEmpty
                  ? imageBase64s[0]
                  : null;
              final productName = productData['name'];
              final productPrice = productData['price'];
              final productRating = productData['rating'] + 0.0;
              final productId = doc.id;

              double finalPrice = productPrice;
              if (isOnOffer) {
                finalPrice =
                    productPrice -
                    (productPrice * productData['offerValue'] / 100);
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewProductPage(id: productId),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                  ;
                },
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
                              Stack(
                                children: [
                                  Base64Image(
                                    base64String: firstImageBase64,
                                    width: 250,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),

                                  if (isOnOffer) ...[
                                    Positioned(
                                      top: 10,
                                      left: -30,
                                      child: Transform.rotate(
                                        angle: -0.785,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 40,
                                          ),
                                          color: Colors.red,
                                          child: Text(
                                            "Offer",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    productName,
                                    style: TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 6,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "\$${productPrice.toString()}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: (isOnOffer)
                                            ? Colors.red[700]
                                            : Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                        decoration: (isOnOffer)
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isOnOffer) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "\$$finalPrice",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
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
                                  itemSize: 16,
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
                              ),
                              _buildProductButtons(doc),
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

  Widget _buildProductButtons(QueryDocumentSnapshot<Object?> doc) {
    final productData = doc.data() as Map<String, dynamic>;
    late bool isOwnProduct;
    late bool isFavorite;
    late bool isInCart;
    late bool isPurchased;

    final userId = UserRepository.currentUser?.uid;
    final userData = UserRepository.userData;
    final favoriteProducts = userData?['favoriteProducts'] as List<dynamic>;
    final cartProducts = userData?['cartProducts'] as List<dynamic>;
    final purchasedProducts = userData?['purchasedProducts'] as List<dynamic>;

    isOwnProduct = (userId == productData['sellerId']);
    isFavorite = (favoriteProducts.contains(doc.id));
    isInCart = (cartProducts.contains(doc.id));
    isPurchased = (purchasedProducts.contains(doc.id));

    return (isOwnProduct)
        ? Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Center(child: Text("You are the seller"))
                ),
                IconButton(
                  onPressed: () {
                    _handleDeleteProduct(doc.id);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          )
        : (isPurchased)
        ? Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Expanded(child: Center(child: Text("Product is purchased"))),
                IconButton(
                  onPressed: () {
                    _toggleFavorite(doc.id, isFavorite);
                  },
                  icon: (isFavorite)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border, color: Colors.black),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: (isInCart)
                      ? TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(
                                  productId: doc.id,
                                  productData: productData,
                                ),
                              ),
                            );
                          },
                          child: Text("Proceed to checkout"),
                        )
                      : TextButton(
                          onPressed: () {
                            _addToCart(doc.id);
                          },
                          child: Text("Add to cart"),
                        ),
                ),
                IconButton(
                  onPressed: () {
                    _toggleFavorite(doc.id, isFavorite);
                  },
                  icon: (isFavorite)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border, color: Colors.black),
                ),
              ],
            ),
          );
  }

  Widget _buildPlaceholder({required double height, required Widget child}) {
    return SizedBox(
      height: height,
      child: Center(child: child),
    );
  }

  void _handleDeleteProduct(String id) {
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
                    .doc(id)
                    .delete();
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
}

TextStyle headerStyle() {
  return TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
}
