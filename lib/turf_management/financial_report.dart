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
  Map<String, double> _monthlyRevenue = {};
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  List<String> _months =
      List.generate(12, (i) => DateFormat('MMMM').format(DateTime(0, i + 1)));
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    for (String month in _months) {
      _monthlyRevenue[month] = 0;
    }
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    try {
      setState(() => _isLoading = true);

      // Get current year for date filtering
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31);

      // Query bookings for specific turf
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('turfId', isEqualTo: widget.turfId)
          .where('status', whereIn: [
        'confirmed',
        'completed'
      ]) // Include both confirmed and completed bookings
          .get();

      print(
          'Found ${bookingsQuery.docs.length} bookings for turf ${widget.turfId}');

      double totalRevenue = 0;
      double monthlyRevenue = 0;
      Map<String, double> monthlyData = {};
      List<Map<String, dynamic>> transactions = [];

      // Initialize monthly data
      for (String month in _months) {
        monthlyData[month] = 0;
      }

      // Process each booking
      for (var doc in bookingsQuery.docs) {
        final booking = doc.data();
        final amount = (booking['totalAmount'] as num).toDouble();
        final date = (booking['date'] as Timestamp).toDate();

        // Only include bookings from current year
        if (date.year == now.year) {
          final bookingMonth = DateFormat('MMMM').format(date);

          // Add to total revenue
          totalRevenue += amount;

          // Add to monthly data
          monthlyData[bookingMonth] = (monthlyData[bookingMonth] ?? 0) + amount;

          // Add to selected month revenue
          if (bookingMonth == _selectedMonth) {
            monthlyRevenue += amount;
          }

          // Add to transactions list
          transactions.add({
            ...booking,
            'id': doc.id,
            'date': date,
            'formattedDate': DateFormat('MMM d, yyyy').format(date),
            'amount': amount,
            'sport': booking['sport'] ?? 'Not specified',
            'box': booking['box'] ?? 'Not specified',
            'userName': booking['userName'] ?? 'Unknown User',
            'userPhone': booking['userPhone'],
            'timeSlots': booking['timeSlots'] ?? [],
            'status': booking['status'],
          });
        }
      }

      setState(() {
        _totalIncome = totalRevenue;
        _monthlyIncome = monthlyRevenue;
        _monthlyRevenue = monthlyData;
        _transactions = transactions;
        _isLoading = false;
      });

      print('Total Revenue: $_totalIncome');
      print('Monthly Revenue for $_selectedMonth: $_monthlyIncome');
    } catch (e) {
      print('Error loading financial data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading financial data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions found for this period',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['userName'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        transaction['userPhone'] ?? 'No phone',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${transaction['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      transaction['formattedDate'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (transaction['timeSlots'] as List).join(', '),
                        style: TextStyle(color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      transaction['sport'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.grid_view, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      transaction['box'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Revenue Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _monthlyRevenue.values.isEmpty
                    ? 100
                    : _monthlyRevenue.values.reduce((a, b) => a > b ? a : b) *
                        1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}\n${_months[group.x.toInt()]}',
                        TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= _months.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _months[value.toInt()].substring(0, 3),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      1000, // Adjust based on your revenue range
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(_months.length, (index) {
                  final revenue = _monthlyRevenue[_months[index]] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: _months[index] == _selectedMonth
                            ? Colors.green
                            : Colors.blue,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Report'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedMonth,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.green,
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMonth = newValue;
                    _loadFinancialData();
                  });
                }
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
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinancialData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildRevenueCard(
                            'Total Revenue',
                            _totalIncome.toStringAsFixed(2),
                            Icons.account_balance_wallet,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildRevenueCard(
                            '$_selectedMonth Revenue',
                            _monthlyIncome.toStringAsFixed(2),
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildRevenueChart(),
                    SizedBox(height: 24),
                    Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTransactionsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueCard(
      String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '₹$amount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(icon, size: 40, color: color),
          ],
        ),
      ),
    );
  }
}
