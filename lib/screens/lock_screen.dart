import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  String? _error;

  void _masuk() {
    final s = SettingsService.instance;
    if (s.pinCocok(_pinCtrl.text)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _error = 'PIN salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = SettingsService.instance.namaWarung;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(Icons.lock_outline, size: 42, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Masukkan PIN kasir'),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'PIN',
                                    errorText: _error,
                ),
                onSubmitted: (_) => _masuk(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _masuk,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Buka kasir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
