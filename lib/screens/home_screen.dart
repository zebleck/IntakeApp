import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lists_screen.dart';
import 'recipes_screen.dart';
import 'tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final _screens = const [
    TrackerScreen(),
    RecipesScreen(),
    ListsScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.timeline_outlined, activeIcon: Icons.timeline, label: 'Tracker'),
    _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Recipes'),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Lists'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                return _screens[index];
              },
            ),
          ),
          // Frosted nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21).withAlpha(180),
                    border: const Border(
                      top: BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_navItems.length, (i) {
                          final item = _navItems[i];
                          final isActive = _currentIndex == i;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onNavTap(i),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Glow bar
                                  AnimatedOpacity(
                                    opacity: isActive ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 250),
                                    child: Container(
                                      width: 24,
                                      height: 3,
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromARGB(100, 102, 126, 234),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    color: isActive
                                        ? const Color(0xFF667EEA)
                                        : Colors.white38,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 11,
                                      fontWeight:
                                          isActive ? FontWeight.w700 : FontWeight.w400,
                                      color: isActive
                                          ? const Color(0xFF667EEA)
                                          : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
