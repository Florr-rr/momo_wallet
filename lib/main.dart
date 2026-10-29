import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'wallet.dart';
import 'weather.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const WalletScreen();
      },
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  // Ids swiped away: hidden at once, so the list updates immediately.
  final Set<String> hidden = {};

  @override
  void initState() {
    super.initState();
    stream = myTransactions().orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> add(Transaction t) async {
    await myTransactions().add({
      ...t.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void remove(Transaction t) {
    setState(() {
      hidden.add(t.id);
    });
    myTransactions().doc(t.id).delete();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${t.description}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Write the same data back, with its original time.
            myTransactions().doc(t.id).set({
              ...t.toMap(),
              'createdAt': t.createdAt != null
                  ? Timestamp.fromDate(t.createdAt!)
                  : FieldValue.serverTimestamp(),
            });
            setState(() {
              hidden.remove(t.id);
            });
          },
        ),
      ),
    );
  }

  Future<void> open(bool receive, int balance) async {
    final t = await showDialog<Transaction>(
      context: context,
      builder: (_) => TransactionDialog(receive: receive, balance: balance),
    );
    if (t != null) add(t);
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your transactions.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = snapshot.data!.docs
              .map(Transaction.fromDoc)
              .where((t) => !hidden.contains(t.id))
              .toList();
          final balance = balanceOf(transactions);
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
                          '$balance RWF',
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      onPressed: () => open(true, balance),
                      child: const Text('Receive'),
                    ),
                    FilledButton(
                      onPressed: () => open(false, balance),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                  child: Text(
                    'No transactions yet.\nTap Receive to add one.',
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, i) {
                    final t = transactions[i];
                    return Dismissible(
                      key: ValueKey(t.id),
                      onDismissed: (_) => remove(t),
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
        },
      ),
    );
  }
}

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({
    super.key,
    required this.receive,
    required this.balance,
  });

  final bool receive;
  final int balance;

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final first = TextEditingController();
  final second = TextEditingController();
  String? error;

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }

  void confirm() {
    final problem = widget.receive
        ? checkReceive(first.text, second.text)
        : checkSend(first.text, second.text, widget.balance);
    if (problem != null) {
      setState(() {
        error = problem;
      });
      return;
    }
    final amount = int.parse(second.text.trim());
    final name = first.text.trim();
    Navigator.pop(
      context,
      Transaction(widget.receive ? name : 'Sent to $name', amount, widget.receive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.receive ? 'Receive money' : 'Send money'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: first,
            keyboardType: widget.receive
                ? TextInputType.text
                : TextInputType.phone,
            decoration: InputDecoration(
              labelText: widget.receive ? 'Description' : 'Phone number',
            ),
          ),
          TextField(
            controller: second,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (RWF)'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: confirm, child: const Text('Confirm')),
      ],
    );
  }
}

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Weather? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await fetchKigaliWeather();
      setState(() {
        weather = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      child = Row(
        children: [
          const Icon(Icons.wifi_off),
          const SizedBox(width: 12),
          Expanded(child: Text(error!)),
          FilledButton(onPressed: retry, child: const Text('Retry')),
        ],
      );
    } else {
      final w = weather!;
      child = Row(
        children: [
          const Icon(Icons.cloud),
          const SizedBox(width: 12),
          Text('Kigali today: ${w.temperature.round()}°C, ${describe(w.code)}'),
        ],
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}