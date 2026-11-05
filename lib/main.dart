// MoMo Wallet translation table (Session 7)
// Guide name              -> Mine
// Txn, txn.dart           -> Transaction, models/transaction.dart
// transactions collection -> transactions
// TxnRepository           -> TransactionRepository
// WalletState             -> WalletState
// balance                 -> balance
// WalletScreen, TxnForm   -> WalletScreen, TransactionDialog

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MomoApp());
}

class MomoApp extends StatelessWidget {
  const MomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber),
      home: const AuthGate(),
    );
  }
}