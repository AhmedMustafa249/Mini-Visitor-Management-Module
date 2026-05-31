import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/visitor_cubit.dart';
import '../cubit/visitor_state.dart';
import '../data/visitor.dart';
import '../data/visitor_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../core/router/app_router.dart';

class VisitorListScreen extends StatelessWidget {
  const VisitorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthCubit>().currentUser!.token;
    return BlocProvider(
      create: (_) => VisitorCubit(repository: VisitorRepository(token: token))
        ..loadVisitors(),
      child: const _VisitorListView(),
    );
  }
}

enum _DateGroup { today, tomorrow, thisWeek, upcoming, past }

class _VisitorListView extends StatelessWidget {
  const _VisitorListView();

  _DateGroup _groupFor(DateTime visitDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visit = DateTime(visitDate.year, visitDate.month, visitDate.day);
    final diff = visit.difference(today).inDays;

    if (diff < 0) return _DateGroup.past;
    if (diff == 0) return _DateGroup.today;
    if (diff == 1) return _DateGroup.tomorrow;
    if (diff <= 6) return _DateGroup.thisWeek;
    return _DateGroup.upcoming;
  }

  String _groupLabel(_DateGroup group) {
    return switch (group) {
      _DateGroup.today => 'Today',
      _DateGroup.tomorrow => 'Tomorrow',
      _DateGroup.thisWeek => 'This Week',
      _DateGroup.upcoming => 'Upcoming',
      _DateGroup.past => 'Past',
    };
  }

  List<(_DateGroup, List<Visitor>)> _buildGroups(List<Visitor> visitors) {
    final sorted = List<Visitor>.from(visitors)
      ..sort((a, b) {
        final da = DateTime.tryParse(a.visitDate);
        final db = DateTime.tryParse(b.visitDate);
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });

    final Map<_DateGroup, List<Visitor>> grouped = {};
    for (final v in sorted) {
      final date = DateTime.tryParse(v.visitDate);
      final group = date != null ? _groupFor(date) : _DateGroup.upcoming;
      grouped.putIfAbsent(group, () => []).add(v);
    }

    const order = [
      _DateGroup.today,
      _DateGroup.tomorrow,
      _DateGroup.thisWeek,
      _DateGroup.upcoming,
      _DateGroup.past,
    ];

    return [
      for (final g in order)
        if (grouped.containsKey(g)) (g, grouped[g]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cubit = context.read<VisitorCubit>();
          await Navigator.of(context).pushNamed(AppRoutes.addVisitor);
          cubit.loadVisitors();
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<VisitorCubit, VisitorState>(
        builder: (context, state) {
          if (state is VisitorLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VisitorFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<VisitorCubit>().loadVisitors(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is VisitorLoaded) {
            if (state.visitors.isEmpty) {
              return const Center(child: Text('No visitors yet. Tap + to add one.'));
            }
            final groups = _buildGroups(state.visitors);
            return RefreshIndicator(
              onRefresh: () => context.read<VisitorCubit>().loadVisitors(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: groups.fold<int>(
                  0, (sum, g) => sum + 1 + g.$2.length,
                ),
                itemBuilder: (context, index) {
                  var offset = 0;
                  for (final (group, visitors) in groups) {
                    if (index == offset) {
                      return _SectionHeader(label: _groupLabel(group));
                    }
                    offset++;
                    if (index < offset + visitors.length) {
                      final v = visitors[index - offset];
                      return _VisitorCard(visitor: v, group: group);
                    }
                    offset += visitors.length;
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final _DateGroup group;
  const _VisitorCard({required this.visitor, required this.group});

  (String label, Color bg, Color fg) get _chip {
    return switch (group) {
      _DateGroup.today => ('Today', const Color(0xFF1565C0), Colors.white),
      _DateGroup.tomorrow => ('Tomorrow', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      _DateGroup.thisWeek => ('This Week', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      _DateGroup.upcoming => ('Scheduled', const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
      _DateGroup.past => ('Completed', const Color(0xFFF5F5F5), Colors.grey),
    };
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(visitor.visitDate);
    final dateStr = date != null ? DateFormat('d MMM yyyy').format(date) : visitor.visitDate;
    final chip = _chip;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: group == _DateGroup.past
              ? Colors.grey.shade400
              : const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          child: Text(visitor.name[0].toUpperCase()),
        ),
        title: Text(
          visitor.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: group == _DateGroup.past ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(visitor.mobile,
                style: TextStyle(
                  fontSize: 13,
                  color: group == _DateGroup.past ? Colors.grey.shade400 : null,
                )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chip.$2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chip.$1,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: chip.$3),
              ),
            ),
          ],
        ),
        trailing: Text(dateStr,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.visitorDetail,
          arguments: visitor.id,
        ),
      ),
    );
  }
}
