import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const LoanCalculatorScreen(),
    );
  }
}

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  _LoanCalculatorScreenState createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _loanTermController = TextEditingController();
  final TextEditingController _extraPaymentController = TextEditingController();

  double _monthlyPayment = 0.0;
  double _totalPayment = 0.0;
  double _totalInterest = 0.0;
  List<Map<String, dynamic>> _amortizationSchedule = [];

  bool _showSchedule = false;
  bool _showResults = false;

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    _extraPaymentController.dispose();
    super.dispose();
  }

  void _calculateLoan() {
    if (_formKey.currentState!.validate()) {
      final double loanAmount = double.parse(_loanAmountController.text);
      final double interestRate = double.parse(_interestRateController.text);
      final int loanTerm = int.parse(_loanTermController.text);
      final double extraPayment =
          double.tryParse(_extraPaymentController.text) ?? 0.0;

      final double monthlyInterestRate = interestRate / 100 / 12;
      final int totalPayments = loanTerm * 12;

      // Calculate monthly payment
      _monthlyPayment =
          (loanAmount *
              monthlyInterestRate *
              (pow(1 + monthlyInterestRate, totalPayments))) /
          ((pow(1 + monthlyInterestRate, totalPayments)) - 1);

      // Calculate total payment and total interest
      _totalPayment = _monthlyPayment * totalPayments;
      _totalInterest = _totalPayment - loanAmount;

      // Generate amortization schedule
      _generateAmortizationSchedule(
        loanAmount,
        monthlyInterestRate,
        totalPayments,
        _monthlyPayment,
        extraPayment,
      );

      setState(() {
        _showResults = true;
      });
    }
  }

  void _generateAmortizationSchedule(
    double loanAmount,
    double monthlyInterestRate,
    int totalPayments,
    double monthlyPayment,
    double extraPayment,
  ) {
    _amortizationSchedule = [];
    double balance = loanAmount;
    double totalExtraPayments = 0;

    for (int i = 1; i <= totalPayments; i++) {
      if (balance <= 0) break;

      double interest = balance * monthlyInterestRate;
      double principal = monthlyPayment - interest;
      double payment = monthlyPayment;

      // Apply extra payment if available
      if (extraPayment > 0) {
        principal += extraPayment;
        payment += extraPayment;
        totalExtraPayments += extraPayment;
      }

      // Ensure we don't overpay in the last payment
      if (principal > balance) {
        principal = balance;
        payment = principal + interest;
      }

      balance -= principal;

      _amortizationSchedule.add({
        'month': i,
        'payment': payment,
        'principal': principal,
        'interest': interest,
        'balance': balance > 0 ? balance : 0,
      });
    }

    // Update totals with extra payments
    if (extraPayment > 0) {
      _totalPayment = (monthlyPayment * totalPayments) + totalExtraPayments;
    }
  }

  void _resetCalculator() {
    _formKey.currentState?.reset();
    _loanAmountController.clear();
    _interestRateController.clear();
    _loanTermController.clear();
    _extraPaymentController.clear();

    setState(() {
      _monthlyPayment = 0.0;
      _totalPayment = 0.0;
      _totalInterest = 0.0;
      _amortizationSchedule = [];
      _showResults = false;
      _showSchedule = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCalculator,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 20),
              if (_showResults) _buildResultsCard(),
              if (_showSchedule) _buildAmortizationSchedule(),
              const SizedBox(height: 20),
              if (_showResults && !_showSchedule)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSchedule = true;
                    });
                  },
                  child: const Text('View Amortization Schedule'),
                ),
              if (_showSchedule)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSchedule = false;
                    });
                  },
                  child: const Text('Hide Amortization Schedule'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _loanAmountController,
              decoration: const InputDecoration(
                labelText: 'Loan Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter interest rate';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loanTermController,
              decoration: const InputDecoration(
                labelText: 'Loan Term (years)',
                suffixText: 'years',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan term';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _extraPaymentController,
              decoration: const InputDecoration(
                labelText: 'Extra Monthly Payment (optional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateLoan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Calculate', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Loan Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildResultRow('Monthly Payment', _monthlyPayment),
            _buildResultRow('Total Payment', _totalPayment),
            _buildResultRow('Total Interest', _totalInterest),
            _buildResultRow(
              'Payoff Time',
              _amortizationSchedule.length / 12,
              isYears: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double value, {bool isYears = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            isYears
                ? '${value.toStringAsFixed(1)} years'
                : '\$${value.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortizationSchedule() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Amortization Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Payment')),
                    DataColumn(label: Text('Principal')),
                    DataColumn(label: Text('Interest')),
                    DataColumn(label: Text('Balance')),
                  ],
                  rows:
                      _amortizationSchedule.take(60).map((payment) {
                        return DataRow(
                          cells: [
                            DataCell(Text(payment['month'].toString())),
                            DataCell(
                              Text(
                                '\$${payment['payment'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${payment['principal'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${payment['interest'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$${payment['balance'].toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
