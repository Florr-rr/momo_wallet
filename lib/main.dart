class Transaction {
  Transaction(this.description, this.amount, this.isIn);

  final String description;
  final int amount;
  final bool isIn; // true = money IN, false = money OUT
}

void main() {
  final transactions = [
    Transaction('Salary', 15000, true),
    Transaction('Airtime', 3000, false),
    Transaction('Sent to Keza', 2000, false),
  ];

  var balance = 0;
  for (final t in transactions) {
    if (t.isIn) {
      balance += t.amount;
    } else {
      balance -= t.amount;
    }
    print('${t.description}: ${t.isIn ? '+' : '-'}${t.amount} RWF');
  }
  print('Balance: $balance RWF');
}