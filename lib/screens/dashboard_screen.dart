import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';
import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ========== 🔥 INITIALIZE SEQUENTIALLY (LOAD USER DULU) ==========
  Future<void> _initialize() async {
    await _loadUser();
    await _fetchTickets();
  }

  Future<void> _loadUser() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.getUser();
    setState(() {
      _currentUser = user;
    });
  }

  // ========== 🔥 FETCH TICKETS DENGAN FILTER ROLE ==========
  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final allTickets = await api.getTickets();

      // Filter berdasarkan role
      List<Ticket> filteredTickets = allTickets;
      final user = _currentUser;

      if (user != null && user.role == 'user') {
        // User hanya lihat tiket yang dia buat
        filteredTickets = allTickets.where((t) => t.createdBy == user.id).toList();
      }
      // Admin & Helpdesk lihat semua

      setState(() {
        _tickets = filteredTickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data tiket: $e')),
      );
    }
  }

  // ========== 🔥 PERBAIKAN DI SINI ==========
  String _getDate() {
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
            stops: [0.0, 0.6],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'E-Ticketing',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.person_outline, color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _fetchTickets,
                  color: Color(0xFF4F46E5),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.titleLarge?.color ?? Color(0xFF0F172A),
                                ),
                                children: [
                                  TextSpan(text: 'Halo, '),
                                  TextSpan(
                                    text: _currentUser?.name ?? 'Pengguna',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  TextSpan(text: ' 👋'),
                                ],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _getDate(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildStatsGrid(context),
                        _buildClosedCard(context),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/create-ticket');
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF4F46E5).withOpacity(0.30),
                                        blurRadius: 20,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Buat Tiket',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/tickets');
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Color(0xFF4F46E5), width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.list, color: Color(0xFF4F46E5), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Lihat Semua',
                                        style: GoogleFonts.inter(
                                          color: Color(0xFF4F46E5),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiket Terbaru',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleLarge?.color ?? Color(0xFF0F172A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/tickets');
                              },
                              child: Text(
                                'Lihat semua',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _isLoading
                            ? Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                            : _tickets.isEmpty
                                ? _buildEmptyState(context)
                                : Column(
                                    children: _tickets.take(3).map((ticket) {
                                      return _buildTicketItem(context, ticket);
                                    }).toList(),
                                  ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4F46E5).withOpacity(0.50),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create-ticket');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200.withOpacity(0.1),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home, 'Beranda', 0, true),
            _buildNavItem(context, Icons.list_alt, 'Tiket', 1, false, badge: _tickets.where((t) => t.status == 'open' || t.status == 'assigned').length),
            _buildNavItem(context, Icons.notifications, 'Notif', 2, false, badge: 2),
            _buildNavItem(context, Icons.person, 'Profil', 3, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, bool isActive, {int? badge}) {
    final theme = Theme.of(context);
    final color = isActive ? Color(0xFF4F46E5) : theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Color(0xFF94A3B8);
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/tickets');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/notifications');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEF4444).withOpacity(0.40),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final total = _tickets.length;
    final open = _tickets.where((t) => t.status == 'open').length;
    final assigned = _tickets.where((t) => t.status == 'assigned').length;
    final inProgress = _tickets.where((t) => t.status == 'inprogress').length;

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _statCard(context, 'Total Tiket', total, 'blue', Icons.assignment),
        _statCard(context, 'Open', open, 'amber', Icons.inbox),
        _statCard(context, 'Assigned', assigned, 'purple', Icons.person_add),
        _statCard(context, 'In Progress', inProgress, 'green', Icons.timelapse),
      ],
    );
  }

  Widget _buildClosedCard(BuildContext context) {
    final closed = _tickets.where((t) => t.status == 'closed' || t.status == 'resolved').length;
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$closed',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color ?? Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Closed',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Color(0xFF94A3B8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int count, String colorType, IconData icon) {
    final theme = Theme.of(context);
    Map<String, Color> colors = {
      'blue': Color(0xFF4F46E5),
      'amber': Color(0xFFF59E0B),
      'purple': Color(0xFF7C3AED),
      'green': Color(0xFF10B981),
    };
    Map<String, Color> lightColors = {
      'blue': Color(0xFF818CF8),
      'amber': Color(0xFFFCD34D),
      'purple': Color(0xFFA78BFA),
      'green': Color(0xFF6EE7B7),
    };

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors[colorType]!, lightColors[colorType]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(height: 10),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color ?? Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, Ticket ticket) {
    final theme = Theme.of(context);
    final user = _currentUser;
    final initial = user?.name?.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : '?';
    final statusMap = {
      'open': 'Open',
      'assigned': 'Assigned',
      'inprogress': 'In Progress',
      'resolved': 'Resolved',
      'closed': 'Closed'
    };
    final priorityMap = {
      'high': 'Tinggi',
      'medium': 'Sedang',
      'low': 'Rendah'
    };
    final statusClass = ticket.status;
    final priorityClass = ticket.priority;
    Color statusColor;
    Color statusBg;
    Color priorityColor;
    Color priorityBg;

    switch (statusClass) {
      case 'open':
        statusColor = Color(0xFF2563EB);
        statusBg = Color(0xFFDBEAFE);
        break;
      case 'assigned':
        statusColor = Color(0xFFD97706);
        statusBg = Color(0xFFFEF3C7);
        break;
      case 'inprogress':
        statusColor = Color(0xFF7C3AED);
        statusBg = Color(0xFFEDE9FE);
        break;
      case 'resolved':
      case 'closed':
        statusColor = Color(0xFF059669);
        statusBg = Color(0xFFD1FAE5);
        break;
      default:
        statusColor = Color(0xFF94A3B8);
        statusBg = Color(0xFFF1F5F9);
    }

    switch (priorityClass) {
      case 'high':
        priorityColor = Color(0xFFDC2626);
        priorityBg = Color(0xFFFEE2E2);
        break;
      case 'medium':
        priorityColor = Color(0xFFD97706);
        priorityBg = Color(0xFFFEF3C7);
        break;
      case 'low':
        priorityColor = Color(0xFF2563EB);
        priorityBg = Color(0xFFDBEAFE);
        break;
      default:
        priorityColor = Color(0xFF94A3B8);
        priorityBg = Color(0xFFF1F5F9);
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFDDD6FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color ?? Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        ticket.category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          priorityMap[ticket.priority] ?? ticket.priority,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusMap[ticket.status] ?? ticket.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 72,
            color: theme.disabledColor.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada tiket',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color ?? Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tiket yang Anda buat akan muncul di sini.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color ?? Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}