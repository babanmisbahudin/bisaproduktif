// This file is deprecated. Use AdminPanelScreen instead.
import 'package:flutter/material.dart';

class AdminRewardClaimsScreen extends StatelessWidget {
  const AdminRewardClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ℹ️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Screen ini sudah dipindahkan ke Admin Dashboard',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
