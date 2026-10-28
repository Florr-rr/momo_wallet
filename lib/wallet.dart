import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  Transaction(this.description, this.amount, this.isIn);

  final String description;
  final int amount;
  final bool isIn;

  Map<String, dynamic> toJson() {
    return {'description': description, 'amount': amount, 'isIn': isIn};
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      json['description'] as String,
      json['amount'] as int,
      json['isIn'] as bool,
    );
  }
}

List<Transaction> sampleTransactions() {
  return [
    Transaction('Salary', 15000, true),
    Transaction('Airtime', 3000, false),
    Transaction('Sent to Keza', 2000, false),
  ];
}

int balanceOf(List<Transaction> list) {
  var balance = 0;
  for (final t in list) {
    if (t.isIn) {
      balance += t.amount;
    } else {
      balance -= t.amount;
    }
  }
  return balance;
}

// Returns null if OK, or a message saying which rule failed.
String? checkReceive(String description, String amountText) {
  if (description.trim().isEmpty) {
    return 'Type a description first';
  }
  final amount = int.tryParse(amountText.trim());
  if (amount == null) {
    return 'The amount must be a whole number';
  }
  if (amount <= 0) {
    return 'The amount must be above 0';
  }
  return null;
}

String? checkSend(String phone, String amountText, int balance) {
  phone = phone.trim();
  if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
    return 'The phone number must be exactly 10 digits';
  }
  if (!phone.startsWith('078') && !phone.startsWith('079')) {
    return 'The phone number must start with 078 or 079';
  }
  final amount = int.tryParse(amountText.trim());
  if (amount == null) {
    return 'The amount must be a whole number';
  }
  if (amount < 100) {
    return 'The amount must be at least 100 RWF';
  }
  if (amount > balance) {
    return 'The amount must not be more than your balance';
  }
  return null;
}

Future<void> saveTransactions(List<Transaction> list) async {
  final prefs = await SharedPreferences.getInstance();
  final json = list.map((t) => t.toJson()).toList();
  await prefs.setString('transactions', jsonEncode(json));
}

// Returns null the very first time (nothing saved yet).
Future<List<Transaction>?> loadTransactions() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('transactions');
  if (saved == null) return null;
  final list = jsonDecode(saved) as List;
  return list
      .map((x) => Transaction.fromJson(x as Map<String, dynamic>))
      .toList();
}