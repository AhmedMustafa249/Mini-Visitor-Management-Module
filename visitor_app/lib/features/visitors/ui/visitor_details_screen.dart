import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../cubit/visitor_cubit.dart';
import '../cubit/visitor_state.dart';
import '../data/visitor_repository.dart';
import '../data/visitor.dart';
import '../../auth/cubit/auth_cubit.dart';

class VisitorDetailsScreen extends StatelessWidget {
  final String visitorId;

  const VisitorDetailsScreen({super.key, required this.visitorId});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthCubit>().currentUser!.token;
    return BlocProvider(
      create: (_) => VisitorCubit(repository: VisitorRepository(token: token))
        ..loadVisitorDetail(visitorId),
      child: const _VisitorDetailsView(),
    );
  }
}

class _VisitorDetailsView extends StatelessWidget {
  const _VisitorDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<VisitorCubit, VisitorState>(
        builder: (context, state) {
          if (state is VisitorLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VisitorFailure) {
            return Center(child: Text(state.message));
          }
          if (state is VisitorDetailLoaded) {
            return _VisitorDetailBody(visitor: state.visitor);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _VisitorDetailBody extends StatelessWidget {
  final Visitor visitor;

  const _VisitorDetailBody({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(visitor.visitDate);
    final dateStr =
        date != null ? DateFormat('d MMM yyyy').format(date) : visitor.visitDate;
    final createdAt = DateTime.tryParse(visitor.createdAt);
    final createdStr = createdAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(createdAt.toLocal())
        : visitor.createdAt;

    final qrData = jsonEncode(visitor.toJson());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    child: Text(
                      visitor.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    visitor.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(icon: Icons.phone_outlined, label: 'Mobile', value: visitor.mobile),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Visit Date', value: dateStr),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.schedule_outlined, label: 'Registered', value: createdStr),
                  const Divider(height: 24),
                  _DetailRow(icon: Icons.fingerprint, label: 'ID', value: visitor.id, small: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Visitor QR Code',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to verify visitor identity',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool small;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: small ? 11 : 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
