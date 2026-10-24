// Người phụ trách: Khôi - lịch sử vé
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_poster.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vé của tôi'),
          bottom: TabBar(
            dividerColor: Colors.white10,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Sắp chiếu (${provider.upcoming.length})'),
              Tab(text: 'Đã xem (${provider.watched.length})'),
            ],
          ),
        ),
        body: provider.isLoading && provider.tickets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _TicketList(
                    tickets: provider.upcoming,
                    emptyText: 'Bạn chưa có vé nào sắp chiếu',
                  ),
                  _TicketList(
                    tickets: provider.watched,
                    emptyText: 'Chưa có vé nào đã xem',
                  ),
                ],
              ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets, required this.emptyText});

  final List<Ticket> tickets;
  final String emptyText;

  Future<void> _refresh(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<TicketProvider>().loadTickets(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: tickets.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                const Icon(
                  Icons.local_activity_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 12),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _TicketTile(ticket: tickets[i]),
            ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final s = ticket.showtime;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 92,
                child: MoviePoster(movie: ticket.movie, emojiSize: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TicketStatusChip(upcoming: ticket.isUpcoming),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _IconLine(Icons.location_on_outlined, s.cinema.name),
                  _IconLine(
                    Icons.schedule,
                    '${formatTime(s.startTime)} • ${formatDate(s.startTime)}',
                  ),
                  _IconLine(Icons.event_seat_outlined, 'Ghế ${ticket.seatLabel}'),
                  const SizedBox(height: 4),
                  Text(
                    'Mã vé: ${ticket.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
