import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../theme/finora_theme.dart';
import '../widgets/finora_header.dart';
import 'dashboard_screen.dart';
import 'logs_screen.dart';
import 'filters_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final BlockerService service;

  const MainShell({
    super.key,
    required this.service,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.service,
      builder: (context, _) {
        final isWide = MediaQuery.of(context).size.width >= 750;

        final screens = [
          DashboardScreen(
            service: widget.service,
            onNavigateToLogs: () => setState(() => _selectedIndex = 1),
          ),
          LogsScreen(service: widget.service),
          FiltersScreen(service: widget.service),
          RulesScreen(service: widget.service),
          SettingsScreen(service: widget.service),
        ];

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                FinoraHeader(isShieldActive: widget.service.isShieldActive),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            NavigationRail(
                              backgroundColor: FinoraColors.surface,
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: (index) {
                                setState(() => _selectedIndex = index);
                              },
                              labelType: NavigationRailLabelType.all,
                              selectedIconTheme: const IconThemeData(color: FinoraColors.red),
                              unselectedIconTheme: const IconThemeData(color: FinoraColors.textMuted),
                              selectedLabelTextStyle: const TextStyle(
                                color: FinoraColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              unselectedLabelTextStyle: const TextStyle(
                                color: FinoraColors.textMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                              indicatorColor: FinoraColors.red.withValues(alpha: 0.15),
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.shield_outlined),
                                  selectedIcon: Icon(Icons.shield),
                                  label: Text('Kalkan'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.list_alt_outlined),
                                  selectedIcon: Icon(Icons.list_alt),
                                  label: Text('Günlük'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.filter_list),
                                  selectedIcon: Icon(Icons.filter_list_outlined),
                                  label: Text('Filtreler'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.rule_outlined),
                                  selectedIcon: Icon(Icons.rule),
                                  label: Text('Kurallar'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.settings_outlined),
                                  selectedIcon: Icon(Icons.settings),
                                  label: Text('Ayarlar'),
                                ),
                              ],
                            ),
                            const VerticalDivider(width: 1, color: FinoraColors.border),
                            Expanded(child: screens[_selectedIndex]),
                          ],
                        )
                      : screens[_selectedIndex],
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    color: FinoraColors.surface,
                    border: Border(
                      top: BorderSide(color: FinoraColors.border, width: 1),
                    ),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: FinoraColors.surface,
                    selectedItemColor: FinoraColors.red,
                    unselectedItemColor: FinoraColors.textMuted,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.shield_outlined),
                        activeIcon: Icon(Icons.shield),
                        label: 'Kalkan',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.list_alt_outlined),
                        activeIcon: Icon(Icons.list_alt),
                        label: 'Günlük',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.filter_list),
                        activeIcon: Icon(Icons.filter_list_outlined),
                        label: 'Filtreler',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.rule_outlined),
                        activeIcon: Icon(Icons.rule),
                        label: 'Kurallar',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings_outlined),
                        activeIcon: Icon(Icons.settings),
                        label: 'Ayarlar',
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
