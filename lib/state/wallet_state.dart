import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class WalletState extends ChangeNotifier {
  WalletState(this._repo) {
    debugPrint('Brain born for ${_repo.uid}');
    // Born: open the pipe to the backend, once.
    _subscription = _repo.watchAll().listen(
          (list) {
        _all = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your transactions.';
        notifyListeners();
      },
    );
  }

  final TransactionRepository _repo;
  StreamSubscription<List<Transaction>>? _subscription;

  // The data: private, so only the brain can change it.
  List<Transaction> _all = [];
  final Set<String> _hidden = {}; // swiped away: hidden at once
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'in' or 'out'

  // Read-only views for the screens.
  bool get loading => _loading;
  String? get error => _error;
  String get filter => _filter;

  List<Transaction> get transactions =>
      _all.where((t) => !_hidden.contains(t.id)).toList();

  // Never saved, computed every time it is read.
  int get balance => transactions.fold<int>(
      0, (total, t) => t.isIn ? total + t.amount : total - t.amount);

  // What the list shows: the transactions, narrowed by the filter.
  List<Transaction> get visible {
    final list = transactions;
    if (_filter == 'in') return list.where((t) => t.isIn).toList();
    if (_filter == 'out') return list.where((t) => !t.isIn).toList();
    return list;
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  // Actions: the brain hands the job to the repository.
  Future<void> add(Transaction t) => _repo.add(t);
  Future<void> edit(String id, Transaction t) => _repo.update(id, t);

  Future<void> remove(Transaction t) async {
    _hidden.add(t.id);
    notifyListeners();
    await _repo.delete(t.id);
  }

  Future<void> restore(Transaction t) async {
    _hidden.remove(t.id);
    notifyListeners();
    await _repo.restore(t);
  }

  @override
  void dispose() {
    debugPrint('Brain disposed: pipe closed');
    _subscription?.cancel();
    super.dispose();
  }
}