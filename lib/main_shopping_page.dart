import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/ThemeProvider.dart';
import 'package:shopping_app/cart_page.dart';
import 'package:shopping_app/categories_page.dart';
import 'package:shopping_app/favorites_page.dart';
import 'package:shopping_app/home_page.dart';
import 'package:shopping_app/messages_page.dart';
import 'package:shopping_app/profile_page.dart';
import 'package:shopping_app/search_products_page.dart';
import 'package:shopping_app/sign_in_page.dart';

class MainShoppingPage extends StatefulWidget {
  const MainShoppingPage({super.key});

  @override
  MainShoppingPageState createState() => MainShoppingPageState();
}

class MainShoppingPageState extends State<MainShoppingPage> {
  int _currentIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;

  final List<Widget> _pages = [
    HomePage(),
    FavoritesPage(),
    CartPage(),
    MessagesPage(),
  ];

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.light_mode),
                title: Text('Light Theme'),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.dark_mode),
                title: Text('Dark Theme'),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.phone_android),
                title: Text('System Default'),
                onTap: () {
                  themeProvider.setTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInPage()),
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(
    String value,
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    switch (value) {
      case 'theme':
        _showThemeDialog(context, themeProvider);
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? _buildSearchField()
          : Center(child: Text('Shopping app')),
      backgroundColor: Colors.cyan,
      actions: _buildAppBarActions(),
    );
  }

  bool _isNavigating = false;
  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search for products...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[800]),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onSubmitted: (value) {
        if (_isNavigating) return;
        _searchQuery = value;
        _isSearching = true;
        _isNavigating = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchProductsPage(searchQuery: _searchQuery),
          ),
        ).then((_) {
          _isNavigating = false;
        });
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
            });
          },
        ),
      ];
    } else {
      final themeProvider = Provider.of<ThemeProvider>(context);
      return [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.settings),
          onSelected: (value) {
            _handleMenuSelection(value, context, themeProvider);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  Icon(Icons.color_lens, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Change Theme'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ];
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: Colors.pink,
      backgroundColor: Colors.cyan,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.shifting,
      unselectedItemColor: Colors.blueGrey,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
      ],
    );
  }
}
