import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/ticket.dart';
import '../models/user.dart'; // 🔥 TAMBAHKAN INI
import '../services/auth_service.dart';

class TicketListScreen extends StatefulWidget {
  @override
  _TicketListScreenState createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Ticket> _allTickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

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

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final tickets = await api.getTickets();

      List<Ticket> filteredTickets = tickets;
      final user = _currentUser;

      if (user != null && user.role == 'user') {
        filteredTickets = tickets.where((t) => t.createdBy == user.id).toList();
      }

      setState(() {
        _allTickets = filteredTickets;
        _filteredTickets = filteredTickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat tiket: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _filterTickets() {
    String query = _searchController.text.toLowerCase().trim();
    List<Ticket> filtered = [..._allTickets];

    if (_selectedFilter != 'all') {
      filtered = filtered.where((t) => t.status == _selectedFilter).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.title.toLowerCase().contains(query) ||
        t.description.toLowerCase().contains(query) ||
        t.category.toLowerCase().contains(query)
      ).toList();
    }

    setState(() {
      _filteredTickets = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Semua Tiket',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTickets,
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _filterTickets(),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari tiket...',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterTickets();
                        },
                      ),
                  ],
                ),
              ),
              Container(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('Semua', 'all'),
                    _buildFilterChip('Open', 'open'),
                    _buildFilterChip('Assigned', 'assigned'),
                    _buildFilterChip('In Progress', 'inprogress'),
                    _buildFilterChip('Closed', 'closed'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              _isLoading
                  ? Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : _filteredTickets.isEmpty
                      ? _buildEmptyState()
                      : Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 80),
                            itemCount: _filteredTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = _filteredTickets[index];
                              return _buildTicketItem(ticket);
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.40),
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
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isActive = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _filterTickets();
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.30),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(Ticket ticket) {
    final statusMap = {
      'open': 'Open',
      'assigned': 'Assigned',
      'inprogress': 'In Progress',
      'closed': 'Closed'
    };
    final priorityMap = {
      'high': 'Tinggi',
      'medium': 'Sedang',
      'low': 'Rendah'
    };
    Color statusColor;
    Color statusBg;
    Color priorityColor;
    Color priorityBg;

    switch (ticket.status) {
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
      case 'closed':
        statusColor = Color(0xFF059669);
        statusBg = Color(0xFFD1FAE5);
        break;
      default:
        statusColor = Color(0xFF94A3B8);
        statusBg = Color(0xFFF1F5F9);
    }

    switch (ticket.priority) {
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFFDDD6FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  ticket.createdByUser?.name?.isNotEmpty == true
                      ? ticket.createdByUser!.name[0].toUpperCase()
                      : '?',
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.30),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada tiket',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah filter atau cari dengan kata kunci lain.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 'Beranda', 0, currentIndex == 0,
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard')),
          _buildNavItem(context, Icons.list_alt, 'Tiket', 1, currentIndex == 1,
              onTap: () {}),
          _buildNavItem(context, Icons.notifications, 'Notif', 2, currentIndex == 2,
              onTap: () => Navigator.pushReplacementNamed(context, '/notifications')),
          _buildNavItem(context, Icons.person, 'Profil', 3, currentIndex == 3,
              onTap: () => Navigator.pushReplacementNamed(context, '/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, bool isActive,
      {VoidCallback? onTap}) {
    final color = isActive
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodySmall?.color;
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
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
}