import 'package:flutter/material.dart';
import 'package:origami/app/theme.dart';
import 'package:origami/core/library/library_api.dart';
import 'package:origami/features/contribution/screens/contribution_screens.dart';
import 'package:origami/features/explore/screens/library_screen.dart';
import 'package:origami/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:origami/features/profile/screens/profile_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0, this.libraryGateway});

  final int initialIndex;
  final LibraryGateway? libraryGateway;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Newsfeed',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_box_outlined),
      selectedIcon: Icon(Icons.add_box),
      label: 'Create',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const NewsfeedHomeTab(),
          LibraryTab(active: _index == 1, gateway: widget.libraryGateway),
          const CreatorHubTab(),
          const ProfileHomeTab(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: _destinations,
        ),
      ),
    );
  }
}
