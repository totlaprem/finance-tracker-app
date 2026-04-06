import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String selectedType = "Expense";

  List<Map<String, dynamic>> transactions = [];
  Future<void> saveData() async {
  final prefs = await SharedPreferences.getInstance();
  final String encodedData = jsonEncode(transactions);
  await prefs.setString('transactions', encodedData);
}

Future<void> loadData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? data = prefs.getString('transactions');

  if (data != null) {
    setState(() {
      transactions = List<Map<String, dynamic>>.from(
        jsonDecode(data),
      );
    });
  }
}
@override
void initState() {
  super.initState();
  loadData();
}

  void addTransaction() {
    final title = titleController.text;
    final amount = double.tryParse(amountController.text);

    if (title.isEmpty || amount == null) return;

    setState(() {
      transactions.add({
        'title': title,
        'amount': amount,
        'type': selectedType,
      });
    });

    titleController.clear();
    amountController.clear();
  }

  void deleteTransaction(int index) {
  setState(() {
    transactions.removeAt(index);
  });
  saveData();
}
  void editTransaction(int index) {
    final tx = transactions[index];

    // fill inputs
    titleController.text = tx['title'];
    amountController.text = tx['amount'].toString();
    selectedType = tx['type'];

    // remove old item
    setState(() {
      transactions.removeAt(index);
    });

    saveData();
  }

  // 🔥 TOTAL BALANCE
  double get totalBalance {
    return transactions.fold(0, (sum, item) {
      if (item['type'] == "Income") {
        return sum + item['amount'];
      } else {
        return sum - item['amount'];
      }
    });
  }

  // 🔥 TOTAL INCOME
  double get totalIncome {
    return transactions
        .where((tx) => tx['type'] == "Income")
        .fold(0, (sum, item) => sum + item['amount']);
  }

  // 🔥 TOTAL EXPENSE
  double get totalExpense {
    return transactions
        .where((tx) => tx['type'] == "Expense")
        .fold(0, (sum, item) => sum + item['amount']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finance Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 💰 BALANCE
            Text(
              "Balance: ₹${totalBalance.toStringAsFixed(0)}",
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // 📊 PIE CHART (ADDED HERE)
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: totalIncome == 0 ? 1 : totalIncome,
                      color: Colors.green,
                      radius: 60,
                      title:
                          "Income\n₹${totalIncome.toStringAsFixed(0)}",
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: totalExpense == 0 ? 1 : totalExpense,
                      color: Colors.red,
                      radius: 60,
                      title:
                          "Expense\n₹${totalExpense.toStringAsFixed(0)}",
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📝 INPUT FIELDS
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 10),

            // 🔽 DROPDOWN
            DropdownButton<String>(
              value: selectedType,
              items: ["Income", "Expense"].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            ElevatedButton(
              onPressed: addTransaction,
              child: const Text("Add Transaction"),
            ),

            const SizedBox(height: 20),

            // 📋 LIST
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isIncome = tx['type'] == "Income";

                  return Card(
                    child: ListTile(
                      title: Text(tx['title']),
                      subtitle: Text(tx['type']),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                            children: [
                            // 💰 AMOUNT
                            Text(
                              "₹${tx['amount']}",
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ✏️ EDIT BUTTON
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              editTransaction(index);
                            },
                          ),

                          // ❌ DELETE BUTTON
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteTransaction(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}