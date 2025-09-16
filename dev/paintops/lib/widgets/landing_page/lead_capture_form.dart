import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_layout.dart';
import '../../models/lead_model.dart';
import '../../repositories/lead_repository.dart';

class LeadCaptureForm extends StatefulWidget {
  const LeadCaptureForm({super.key});

  @override
  State<LeadCaptureForm> createState() => _LeadCaptureFormState();
}

class _LeadCaptureFormState extends State<LeadCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _projectDetailsController = TextEditingController();
  final LeadRepository _leadRepository = LeadRepository();
  
  String _selectedService = 'Interior Painting';
  String _selectedTimeline = 'Within 1 month';
  bool _isSubmitting = false;

  final List<String> _services = [
    'Interior Painting',
    'Exterior Painting',
    'Commercial Painting',
    'Cabinet Refinishing',
    'Specialty Finishes',
    'Full Home Renovation',
  ];

  final List<String> _timelines = [
    'ASAP',
    'Within 1 month',
    'Within 3 months',
    'Planning ahead',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _projectDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveLayout.getPadding(context),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E5BBA),
            Color(0xFF1A365D),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          Text(
            'Get Your Free Quote Today',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 28),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          Text(
            'Ready to transform your space? Fill out our quick form and we\'ll provide a detailed estimate within 24 hours.',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
          
          if (ResponsiveLayout.isMobileLayout(context))
            _buildMobileForm(context)
          else
            _buildDesktopForm(context),
            
          const SizedBox(height: 40),
          
          _buildContactInfo(context),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMobileForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildFormFields(context),
            const SizedBox(height: 24),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopForm(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormFields(context),
                  const SizedBox(height: 32),
                  _buildSubmitButton(context),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 40),
        
        Expanded(
          child: _buildFormBenefits(context),
        ),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
                validator: (value) => value?.isEmpty == true ? 'Phone is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Property Address *',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
          ),
          validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: InputDecoration(
                  labelText: 'Service Needed',
                  prefixIcon: const Icon(Icons.build),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
                items: _services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedService = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimeline,
                decoration: InputDecoration(
                  labelText: 'Timeline',
                  prefixIcon: const Icon(Icons.schedule),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
                items: _timelines.map((timeline) {
                  return DropdownMenuItem(
                    value: timeline,
                    child: Text(timeline),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTimeline = value);
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _projectDetailsController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Project Details',
            hintText: 'Tell us about your project, rooms to be painted, any special requirements...',
            prefixIcon: const Icon(Icons.description),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveLayout.getButtonHeight(context),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E5BBA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  Text(
                    'Get My Free Quote',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormBenefits(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.speed,
        'title': '24-Hour Response',
        'description': 'We\'ll get back to you within 24 hours with a detailed quote',
      },
      {
        'icon': Icons.money_off,
        'title': 'No Obligation',
        'description': 'Free consultation and estimate with no strings attached',
      },
      {
        'icon': Icons.verified_user,
        'title': 'Licensed & Insured',
        'description': 'Fully licensed painters with comprehensive insurance coverage',
      },
      {
        'icon': Icons.star,
        'title': 'Quality Guarantee',
        'description': 'We stand behind our work with a satisfaction guarantee',
      },
    ];

    return Column(
      children: benefits.map((benefit) => 
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      benefit['description'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Or Contact Us Directly',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (ResponsiveLayout.isMobileLayout(context))
            Column(
              children: [
                _buildContactItem(context, Icons.phone, '(08) 9123 4567', 'Call us now'),
                const SizedBox(height: 12),
                _buildContactItem(context, Icons.email, 'info@hwrpainting.com.au', 'Send us an email'),
                const SizedBox(height: 12),
                _buildContactItem(context, Icons.schedule, 'Mon-Fri 7AM-6PM, Sat 8AM-4PM', 'Business hours'),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildContactItem(context, Icons.phone, '(08) 9123 4567', 'Call us now'),
                _buildContactItem(context, Icons.email, 'info@hwrpainting.com.au', 'Send us an email'),
                _buildContactItem(context, Icons.schedule, 'Mon-Fri 7AM-6PM, Sat 8AM-4PM', 'Business hours'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: ResponsiveLayout.getIconSize(context, base: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 14),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 12),
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final lead = LeadModel(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        projectType: _selectedService,
        timeline: _selectedTimeline,
        message: _projectDetailsController.text.trim(),
        status: LeadStatus.newLead,
        createdAt: DateTime.now(),
      );

      final success = await _leadRepository.createLead(lead);
      
      if (success) {
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF10B981),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text('Quote Request Submitted!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thank you for your interest in HWR Painting Services, ${_nameController.text}!'),
                  const SizedBox(height: 12),
                  const Text('We\'ve received your quote request and will contact you within 24 hours to discuss your project and schedule a consultation.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: const Color(0xFF2E5BBA), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keep an eye on your phone for our call!',
                            style: TextStyle(
                              color: const Color(0xFF1E40AF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5BBA),
                  ),
                  child: const Text('Great!'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to submit lead');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit form: Please try again or call us directly.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _projectDetailsController.clear();
    setState(() {
      _selectedService = 'Interior Painting';
      _selectedTimeline = 'Within 1 month';
    });
  }
}
