import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

class Transaction {
  Transaction(
      this.description,
      this.amount,
      this.isIn, {
        this.id = '',
        this.createdAt,
      });

  final String description;
  final int amount;
  final bool isIn;
  final String id;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {'description': description, 'amount': amount, 'isIn': isIn};
  }

  factory Transaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Transaction(
      data['description'] as String,
      (data['amount'] as num).toInt(),
      data['isIn'] as bool,
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
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