import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FinancialReportPage extends StatefulWidget {
  final String userId;
  final String turfId;

  const FinancialReportPage({
    Key? key,
    required this.userId,
    required this.turfId,
  }) : super(key: key);

  @override
  _FinancialReportPageState createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  double _totalIncome = 0;
  double _monthlyIncome = 0;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  List<String> _months =
      List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)));
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _monthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    try {
      setState(() => _isLoading = true);
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('turfId', isEqualTo: widget.turfId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      double totalRevenue = 0;
      double selectedMonthIncome = 0;

      // Initialize monthly revenue map
      Map<String, double> monthlyData = {};
      for (String month in _months) {
        monthlyData[month] = 0;
      }

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num).toDouble();
        final date = (data['createdAt'] as Timestamp).toDate();
        final month = DateFormat('MMMM').format(date);

        monthlyData[month] = (monthlyData[month] ?? 0) + amount;
        totalRevenue += amount;
        if (DateFormat('MMMM').format(date) == _selectedMonth) {
          selectedMonthIncome += amount;
        }
      }

      setState(() {
        _totalIncome = totalRevenue;
        _monthlyIncome = selectedMonthIncome;
        _transactions = bookingsSnapshot.docs.map((doc) => doc.data()).toList();
        _monthlyRevenue = monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading financial data: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRevenueCard(
      String title, String amount, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
                SizedBox(height: 5),
                Text(
                  '₹$amount',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            Icon(icon, size: 40, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: Icon(Icons.payment, color: Colors.blue),
            title: Text('₹${transaction['totalAmount']}'),
            subtitle: Text(DateFormat('MMM d, yyyy')
                .format(transaction['createdAt'].toDate())),
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _monthlyRevenue.values.isEmpty
              ? 100
              : _monthlyRevenue.values.reduce((a, b) => a > b ? a : b) * 1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= _months.length)
                    return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _months[value.toInt()].substring(0, 3),
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('₹${value.toInt()}',
                      style: TextStyle(fontSize: 12));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_months.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _monthlyRevenue[_months[index]] ?? 0,
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Report'),
        backgroundColor: Colors.blue,
        actions: [
          DropdownButton<String>(
            value: _selectedMonth,
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.blue,
            onChanged: (String? newValue) {
              setState(() {
                _selectedMonth = newValue!;
                _loadFinancialData();
              });
            },
            items: _months.map((String month) {
              return DropdownMenuItem<String>(
                value: month,
                child: Text(
                  month,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueCard(
                      'Total Revenue',
                      _totalIncome.toStringAsFixed(2),
                      Icons.account_balance_wallet,
                      Colors.green),
                  _buildRevenueCard(
                      '$_selectedMonth Income',
                      _monthlyIncome.toStringAsFixed(2),
                      Icons.calendar_today,
                      Colors.blue),
                  SizedBox(height: 24),
                  Text(
                    'Monthly Revenue Distribution',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildRevenueChart(),
                  SizedBox(height: 24),
                  Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  _buildTransactionsList(),
                ],
              ),
            ),
    );
  }
}
