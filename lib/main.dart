import 'package:flutter/material.dart';

void main() {
  runApp(const GoldAccountingApp());
}

class Transaction {
  final String type;
  final String date;
  final double weight;
  final String id;

  Transaction({
    required this.type,
    required this.date,
    required this.weight,
    required this.id,
  });
}

class GoldAccountingApp extends StatefulWidget {
  const GoldAccountingApp({super.key});

  @override
  State<GoldAccountingApp> createState() => _GoldAccountingAppState();
}

class _GoldAccountingAppState extends State<GoldAccountingApp> {
  List<Transaction> transactions = [];
  TextEditingController dateController = TextEditingController(text: '1403/04/01');
  TextEditingController weightController = TextEditingController(text: '10.0');
  TextEditingController profitController = TextEditingController(text: '1.0');
  TextEditingController endDateController = TextEditingController(text: '1403/12/29');

  double currentBalance = 0.0;
  double totalInterest = 0.0;
  double totalWeight = 0.0;
  List<String> calculationDetails = [];

  @override
  void initState() {
    super.initState();
    _updateBalance();
  }

  void _updateBalance() {
    double balance = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == 'buy') {
        balance += transaction.weight;
      } else if (transaction.type == 'sell') {
        balance -= transaction.weight;
      }
    }
    setState(() {
      currentBalance = balance;
    });
  }

  bool _isValidJalaliDate(String dateStr) {
    List<String> parts = dateStr.split('/');
    if (parts.length != 3) return false;
    
    try {
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int day = int.parse(parts[2]);
      
      if (year < 1300 || year > 1500) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  int _daysBetweenJalali(String date1, String date2) {
    List<String> parts1 = date1.split('/');
    List<String> parts2 = date2.split('/');
    
    int year1 = int.parse(parts1[0]);
    int year2 = int.parse(parts2[0]);
    int month1 = int.parse(parts1[1]);
    int month2 = int.parse(parts2[1]);
    int day1 = int.parse(parts1[2]);
    int day2 = int.parse(parts2[2]);
    
    int totalDays1 = year1 * 365 + month1 * 30 + day1;
    int totalDays2 = year2 * 365 + month2 * 30 + day2;
    
    return (totalDays2 - totalDays1).clamp(0, 10000);
  }

  void _addTransaction(String type) {
    String dateStr = dateController.text.trim();
    String weightStr = weightController.text.trim();

    if (dateStr.isEmpty || weightStr.isEmpty) {
      _showMessage('لطفا تاریخ و وزن را وارد کنید');
      return;
    }

    if (!_isValidJalaliDate(dateStr)) {
      _showMessage('تاریخ نامعتبر است');
      return;
    }

    double weight = double.tryParse(weightStr) ?? 0;
    if (weight <= 0) {
      _showMessage('وزن باید عددی مثبت باشد');
      return;
    }

    if (type == 'sell' && weight > currentBalance) {
      _showMessage('موجودی کافی نیست!');
      return;
    }

    setState(() {
      transactions.add(Transaction(
        type: type,
        date: dateStr,
        weight: weight,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
      
      transactions.sort((a, b) => a.date.compareTo(b.date));
    });

    _updateBalance();
    _clearInputs();
  }

  void _clearInputs() {
    weightController.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _removeTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تراکنش'),
        content: const Text('آیا از حذف این تراکنش مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                transactions.removeAt(index);
                _updateBalance();
              });
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    if (transactions.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن همه'),
        content: const Text('آیا از پاک کردن همه تراکنش‌ها مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                transactions.clear();
                _updateBalance();
                calculationDetails.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );
  }

  void _calculateDetailed() {
    if (transactions.isEmpty) {
      _showMessage('هیچ تراکنشی ثبت نشده است');
      return;
    }

    String endDateStr = endDateController.text.trim();
    if (!_isValidJalaliDate(endDateStr)) {
      _showMessage('تاریخ پایان نامعتبر است');
      return;
    }

    double monthlyProfit = (double.tryParse(profitController.text) ?? 0) / 100;

    List<Transaction> sortedTransactions = List.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    double currentWeight = 0.0;
    double totalInterest = 0.0;
    String lastDate = sortedTransactions.first.date;
    List<String> details = [];
    int periodNumber = 1;

    for (int i = 0; i < sortedTransactions.length; i++) {
      Transaction transaction = sortedTransactions[i];
      String nextDate = (i < sortedTransactions.length - 1) 
          ? sortedTransactions[i + 1].date 
          : endDateStr;
      
      int days = _daysBetweenJalali(lastDate, transaction.date);
      if (days > 0 && currentWeight > 0) {
        double interest = currentWeight * (monthlyProfit / 30) * days;
        totalInterest += interest;
        
        details.add('دوره $periodNumber: $lastDate تا ${transaction.date}');
        details.add('  مدت: $days روز | وزن: ${currentWeight.toStringAsFixed(4)} گرم | سود: ${interest.toStringAsFixed(4)} گرم');
        periodNumber++;
      }

      String transactionType = transaction.type == 'buy' ? 'خرید' : 'فروش';
      details.add('$transactionType: ${transaction.weight.toStringAsFixed(4)} گرم در ${transaction.date}');

      if (transaction.type == 'buy') {
        currentWeight += transaction.weight;
      } else {
        currentWeight -= transaction.weight;
      }

      lastDate = transaction.date;
    }

    int finalDays = _daysBetweenJalali(lastDate, endDateStr);
    if (finalDays > 0 && currentWeight > 0) {
      double finalInterest = currentWeight * (monthlyProfit / 30) * finalDays;
      totalInterest += finalInterest;
      
      details.add('دوره $periodNumber: $lastDate تا $endDateStr');
      details.add('  مدت: $finalDays روز | وزن: ${currentWeight.toStringAsFixed(4)} گرم | سود: ${finalInterest.toStringAsFixed(4)} گرم');
    }

    setState(() {
      this.totalWeight = currentWeight;
      this.totalInterest = totalInterest;
      this.calculationDetails = details;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حسابداری طلا',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_money, color: Colors.yellow),
              SizedBox(width: 8),
              Text('حسابداری طلا'),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFf9f7f0), Color(0xFFfff8e1)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCurrentBalance(),
                  const SizedBox(height: 20),
                  _buildTransactionForm(),
                  const SizedBox(height: 20),
                  _buildTransactionList(),
                  const SizedBox(height: 20),
                  _buildCalculationSettings(),
                  const SizedBox(height: 20),
                  _buildCalculateButton(),
                  const SizedBox(height: 20),
                  if (calculationDetails.isNotEmpty) _buildResults(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalance() {
    Color bgColor = currentBalance > 0 
        ? Colors.green.shade50 
        : currentBalance < 0 
          ? Colors.red.shade50 
          : Colors.blue.shade50;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'موجودی فعلی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${currentBalance.toStringAsFixed(4)} گرم',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'ثبت تراکنش جدید',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'تاریخ (شمسی)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'وزن (گرم)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTransaction('buy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('خرید'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addTransaction('sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('فروش'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تراکنش‌ها:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              const Center(
                child: Text(
                  'تراکنشی وجود ندارد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    Transaction transaction = transactions[index];
                    bool isBuy = transaction.type == 'buy';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isBuy ? Icons.add : Icons.remove,
                          color: isBuy ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          '${isBuy ? 'خرید' : 'فروش'}: ${transaction.weight.toStringAsFixed(4)} گرم',
                          style: TextStyle(
                            color: isBuy ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(transaction.date),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _removeTransaction(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: profitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'نرخ سود ماهانه (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(
                labelText: 'تاریخ پایان (شمسی)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calculateDetailed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.calculate),
        label: const Text(
          'محاسبه سود با جزئیات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'نتیجه محاسبه',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  const Text(
                    'موجودی طلا (اصل سرمایه)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${totalWeight.toStringAsFixed(4)} گرم',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'سرمایه اصلی بدون سود',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Text(
                    'سود انباشته',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${totalInterest.toStringAsFixed(4)} گرم',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${profitController.text}% سود ماهانه',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'جمع کل (اصل + سود)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(totalWeight + totalInterest).toStringAsFixed(4)} گرم',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'برای مقایسه و اطلاعات بیشتر',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'ریز محاسبات دوره‌ها:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...calculationDetails.map((detail) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  detail,
                  style: TextStyle(
                    color: detail.contains('خرید') ? Colors.green :
                           detail.contains('فروش') ? Colors.red :
                           detail.contains('سود:') ? Colors.blue :
                           Colors.black,
                    fontSize: detail.startsWith('  ') ? 12 : 14,
                  ),
                ),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }
}
