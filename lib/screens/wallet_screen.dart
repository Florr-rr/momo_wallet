import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../state/wallet_state.dart';
import 'transaction_dialog.dart';
import 'weather_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  // Open the dialog and hand it the SAME brain.
  Future<void> _open(BuildContext context, bool receive) async {
    final wallet = context.read<WalletState>(); // read BEFORE the await
    final t = await showDialog<Transaction>(
      context: context,
      builder: (_) => ChangeNotifierProvider<WalletState>.value(
        value: wallet,
        child: TransactionDialog(receive: receive),
      ),
    );
    if (t != null) await wallet.add(t);
  }

  void _remove(BuildContext context, Transaction t) {
    final wallet = context.read<WalletState>();
    final messenger = ScaffoldMessenger.of(context);
    wallet.remove(t);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted ${t.description}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => wallet.restore(t),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _body(context, wallet),
    );
  }

  Widget _body(BuildContext context, WalletState wallet) {
    if (wallet.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(wallet.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (wallet.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final txns = wallet.visible;
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Text('Balance'),
                  Text(
                    '${wallet.balance} RWF',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const WeatherCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: ['all', 'in', 'out']
                .map(
                  (f) => ChoiceChip(
                label: Text(f.toUpperCase()),
                selected: wallet.filter == f,
                onSelected: (_) =>
                    context.read<WalletState>().setFilter(f),
              ),
            )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                onPressed: () => _open(context, true),
                child: const Text('Receive'),
              ),
              FilledButton(
                onPressed: () => _open(context, false),
                child: const Text('Send'),
              ),
            ],
          ),
        ),
        Expanded(
          child: wallet.transactions.isEmpty
              ? const Center(
            child: Text(
              'No transactions yet.\nTap Receive to add one.',
              textAlign: TextAlign.center,
            ),
          )
              : txns.isEmpty
              ? const Center(child: Text('Nothing matches this filter.'))
              : ListView.builder(
            itemCount: txns.length,
            itemBuilder: (context, i) {
              final t = txns[i];
              return Dismissible(
                key: ValueKey(t.id),
                onDismissed: (_) => _remove(context, t),
                background: Container(color: Colors.red),
                child: ListTile(
                  leading: Icon(
                    t.isIn
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: t.isIn ? Colors.green : Colors.red,
                  ),
                  title: Text(t.description),
                  trailing: Text(
                    '${t.isIn ? '+' : '-'}${t.amount} RWF',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}