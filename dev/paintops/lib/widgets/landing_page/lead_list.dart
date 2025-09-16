import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../../models/lead_model.dart';
import '../../repositories/lead_repository.dart';

class LeadList extends StatefulWidget {
  const LeadList({super.key});

  @override
  State<LeadList> createState() => _LeadListState();
}

class _LeadListState extends State<LeadList> {
  final LeadRepository _leadRepository = LeadRepository();
  List<LeadModel> _leads = [];
  bool _isLoading = true;
  String? _error;
  LeadStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leads = await _leadRepository.getLeads(status: _filterStatus);
      setState(() {
        _leads = leads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Failed to load leads', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeads,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildFilterBar(),
        Expanded(
          child: _leads.isEmpty ? _buildEmptyState() : _buildLeadsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Customer Leads',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Chip(
            label: Text('${_leads.length} Total'),
            backgroundColor: const Color(0xFF2E5BBA).withOpacity(0.1),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeads,
            tooltip: 'Refresh Leads',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _filterStatus == null),
            const SizedBox(width: 8),
            ...LeadStatus.values.map((status) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  status.displayName, 
                  _filterStatus == status,
                  status: status,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {LeadStatus? status}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
        _loadLeads();
      },
      selectedColor: const Color(0xFF2E5BBA).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2E5BBA),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterStatus == null ? 'No leads yet' : 'No ${_filterStatus!.displayName.toLowerCase()} leads',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Leads will appear here when customers submit the contact form.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsList() {
    return RefreshIndicator(
      onRefresh: _loadLeads,
      child: ListView.builder(
        itemCount: _leads.length,
        itemBuilder: (context, index) {
          final lead = _leads[index];
          return _buildLeadCard(lead);
        },
      ),
    );
  }

  Widget _buildLeadCard(LeadModel lead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lead.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lead.projectType} • ${_formatDate(lead.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(lead.email ?? 'No email', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(lead.phone, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(lead.address, style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
            if (lead.timeline.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Timeline: ${lead.timeline}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              lead.message ?? 'No additional details provided',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Call'),
                  onPressed: () => _contactLead(lead, 'call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.email, size: 16),
                  label: const Text('Email'),
                  onPressed: () => _contactLead(lead, 'email'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Schedule'),
                  onPressed: () => _scheduleMeeting(lead),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _updateLeadStatus(lead, value),
                  itemBuilder: (context) => LeadStatus.values
                      .where((status) => status != lead.status)
                      .map((status) => PopupMenuItem(
                            value: status.name,
                            child: Text('Mark as ${status.displayName}'),
                          ))
                      .toList(),
                  child: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.contacted:
        return Colors.orange;
      case LeadStatus.quoted:
        return Colors.purple;
      case LeadStatus.scheduled:
        return Colors.indigo;
      case LeadStatus.won:
        return Colors.green;
      case LeadStatus.lost:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _contactLead(LeadModel lead, String method) async {
    if (method == 'call') {
      if (kIsWeb) {
        // On web, we can't directly initiate calls, so copy number to clipboard
        await Clipboard.setData(ClipboardData(text: lead.phone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number ${lead.phone} copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // On mobile, try to open dialer
        try {
          // This would normally use url_launcher package
          // For demo, we'll just show the number
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Would call ${lead.phone}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          await Clipboard.setData(ClipboardData(text: lead.phone));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone number ${lead.phone} copied to clipboard'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } else if (method == 'email') {
      if (kIsWeb) {
        // On web, try to open mailto link
        try {
          js.context.callMethod('open', ['mailto:${lead.email ?? ""}?subject=Re: Your Painting Inquiry']);
        } catch (e) {
          if (lead.email != null) {
            await Clipboard.setData(ClipboardData(text: lead.email!));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email address ${lead.email!} copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      } else {
        // On mobile, this would use url_launcher
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Would email ${lead.email ?? "No email"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    // Update lead status to contacted
    _updateLeadStatus(lead, LeadStatus.contacted.name);
  }

  void _scheduleMeeting(LeadModel lead) {
    if (kIsWeb) {
      // On web, show a dialog with calendar options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Schedule Meeting with ${lead.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact: ${lead.phone}'),
              Text('Email: ${lead.email ?? "No email"}'),
              Text('Address: ${lead.address}'),
              const SizedBox(height: 16),
              const Text('Use your preferred calendar app to schedule:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Google Calendar'),
                    onPressed: () {
                      Navigator.pop(context);
                      js.context.callMethod('open', ['https://calendar.google.com']);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Outlook'),
                    onPressed: () {
                      Navigator.pop(context);
                      js.context.callMethod('open', ['https://outlook.live.com/calendar']);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      // On mobile, this would integrate with native calendar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Would schedule meeting with ${lead.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // Update lead status to scheduled
    _updateLeadStatus(lead, LeadStatus.scheduled.name);
  }

  void _updateLeadStatus(LeadModel lead, String statusName) async {
    final status = LeadStatus.values.firstWhere((s) => s.name == statusName);
    
    try {
      await _leadRepository.updateLeadStatus(lead.id, status);
      _loadLeads(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lead.name} marked as ${status.displayName}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update lead status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
