import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/auth_service.dart';
import 'package:shopping_app/base_64_image.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? productData;
  final String productId;
  const CheckoutPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? couponCodeErrorMessage;
  final List<String> appliedCoupons = [];
  final List<int> appliedCouponValues = [];
  final TextEditingController couponCodeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final productName = widget.productData?['name'];
    final productPrice = widget.productData?['price'];
    final productOfferValue = widget.productData?['offerValue'];
    final productOfferEndDate = widget.productData?['offerEndDate'];
    late final bool isOnOffer;
    double finalPrice = productPrice;

    if (DateTime.now().millisecondsSinceEpoch < productOfferEndDate) {
      isOnOffer = true;
    } else {
      isOnOffer = false;
    }

    if (isOnOffer) {
      finalPrice -= productPrice * (productOfferValue / 100);
    }

    for (var discount in appliedCouponValues) {
      finalPrice -= productPrice * (discount / 100);
    }

    if (finalPrice < 0) {
      finalPrice = 0;
    }

    final productImage =
        (widget.productData?['imageUrls'] as List<dynamic>).first;

    return Scaffold(
      appBar: AppBar(title: const Center(child: Text("Checkout"))),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Base64Image(
                        base64String: productImage,
                        fit: BoxFit.contain,
                        width: 200,
                        height: 200,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            productName,
                            style: TextStyle(fontSize: 20),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text("Price", style: textStyle()),
                              ),
                              Text(
                                "\$${productPrice.toString()}",
                                style: textStyle(),
                              ),
                            ],
                          ),
                        ),
                        if (isOnOffer) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Offer",
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.green[500],
                                    ),
                                  ),
                                ),
                                Text(
                                  "-${productOfferValue.toString()}%",
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.green[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (appliedCoupons.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Text("Applied Coupons", style: textStyle()),
                          ),
                          ListView.builder(
                            itemCount: appliedCoupons.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 30,
                                          right: 30,
                                        ),
                                        child: Text(
                                          "- ${appliedCoupons[index]}",
                                          style: TextStyle(
                                            fontSize: 22,
                                            color: Colors.green[500],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "-${appliedCouponValues[index].toString()}%",
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.green[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text("Total", style: textStyle()),
                              ),
                              Text(
                                "\$${finalPrice.toString()}",
                                style: textStyle(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: couponCodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Coupon Code",
                                    labelStyle: TextStyle(fontSize: 24),
                                    border: OutlineInputBorder(),
                                    hintText: "Enter Coupon Code",
                                    errorText: couponCodeErrorMessage,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: TextButton(
                                    onPressed: () {
                                      _handleCouponApply();
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Text("Apply"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _handleBuy,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text("Buy Now"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBuy() async {
    UserRepository.refreshUserData();
    final currentUser = UserRepository.currentUser;
    final currentUserDataDoc = UserRepository.userData;

    final data = currentUserDataDoc?.data() as Map<String, dynamic>;
    final cartProducts = data['cartProducts'] as List<dynamic>;
    final purchasedProducts = data['purchasedProducts'] as List<dynamic>;
    final updatedCartProducts = List.from(cartProducts);
    final updatedPurchasedProducts = List.from(purchasedProducts);
    final bool isPurchased = purchasedProducts.contains(widget.productId);
    updatedCartProducts.remove(widget.productId);
    updatedPurchasedProducts.add(widget.productId);

    try {
      if (!isPurchased) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .update({"cartProducts": updatedCartProducts});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .update({"purchasedProducts": updatedPurchasedProducts});
        await UserRepository.refreshUserData();
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Product Purchased Successfully!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Product is already purchased.", style: TextStyle(color: Colors.black),),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.yellow,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error purchasing product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An Error occured"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }

    // final userData = await _firestore.collection('users').doc(currentUser?.uid).get();
  }

  void _handleCouponApply() async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('coupons')
        .where('code', isEqualTo: couponCodeController.text)
        .get()
        .then((QuerySnapshot snapshot) {
          if (snapshot.docs.isEmpty) {
            setState(() {
              couponCodeErrorMessage = "This coupon code doesn't exist";
            });
            return;
          }
          final data = snapshot.docs.first.data() as Map<String, dynamic>;
          if (appliedCoupons.contains(data['code'])) {
            setState(() {
              couponCodeErrorMessage = "You already applied this code";
            });
            return;
          }
          setState(() {
            appliedCoupons.add(data['code']);
            appliedCouponValues.add(data['discountValue']);
            couponCodeController.text = "";
            couponCodeErrorMessage = null;
          });
        });
  }
}

TextStyle textStyle() {
  return TextStyle(fontSize: 22);
}
