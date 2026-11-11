import 'package:flutter/material.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/features/products/presentation/screens/product_management_screen.dart';
import 'package:food_pos/features/reports/presentation/screens/reports_screen.dart';
import 'package:food_pos/features/settings/presentation/screens/settings_screen.dart';
import 'package:food_pos/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  final List<Widget> _pages = const [
    PosScreen(),
    ProductManagementScreen(),
    TransactionHistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: whiteColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: whiteColor,
          indicatorColor: primaryLightColor,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(IconsaxPlusLinear.shop, color: greyColor),
              selectedIcon: Icon(IconsaxPlusBold.shop, color: primaryColor),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(IconsaxPlusLinear.box, color: greyColor),
              selectedIcon: Icon(IconsaxPlusBold.box, color: primaryColor),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(IconsaxPlusLinear.receipt_text, color: greyColor),
              selectedIcon: Icon(
                IconsaxPlusBold.receipt_text,
                color: primaryColor,
              ),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(IconsaxPlusLinear.chart_2, color: greyColor),
              selectedIcon: Icon(IconsaxPlusBold.chart_2, color: primaryColor),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(IconsaxPlusLinear.setting_2, color: greyColor),
              selectedIcon: Icon(
                IconsaxPlusBold.setting_2,
                color: primaryColor,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
