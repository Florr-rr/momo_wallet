import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../models/transaction.dart';

class TransactionRepository {
  TransactionRepository(this.uid);

  final String uid;

  // users/{uid}/transactions: the path your security rules protect.
  CollectionReference<Map<String, dynamic>> get _transactions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions');

  // The pipe: the list now, and again after every change.
  Stream<List<Transaction>> watchAll() => _transactions
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Transaction.fromDoc).toList());

  Future<void> add(Transaction t) => _transactions.add({
    ...t.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> update(String id, Transaction t) =>
      _transactions.doc(id).update(t.toMap());

  Future<void> delete(String id) => _transactions.doc(id).delete();

  // Undo: write the same data back, with its original time.
  Future<void> restore(Transaction t) => _transactions.doc(t.id).set({
    ...t.toMap(),
    'createdAt': t.createdAt != null
        ? Timestamp.fromDate(t.createdAt!)
        : FieldValue.serverTimestamp(),
  });

  // Sample data for a brand new account.
  Future<void> addSamples() async {
    final now = DateTime.now();
    final samples = [
      Transaction('Salary', 15000, true),
      Transaction('Airtime', 3000, false),
      Transaction('Sent to Keza', 2000, false),
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < samples.length; i++) {
      batch.set(_transactions.doc(), {
        ...samples[i].toMap(),
        'createdAt': Timestamp.fromDate(now.subtract(Duration(seconds: i))),
      });
    }
    await batch.commit();
  }
}