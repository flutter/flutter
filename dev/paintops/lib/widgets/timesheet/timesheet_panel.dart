import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/operations_provider.dart';
import '../../models/timesheet_model.dart';
import '../../utils/responsive_layout.dart';

class TimesheetPanel extends StatefulWidget {
  const TimesheetPanel({super.key});

  @override
  State<TimesheetPanel> createState() => _TimesheetPanelState();
}

class _TimesheetPanelState extends State<TimesheetPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OperationsProvider>(context, listen: false);
      provider.loadTimesheets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final operationsProvider = Provider.of<OperationsProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFECEFF1),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: ResponsiveLayout.getPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(authProvider),
            SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
            
            if (authProvider.canApproveTimesheets()) ...{
              _buildApprovalSection(operationsProvider, authProvider),
              SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
            },
            
            _buildTimesheetsList(operationsProvider, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF263238)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF37474F).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.access_time,
              size: ResponsiveLayout.getIconSize(context, base: 36),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Management',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  authProvider.canApproveTimesheets()
                      ? 'Review and approve team timesheets'
                      : 'Track your work hours and submit timesheets',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection(OperationsProvider provider, AuthProvider authProvider) {
    final pendingTimesheets = provider.pendingTimesheets;
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: ResponsiveLayout.getIconSize(context, base: 28),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Approvals',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                    Text(
                      '${pendingTimesheets.length} timesheets awaiting approval',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (pendingTimesheets.isNotEmpty) ...{
            SizedBox(height: ResponsiveLayout.getSpacing(context)),
            ...pendingTimesheets.take(3).map((timesheet) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildTimesheetCard(timesheet, authProvider, provider, showApprovalButton: true),
              );
            }).toList(),
            
            if (pendingTimesheets.length > 3)
              TextButton(
                onPressed: () => _showAllPendingDialog(pendingTimesheets, authProvider, provider),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF37474F),
                ),
                child: Text('View all ${pendingTimesheets.length} pending approvals'),
              ),
          } else ...{
            SizedBox(height: ResponsiveLayout.getSpacing(context)),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF10B981),
                    size: ResponsiveLayout.getIconSize(context, base: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All timesheets are approved',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        color: const Color(0xFF065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildTimesheetsList(OperationsProvider provider, AuthProvider authProvider) {
    final timesheets = provider.timesheets;
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Timesheets',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 22),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF37474F),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showComingSoonDialog('Timesheet Filters'),
                icon: const Icon(Icons.filter_list),
                label: const Text('Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF37474F),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          if (provider.isLoadingTimesheets)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (timesheets.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: timesheets.map((timesheet) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildTimesheetCard(timesheet, authProvider, provider),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimesheetCard(
    TimesheetModel timesheet,
    AuthProvider authProvider,
    OperationsProvider provider, {
    bool showApprovalButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFECEFF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timesheet.isApproved 
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            timesheet.projectName,
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF37474F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: timesheet.isApproved 
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (timesheet.isApproved 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444)).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            timesheet.isApproved ? 'Approved' : 'Pending',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timesheet.workerName,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                        color: const Color(0xFF78909C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF37474F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timesheet.formattedDate,
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 13),
                            color: const Color(0xFF78909C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF37474F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 14,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timesheet.formattedTimeRange,
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 13),
                            color: const Color(0xFF78909C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF37474F), Color(0xFF263238)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF37474F).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      timesheet.formattedDuration,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  if (showApprovalButton && authProvider.canApproveTimesheets() && !timesheet.isApproved)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _approveTimesheet(timesheet, authProvider, provider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          if (timesheet.description != null && timesheet.description!.isNotEmpty) ...{
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timesheet.description!,
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                  color: const Color(0xFF37474F),
                  height: 1.5,
                ),
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: ResponsiveLayout.getIconSize(context, base: 64),
            color: const Color(0xFF78909C),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          Text(
            'No Timesheets Yet',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your work hours to track project time',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 14),
              color: const Color(0xFF78909C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _approveTimesheet(
    TimesheetModel timesheet,
    AuthProvider authProvider,
    OperationsProvider provider,
  ) async {
    final success = await provider.approveTimesheet(
      timesheet.id,
      authProvider.currentUser!.fullName,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Timesheet approved successfully'
                : 'Failed to approve timesheet',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAllPendingDialog(
    List<TimesheetModel> pendingTimesheets,
    AuthProvider authProvider,
    OperationsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Pending Approvals (${pendingTimesheets.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: pendingTimesheets.length,
            itemBuilder: (context, index) {
              final timesheet = pendingTimesheets[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _buildTimesheetCard(
                  timesheet,
                  authProvider,
                  provider,
                  showApprovalButton: true,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('$feature Coming Soon'),
        content: Text('$feature functionality is being developed and will be available in the next update.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
