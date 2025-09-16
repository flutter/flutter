import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> sendNewLeadNotification(LeadModel lead) async {
    try {
      // In production, this would integrate with an email service
      // For now, we'll log the email and store it in a queue table
      
      final emailData = {
        'to_email': 'admin@hwrpainting.com.au',
        'subject': 'New Lead: ${lead.name} - ${lead.projectType}',
        'body': _generateLeadNotificationEmail(lead),
        'lead_id': lead.id,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Store email in queue (you would create this table)
      await _logEmailNotification(emailData);
      
      print('New lead email notification queued for: ${lead.name}');
      return true;
    } catch (e) {
      print('Error sending new lead notification: $e');
      return false;
    }
  }

  Future<bool> sendTimesheetApprovalNotification(String supervisorEmail, String workerName, String projectName) async {
    try {
      final emailData = {
        'to_email': supervisorEmail,
        'subject': 'Timesheet Approval Required: $workerName',
        'body': _generateTimesheetApprovalEmail(workerName, projectName),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _logEmailNotification(emailData);
      
      print('Timesheet approval email notification queued for: $supervisorEmail');
      return true;
    } catch (e) {
      print('Error sending timesheet approval notification: $e');
      return false;
    }
  }

  Future<bool> sendExpenseApprovalNotification(String supervisorEmail, String submitterName, double amount, String projectName) async {
    try {
      final emailData = {
        'to_email': supervisorEmail,
        'subject': 'Expense Approval Required: \$${amount.toStringAsFixed(2)}',
        'body': _generateExpenseApprovalEmail(submitterName, amount, projectName),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _logEmailNotification(emailData);
      
      print('Expense approval email notification queued for: $supervisorEmail');
      return true;
    } catch (e) {
      print('Error sending expense approval notification: $e');
      return false;
    }
  }

  Future<bool> sendQuoteResponseEmail(String leadEmail, String leadName, double quoteAmount) async {
    try {
      final emailData = {
        'to_email': leadEmail,
        'subject': 'Your Painting Quote from HWR Painting Services',
        'body': _generateQuoteResponseEmail(leadName, quoteAmount),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _logEmailNotification(emailData);
      
      print('Quote response email queued for: $leadEmail');
      return true;
    } catch (e) {
      print('Error sending quote response: $e');
      return false;
    }
  }

  Future<void> _logEmailNotification(Map<String, dynamic> emailData) async {
    try {
      // In a real implementation, you would store this in an email_queue table
      // For now, we'll just log it
      print('Email logged: ${emailData['subject']} to ${emailData['to_email']}');
    } catch (e) {
      print('Error logging email notification: $e');
    }
  }

  String _generateLeadNotificationEmail(LeadModel lead) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>New Lead Notification</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #2E5BBA; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">New Lead Received!</h1>
    </div>
    
    <div style="background-color: #f8f9fa; padding: 20px; border: 1px solid #e9ecef; border-radius: 0 0 8px 8px;">
        <h2 style="color: #2E5BBA; margin-top: 0;">Lead Details</h2>
        
        <table style="width: 100%; border-collapse: collapse;">
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Name:</td>
                <td style="padding: 8px 0;">${lead.name}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Phone:</td>
                <td style="padding: 8px 0;">${lead.phone}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Email:</td>
                <td style="padding: 8px 0;">${lead.email ?? 'Not provided'}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Address:</td>
                <td style="padding: 8px 0;">${lead.address}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Project Type:</td>
                <td style="padding: 8px 0;">${lead.projectType}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Timeline:</td>
                <td style="padding: 8px 0;">${lead.timeline}</td>
            </tr>
            <tr>
                <td style="padding: 8px 0; font-weight: bold; color: #666;">Urgency:</td>
                <td style="padding: 8px 0; color: ${lead.urgencyLevel == 'Urgent' ? '#dc3545' : lead.urgencyLevel == 'High' ? '#fd7e14' : '#28a745'};">${lead.urgencyLevel}</td>
            </tr>
        </table>
        
        ${lead.message != null && lead.message!.isNotEmpty ? '''
        <h3 style="color: #2E5BBA; margin-top: 20px;">Project Details</h3>
        <div style="background-color: white; padding: 15px; border-radius: 4px; border-left: 4px solid #2E5BBA;">
            ${lead.message}
        </div>
        ''' : ''}
        
        <div style="margin-top: 20px; padding: 15px; background-color: #e3f2fd; border-radius: 4px;">
            <p style="margin: 0; color: #1565c0;"><strong>⏰ Quick Action Required</strong></p>
            <p style="margin: 5px 0 0 0; font-size: 14px;">This lead was submitted ${lead.daysSinceCreated}. Response time is critical for conversion.</p>
        </div>
        
        <div style="text-align: center; margin-top: 20px;">
            <a href="https://paintops.com/admin" style="background-color: #2E5BBA; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">View Lead in Admin Panel</a>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String _generateTimesheetApprovalEmail(String workerName, String projectName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Timesheet Approval Required</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #2E5BBA; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Timesheet Approval Required</h1>
    </div>
    
    <div style="background-color: #f8f9fa; padding: 20px; border: 1px solid #e9ecef; border-radius: 0 0 8px 8px;">
        <p><strong>$workerName</strong> has submitted a new timesheet for the <strong>$projectName</strong> project that requires your approval.</p>
        
        <div style="margin: 20px 0; padding: 15px; background-color: #fff3cd; border-radius: 4px; border-left: 4px solid #ffc107;">
            <p style="margin: 0; color: #856404;"><strong>Action Required</strong></p>
            <p style="margin: 5px 0 0 0; font-size: 14px;">Please review and approve this timesheet to ensure accurate payroll processing.</p>
        </div>
        
        <div style="text-align: center; margin-top: 20px;">
            <a href="https://paintops.com/app" style="background-color: #2E5BBA; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Review Timesheet</a>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String _generateExpenseApprovalEmail(String submitterName, double amount, String projectName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Expense Approval Required</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #2E5BBA; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Expense Approval Required</h1>
    </div>
    
    <div style="background-color: #f8f9fa; padding: 20px; border: 1px solid #e9ecef; border-radius: 0 0 8px 8px;">
        <p><strong>$submitterName</strong> has submitted an expense of <strong>\$${amount.toStringAsFixed(2)}</strong> for the <strong>$projectName</strong> project that requires your approval.</p>
        
        <div style="margin: 20px 0; padding: 15px; background-color: #d4edda; border-radius: 4px; border-left: 4px solid #28a745;">
            <p style="margin: 0; color: #155724;"><strong>Quick Approval Needed</strong></p>
            <p style="margin: 5px 0 0 0; font-size: 14px;">Review the expense details and receipt to approve or reject this expense claim.</p>
        </div>
        
        <div style="text-align: center; margin-top: 20px;">
            <a href="https://paintops.com/app" style="background-color: #2E5BBA; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Review Expense</a>
        </div>
    </div>
</body>
</html>
    ''';
  }

  String _generateQuoteResponseEmail(String leadName, double quoteAmount) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Your Painting Quote from HWR Painting Services</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #2E5BBA; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
        <h1 style="margin: 0;">Your Painting Quote</h1>
        <p style="margin: 5px 0 0 0; opacity: 0.9;">HWR Painting Services</p>
    </div>
    
    <div style="background-color: #f8f9fa; padding: 20px; border: 1px solid #e9ecef; border-radius: 0 0 8px 8px;">
        <p>Dear $leadName,</p>
        
        <p>Thank you for choosing HWR Painting Services for your painting project. We've prepared a detailed quote based on your requirements.</p>
        
        <div style="background-color: white; border: 2px solid #2E5BBA; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
            <h2 style="color: #2E5BBA; margin: 0; font-size: 24px;">Project Quote</h2>
            <div style="font-size: 36px; font-weight: bold; color: #2E5BBA; margin: 10px 0;">\$${quoteAmount.toStringAsFixed(2)}</div>
            <p style="margin: 0; color: #666; font-size: 14px;">Includes materials, labor, and cleanup</p>
        </div>
        
        <div style="background-color: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0;">
            <h3 style="color: #2E5BBA; margin-top: 0;">What's Included:</h3>
            <ul style="margin: 10px 0; padding-left: 20px;">
                <li>Premium quality paints and materials</li>
                <li>Professional surface preparation</li>
                <li>Expert application and finishing</li>
                <li>Complete cleanup and disposal</li>
                <li>Quality guarantee on all work</li>
            </ul>
        </div>
        
        <p>This quote is valid for 30 days. To proceed with your project, please contact us at <strong>(08) 9123-4567</strong> or reply to this email.</p>
        
        <div style="text-align: center; margin-top: 30px;">
            <a href="tel:+61891234567" style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; margin: 0 5px;">Call Now</a>
            <a href="mailto:info@hwrpainting.com.au" style="background-color: #2E5BBA; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; margin: 0 5px;">Reply to Email</a>
        </div>
        
        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; text-align: center;">
            <p>HWR Painting Services<br>
            123 Swan Street, Perth WA 6000<br>
            (08) 9123-4567 | info@hwrpainting.com.au</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
