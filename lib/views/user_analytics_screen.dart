import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:coding_tutor/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeToday = 0;
  int _activeThisWeek = 0;
  int _newUsersToday = 0;
  double _totalRevenue = 0.0;
  int _totalPurchases = 0;

  @override
  void initState() {
    super.initState();
    _fetchAdminAnalytics();
  }

  Future<void> _fetchAdminAnalytics() async {
    try {
      // Get all users
      final usersQuery = await _firestore.collection('users').get();
      _totalUsers = usersQuery.size;

      // Get today's date
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final weekAgo = today.subtract(const Duration(days: 7));

      // Calculate active users
      int todayCount = 0;
      int weekCount = 0;
      int newTodayCount = 0;

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final lastLogin = data['lastLogin'];

        if (lastLogin != null) {
          final lastLoginTime = (lastLogin as Timestamp).toDate();

          // Active today
          if (lastLoginTime.isAfter(startOfDay)) {
            todayCount++;
          }

          // Active this week
          if (lastLoginTime.isAfter(weekAgo)) {
            weekCount++;
          }
        }

        // New users today
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          final createdTime = (createdAt as Timestamp).toDate();
          if (createdTime.isAfter(startOfDay)) {
            newTodayCount++;
          }
        }
      }

      // Get purchases data
      final purchasesQuery = await _firestore
          .collection('purchases')
          .where('status', isEqualTo: 'completed')
          .get();

      double revenue = 0.0;
      for (final doc in purchasesQuery.docs) {
        final data = doc.data();
        final amount = data['amount'] ?? 0.0;
        revenue += amount;
      }

      setState(() {
        _activeToday = todayCount;
        _activeThisWeek = weekCount;
        _newUsersToday = newTodayCount;
        _totalRevenue = revenue;
        _totalPurchases = purchasesQuery.size;
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching admin analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Growth',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGrowthItem('Today', '$_newUsersToday', Colors.green),
              _buildGrowthItem('7 Days', '${(_newUsersToday * 7).toStringAsFixed(0)}', Colors.blue),
              _buildGrowthItem('30 Days', '${(_newUsersToday * 30).toStringAsFixed(0)}', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthItem(String period, String value, Color color) {
    return Column(
      children: [
        Text(
          period,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Purchases',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalPurchases',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_totalUsers > 0) ? (_activeThisWeek / _totalUsers) : 0,
            backgroundColor: Colors.grey[200],
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '${((_activeThisWeek / _totalUsers) * 100).toStringAsFixed(1)}% active users this week',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildDistributionItem('Active Today', _activeToday, _totalUsers, Colors.green),
          _buildDistributionItem('Active This Week', _activeThisWeek, _totalUsers, Colors.blue),
          _buildDistributionItem('Total Users', _totalUsers, _totalUsers, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: Colors.grey[200],
            color: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is admin (you can implement your own admin check)
    final isAdmin = authProvider.userModel?.email?.endsWith('@admin.com') ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Admin access required',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAdminAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  title: 'Total Users',
                  value: '$_totalUsers',
                  icon: Icons.people,
                  color: Colors.blue,
                  subtitle: 'All Time',
                ),
                _buildStatCard(
                  title: 'Active Today',
                  value: '$_activeToday',
                  icon: Icons.today,
                  color: Colors.green,
                  subtitle: '24 Hours',
                ),
                _buildStatCard(
                  title: 'New Users',
                  value: '$_newUsersToday',
                  icon: Icons.person_add,
                  color: Colors.purple,
                  subtitle: 'Today',
                ),
                _buildStatCard(
                  title: 'Active Week',
                  value: '$_activeThisWeek',
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                  subtitle: '7 Days',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // User Growth
            _buildUserGrowthChart(),

            const SizedBox(height: 20),

            // Revenue Section
            _buildRevenueSection(),

            const SizedBox(height: 20),

            // User Distribution
            _buildUserDistribution(),

            const SizedBox(height: 20),

            // Quick Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.download, 'Export Data', Colors.blue),
                      _buildActionButton(Icons.notifications, 'Send Alert', Colors.orange),
                      _buildActionButton(Icons.settings, 'Settings', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}