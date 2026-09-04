import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/store.dart';
import 'core/theme.dart';
import 'features/root_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WorkbenchApp(prefs: prefs));
}

class WorkbenchApp extends StatelessWidget {
  final SharedPreferences prefs;

  const WorkbenchApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStore(prefs),
      child: Consumer<AppStore>(
        builder: (context, store, _) {
          return MaterialApp(
            title: '小窝工作台',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.build(context, store.palette),
            home: const RootGate(),
          );
        },
      ),
    );
  }
}
