import 'package:flutter/material.dart';
import 'package:flutterbase/shared/components/base_layout.dart';
import 'package:flutterbase/shared/components/app_footer.dart';

/// Home Screen - Example implementation
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFooterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      headerTitle: 'FlutterBase',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to FlutterBase',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Your production-ready Flutter app base',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed!')),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
      showFooter: true,
      footerItems: [
        FooterItem(
          icon: Icons.home,
          label: 'Home',
        ),
        FooterItem(
          icon: Icons.search,
          label: 'Search',
        ),
        FooterItem(
          icon: Icons.add_circle,
          label: 'Add',
        ),
        FooterItem(
          icon: Icons.notifications,
          label: 'Notifications',
        ),
        FooterItem(
          icon: Icons.person,
          label: 'Profile',
        ),
      ],
      selectedFooterIndex: _selectedFooterIndex,
      onFooterItemTapped: (index) {
        setState(() {
          _selectedFooterIndex = index;
        });
        // Handle navigation based on index
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped item at index $index')),
        );
      },
    );
  }
}
