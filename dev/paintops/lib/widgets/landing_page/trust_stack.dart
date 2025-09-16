import 'package:flutter/material.dart';
import '../../utils/responsive_layout.dart';

class TrustStack extends StatelessWidget {
  const TrustStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveLayout.getPadding(context),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          Text(
            'Trusted by Perth Homeowners & Businesses',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 28),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
          
          if (ResponsiveLayout.isMobileLayout(context))
            _buildMobileLayout(context)
          else
            _buildDesktopLayout(context),
            
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTestimonials(context),
        SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
        _buildCredentials(context),
        SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
        _buildProcess(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildTestimonials(context),
        SizedBox(height: ResponsiveLayout.getSpacing(context) * 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCredentials(context)),
            const SizedBox(width: 40),
            Expanded(child: _buildProcess(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildTestimonials(BuildContext context) {
    final testimonials = [
      {
        'name': 'Sarah Mitchell',
        'location': 'Cottesloe',
        'rating': 5,
        'text': 'HWR transformed our home with exceptional interior painting. Professional, clean, and the results exceeded our expectations. Highly recommended!',
        'project': 'Interior Home Renovation',
      },
      {
        'name': 'David Chen',
        'location': 'Subiaco',
        'rating': 5,
        'text': 'Outstanding exterior painting service. The team was punctual, respectful, and delivered flawless results. Our house looks brand new!',
        'project': 'Exterior House Painting',
      },
      {
        'name': 'Emma Rodriguez',
        'location': 'Fremantle',
        'rating': 5,
        'text': 'Professional commercial painting for our office. Completed on time, within budget, and with minimal disruption to our business operations.',
        'project': 'Commercial Office Painting',
      },
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) => const Icon(
                Icons.star,
                color: Color(0xFFFFB800),
                size: 24,
              )),
              const SizedBox(width: 12),
              Text(
                '4.9/5 on Google Reviews',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),

        if (ResponsiveLayout.isMobileLayout(context))
          Column(
            children: testimonials.map((testimonial) => 
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildTestimonialCard(context, testimonial),
              ),
            ).toList(),
          )
        else
          Row(
            children: testimonials.map((testimonial) => 
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildTestimonialCard(context, testimonial),
                ),
              ),
            ).toList(),
          ),
      ],
    );
  }

  Widget _buildTestimonialCard(BuildContext context, Map<String, dynamic> testimonial) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(testimonial['rating'] as int, (index) =>
              const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '"${testimonial['text']}"',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 14),
              color: const Color(0xFF4A5568),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5BBA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    (testimonial['name'] as String)[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['name'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      testimonial['location'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 10),
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentials(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certified & Insured',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          _buildCredentialItem(
            context,
            Icons.verified_user,
            'Master Painters Australia',
            'Certified member with proven expertise',
          ),
          
          const SizedBox(height: 16),
          
          _buildCredentialItem(
            context,
            Icons.security,
            'Fully Insured',
            'Comprehensive liability and workers compensation',
          ),
          
          const SizedBox(height: 16),
          
          _buildCredentialItem(
            context,
            Icons.business,
            'Licensed Contractor',
            'WA Building Commission licensed',
          ),
          
          const SizedBox(height: 16),
          
          _buildCredentialItem(
            context,
            Icons.eco,
            'Eco-Friendly',
            'Low-VOC and environmentally safe paints',
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF10B981),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                  color: const Color(0xFF718096),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcess(BuildContext context) {
    final steps = [
      {
        'number': '1',
        'title': 'Free Consultation',
        'description': 'We assess your project and provide detailed estimates',
      },
      {
        'number': '2',
        'title': 'Preparation',
        'description': 'Professional surface prep and protection of surroundings',
      },
      {
        'number': '3',
        'title': 'Quality Application',
        'description': 'Expert painting using premium materials and techniques',
      },
      {
        'number': '4',
        'title': 'Final Inspection',
        'description': 'Thorough quality check and client walkthrough',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Process',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: index < steps.length - 1 ? 20 : 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5BBA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        step['number']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title']!,
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          step['description']!,
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                            color: const Color(0xFF718096),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
