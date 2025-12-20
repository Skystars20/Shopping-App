import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/view_product_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    UserRepository.refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    final userData = UserRepository.userData;
    final cartProducts = userData?['cartProducts'] as List<dynamic>?;
    if (cartProducts == null || cartProducts.isEmpty) {
      return Center(child: Text('You don\'t have products in your cart yet'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: cartProducts)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading products'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('You don\'t have products in your cart yet'),
          );
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(8),
          shrinkWrap: true,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            final productData = doc.data() as Map<String, dynamic>;
            final imageBase64s = productData['imageUrls'] as List<dynamic>?;
            final firstImageBase64 =
                (imageBase64s != null && imageBase64s.isNotEmpty)
                ? imageBase64s[0]
                : null;
            final productName = productData['name'];
            final productPrice = productData['price'];
            final productRating = productData['rating'] + 0.0;
            final productId = doc.id;
            final isOnOffer =
                (productData['offerEndDate'] >
                DateTime.now().millisecondsSinceEpoch);

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
              },
              child: Container(
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: (firstImageBase64 != null)
                          ? Stack(
                              children: [
                                Base64Image(
                                  base64String: firstImageBase64,
                                  width: 100,
                                  height: 100,
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
                            )
                          : Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[600],
                                size: 50,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
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
                            RatingBar.builder(
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
                                size: 16,
                              ),
                              onRatingUpdate: (rating) {},
                              ignoreGestures: true,
                            ),
                            _buildProductButtons(doc, productId),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductButtons(
    QueryDocumentSnapshot<Object?> doc,
    String productId,
  ) {
    final userData = UserRepository.userData;
    final favoriteProducts = userData?['favoriteProducts'] as List<dynamic>?;
    final isFavorite = favoriteProducts?.contains(doc.id) ?? false;

    return Row(
      children: [
        TextButton(
          onPressed: () {
            _removeFromCart(productId);
          },
          child: Text("Remove from cart"),
        ),
        IconButton(
          onPressed: () {
            _toggleFavorite(productId, isFavorite);
          },
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  void _toggleFavorite(String productId, bool isCurrentlyFavorite) async {
    UserRepository.refreshUserData();
    final userData = UserRepository.userData;
    if (userData == null) return;

    final userId = UserRepository.currentUser?.uid;
    final favoriteProducts = userData['favoriteProducts'] as List<dynamic>;
    List<dynamic> updatedFavoriteProducts = List.from(favoriteProducts);

    if (isCurrentlyFavorite) {
      updatedFavoriteProducts.remove(productId);
    } else {
      updatedFavoriteProducts.add(productId);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "favoriteProducts": updatedFavoriteProducts,
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error updating cart products: $e');
    }
  }

  void _removeFromCart(String productId) async {
    UserRepository.refreshUserData();
    final userData = UserRepository.userData;
    if (userData == null) return;

    final userId = UserRepository.currentUser?.uid;
    final cartProducts = userData['cartProducts'] as List<dynamic>;
    List<dynamic> updatedCartProducts = List.from(cartProducts);
    updatedCartProducts.remove(productId);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        "cartProducts": updatedCartProducts,
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error updating cart products: $e');
    }
  }
}
