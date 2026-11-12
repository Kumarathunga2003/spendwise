enum EntryType { income, expense }

class MoneyTransaction {
  final String id;
  final String title;
  final double amount;
  final EntryType type;
  final String category;
  final DateTime date;
  final String note;

  const MoneyTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) {
    return MoneyTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income' ? EntryType.income : EntryType.expense,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: (json['note'] as String?) ?? '',
    );
  }
}

class BudgetLimit {
  final String category;
  final double amount;

  const BudgetLimit({required this.category, required this.amount});

  Map<String, dynamic> toJson() => {'category': category, 'amount': amount};

  factory BudgetLimit.fromJson(Map<String, dynamic> json) => BudgetLimit(
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class SpendCategories {
  static const income = <String>[
    'Salary',
    'Freelance',
    'Business',
    'Gifts',
    'Other',
  ];

  static const expense = <String>[
    'Food',
    'Groceries',
    'Transport',
    'Shopping',
    'Bills',
    'Education',
    'Health',
    'Entertainment',
    'Other',
  ];
}
