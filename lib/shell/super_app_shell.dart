import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:misana_finance_app/shell/pages/super_home_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/profile_page.dart';
import 'package:misana_finance_app/shell/pages/super_services_page.dart';

class SuperAppShell extends StatefulWidget {
  const SuperAppShell({super.key});

  @override
  State<SuperAppShell> createState() => _SuperAppShellState();
}

class _SuperAppShellState extends State<SuperAppShell> {
  int _index = 0;
  DateTime? _lastBackPressAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }

        final now = DateTime.now();
        final shouldConfirm =
            _lastBackPressAt == null ||
            now.difference(_lastBackPressAt!) > const Duration(seconds: 2);

        if (shouldConfirm) {
          _lastBackPressAt = now;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bonyeza back tena kutoka kwenye app'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            SuperHomePage(onExploreServices: () => setState(() => _index = 1)),
            const SuperServicesPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_rounded),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
