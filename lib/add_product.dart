import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _offerValueController = TextEditingController();
  bool _isUploading = false;
  final List<XFile> _selectedImages = [];
  final List<String> _categories = [
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
  final List<String> _selectedCategories = [];
  final ImagePicker _picker = ImagePicker();
  DateTime? _offerEndDate;
  double? _offerValue;
  bool _isOnOffer = false;
  final List<String> couponCodes = [];
  final List<int> couponValues = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Add New Product")),
        actions: [
          IconButton(
            onPressed: _isUploading ? null : _submitProduct,
            icon: Icon(Icons.check),
          ),
        ],
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Product Name",
                          labelStyle: TextStyle(fontSize: 24),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: "Product Price",
                          labelStyle: TextStyle(fontSize: 24),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _descriptionController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        minLines: 5,
                        decoration: InputDecoration(
                          labelText: "Product Description",
                          labelStyle: TextStyle(fontSize: 24),
                          hintText: "Add a description for your item...",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    __buildCategoriesSection(),
                    _buildImageSection(),
                    _buildOfferSection(),
                    _buildCouponSection(),
                    // Base64Image(
                    //   base64String: "",
                    //   width: 100,
                    //   height: 100,
                    // ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submitProduct() {
    addProductToDatabase();
  }

  Future<void> addProductToDatabase() async {
    try {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please make sure to include at least one image"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (_isOnOffer &&
          (_offerEndDate == null || _offerValueController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please make sure to fill the offer section"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      } else if (_isOnOffer &&
          (int.tryParse(_offerValueController.text) == null ||
              int.parse(_offerValueController.text) < 1 ||
              int.parse(_offerValueController.text) > 100)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please make sure to fill the offer section with a number from 1-100",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (couponCodes.isNotEmpty) {
        if (couponCodes.contains("")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please make sure to fill the coupons section"),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      setState(() {
        _isUploading = true;
      });

      List<String> base64Images = await _convertImagesToBase64();

      var doc = await FirebaseFirestore.instance.collection("products").add({
        "name": _nameController.text,
        "price": double.parse(_priceController.text),
        "description": _descriptionController.text,
        "imageUrls": base64Images,
        "categories": _selectedCategories,
        "rating": 0,
        "offerEndDate": (_offerEndDate == null)
            ? DateTime.now().millisecondsSinceEpoch - 1000000000
            : _offerEndDate?.microsecondsSinceEpoch,
        "offerValue": (_offerValueController.text.isEmpty)
            ? 0
            : int.parse(_offerValueController.text),
        "sellerId": FirebaseAuth.instance.currentUser?.uid,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      });

      if (couponCodes.isNotEmpty) {
        int i = 0;
        for (var couponCode in couponCodes) {
          doc.collection('coupons').add({
            "code": couponCode,
            "discountValue": couponValues[i],
          });
          i++;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product added successfully!')));

      setState(() {
        _isUploading = false;
      });
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Product Images',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ReorderableGridView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final XFile item = _selectedImages.removeAt(oldIndex);
                  _selectedImages.insert(newIndex, item);
                });
              },
              dragStartDelay: Duration(milliseconds: 80),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  key: ValueKey(index),
                  children: [
                    Image.file(
                      File(_selectedImages[index].path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeImage(index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _pickImages,
            icon: Icon(Icons.add_photo_alternate),
            label: Text('Add Images'),
          ),
        ),
      ],
    );
  }

  Widget __buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: __showEditCategoriesDialog,
            child: Text('Select Categories'),
          ),
          SizedBox(height: 8),
          if (_selectedCategories.isNotEmpty) ...[
            Text('Selected _Categories:'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedCategories.map((category) {
                return Chip(
                  label: Text(category),
                  onDeleted: () {
                    setState(() {
                      _selectedCategories.remove(category);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    // return Column(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: [
    //     Padding(
    //       padding: const EdgeInsets.all(8.0),
    //       child: Row(
    //         children: [
    //           Text(
    //             'Product _Categories',
    //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    //           ),
    //           IconButton(
    //             onPressed: () {
    //               __showEditCategoriesDialog();
    //             },
    //             icon: const Icon(Icons.edit),
    //           ),
    //         ],
    //       ),
    //     ),
    //     Padding(
    //       padding: const EdgeInsets.only(left: 8, right: 8),
    //       child: Text(_categories.join(", "), style: TextStyle(fontSize: 18)),
    //     ),
    //   ],
    // );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];

    for (var imageFile in _selectedImages) {
      try {
        final bytes = await File(imageFile.path).readAsBytes();

        String base64String = base64Encode(bytes);

        String dataUri = 'data:image/jpeg;base64,$base64String';
        base64Images.add(dataUri);
      } catch (e) {
        debugPrint('Error converting image to base64: $e');
        throw Exception('Failed to process images');
      }
    }

    return base64Images;
  }

  void __showEditCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Edit  Categories'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _categories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: _selectedCategories.contains(category),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOfferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text('Enable Discount'),
          value: _isOnOffer,
          onChanged: (value) {
            setState(() {
              _isOnOffer = value;
            });
          },
        ),

        if (_isOnOffer) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _offerValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Discount Value",
                labelStyle: TextStyle(fontSize: 24),
                hintText: "1-100",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              (_offerEndDate == null)
                  ? 'Select end date'
                  : 'Ends: ${DateFormat('MMM dd, yyyy').format(_offerEndDate!)}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (selectedDate != null) {
                setState(() {
                  _offerEndDate = selectedDate;
                });
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text(
            "Add a coupon code",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            setState(() {
              couponCodes.add("");
              couponValues.add(1);
            });
          },
        ),

        ListView.builder(
          itemCount: couponCodes.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final TextEditingController couponCodeController =
                TextEditingController();
            final TextEditingController couponValueController =
                TextEditingController();
            couponCodeController.text = couponCodes[index];
            couponValueController.text = couponValues[index].toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: couponCodeController,
                      onChanged: (value) => couponCodes[index] = value,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Coupon Code",
                        labelStyle: TextStyle(fontSize: 24),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: couponValueController,
                      onChanged: (value) =>
                          couponValues[index] = int.tryParse(value) ?? 1,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Coupon Value",
                        labelStyle: TextStyle(fontSize: 24),
                        hintText: "1-100",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        couponCodes.removeAt(index);
                        couponValues.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, size: 30, color: Colors.red),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}