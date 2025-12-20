import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';
import 'package:shopping_app/checkout_page.dart';
import 'package:shopping_app/view_product_page.dart';

class SearchProductsPage extends StatefulWidget {
  final String searchQuery;
  const SearchProductsPage({super.key, required this.searchQuery});

  @override
  State<SearchProductsPage> createState() => _SearchProductsPageState();
}

class _SearchProductsPageState extends State<SearchProductsPage> {
  final List<String> allCategories = [
    'Electronics',
    'Clothing',
    'Appliances',
    'Devices',
    'Books',
    'Sports',
    'Toys',
    'Health',
    'Automotive',
    'Other',
  ];
  int priceMin = 0;
  int priceMax = 10000000;
  List<String> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    String priceMinValue = "";
    String priceMaxValue = "";
    String? priceMinErrorMessage;
    String? priceMaxErrorMessage;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .where("name", isGreaterThanOrEqualTo: widget.searchQuery)
        .where("name", isLessThanOrEqualTo: "${widget.searchQuery}\uf7ff")
        .where("price", isGreaterThanOrEqualTo: priceMin)
        .where("price", isLessThanOrEqualTo: priceMax);

    if (selectedCategories.isNotEmpty) {
      query = query.where("categories", arrayContainsAny: selectedCategories);
    }

    void handleFilter() {
      showDialog(
        context: context,
        builder: (contxt) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: Text("Filter Options"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price from"),
                      TextField(
                        onChanged: (value) => {priceMinValue = value},
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          labelText: "Min Price",
                          labelStyle: TextStyle(fontSize: 24),
                          border: OutlineInputBorder(),
                          errorText: priceMinErrorMessage,
                        ),
                      ),
                      Text("To"),
                      TextField(
                        onChanged: (value) => {priceMaxValue = value},
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          labelText: "Max Price",
                          labelStyle: TextStyle(fontSize: 24),
                          border: OutlineInputBorder(),
                          errorText: priceMaxErrorMessage,
                        ),
                      ),
                      Text("Categories"),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: allCategories.map((category) {
                          return CheckboxListTile(
                            title: Text(category),
                            value: selectedCategories.contains(category),
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedCategories.add(category);
                                } else {
                                  selectedCategories.remove(category);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      selectedCategories = [];
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (priceMaxValue.isNotEmpty) {
                        priceMax = int.parse(priceMaxValue);
                      } else {
                        priceMax = 10000000;
                      }
                      if (priceMinValue.isNotEmpty) {
                        priceMin = int.parse(priceMinValue);
                      } else {
                        priceMin = 0;
                      }
                      if (priceMaxErrorMessage == null &&
                          priceMinErrorMessage == null) {
                        Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    child: Text('Apply Filter'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: handleFilter, icon: Icon(Icons.filter_alt)),
        ],
      ),
      body: FutureBuilder(
        future: query.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Couldn\'t find any products with that name'),
            );
          }

          final products =
              snapshot.data?.docs
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

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
                              _buildProductButtons(doc),
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
      ),
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
        ? Center(child: Text("You are the owner of this product"))
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
}
