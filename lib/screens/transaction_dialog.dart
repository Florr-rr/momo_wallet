import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../state/wallet_state.dart';

class TransactionDialog extends StatefulWidget {
  const TransactionDialog({super.key, required this.receive});

  final bool receive;

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
    final balance = context.read<WalletState>().balance;
    final problem = widget.receive
        ? checkReceive(first.text, second.text)
        : checkSend(first.text, second.text, balance);
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
    final balance = context.watch<WalletState>().balance;
    return AlertDialog(
      title: Text(widget.receive ? 'Receive money' : 'Send money'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your balance: $balance RWF',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: first,
            keyboardType:
            widget.receive ? TextInputType.text : TextInputType.phone,
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