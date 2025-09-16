import 'package:flutter/material.dart';
import '../../utils/responsive_layout.dart';

class ServiceSections extends StatelessWidget {
  const ServiceSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveLayout.getPadding(context),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFC),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          Text(
            'Our Painting Services',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 28),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          Text(
            'Comprehensive painting solutions for residential and commercial properties throughout Perth',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
          
          if (ResponsiveLayout.isMobileLayout(context))
            _buildMobileServices(context)
          else
            _buildDesktopServices(context),
            
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMobileServices(BuildContext context) {
    final services = _getServices();
    
    return Column(
      children: services.map((service) => 
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: _buildServiceCard(context, service),
        ),
      ).toList(),
    );
  }

  Widget _buildDesktopServices(BuildContext context) {
    final services = _getServices();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildServiceCard(context, services[0])),
            const SizedBox(width: 24),
            Expanded(child: _buildServiceCard(context, services[1])),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildServiceCard(context, services[2])),
            const SizedBox(width: 24),
            Expanded(child: _buildServiceCard(context, services[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Container(
      height: ResponsiveLayout.isMobileLayout(context) ? null : 400,
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
          // Service image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(service['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (service['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: service['color'] as Color,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    service['title'] as String,
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: Text(
                      service['description'] as String,
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 14),
                        color: const Color(0xFF718096),
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Includes:',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A5568),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (service['features'] as List<String>).map((feature) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: service['color'] as Color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                                  color: const Color(0xFF718096),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getServices() {
    return [
      {
        'title': 'Interior Painting',
        'description': 'Transform your living spaces with professional interior painting services. From single rooms to whole house makeovers.',
        'icon': Icons.home,
        'color': const Color(0xFF2E5BBA),
        'image': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&h=300&fit=crop',
        'features': [
          'Wall preparation and priming',
          'Ceiling painting',
          'Trim and door finishing',
          'Color consultation',
          'Furniture protection',
        ],
      },
      {
        'title': 'Exterior Painting',
        'description': 'Protect and beautify your property with expert exterior painting. Weather-resistant finishes that last.',
        'icon': Icons.home_work,
        'color': const Color(0xFF10B981),
        'image': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=300&fit=crop',
        'features': [
          'Pressure washing and prep',
          'Weatherboard painting',
          'Roof and gutter painting',
          'Deck and fence staining',
          'Premium weather-resistant paints',
        ],
      },
      {
        'title': 'Commercial Painting',
        'description': 'Professional commercial painting services for offices, retail spaces, and industrial facilities.',
        'icon': Icons.business,
        'color': const Color(0xFFEF4444),
        'image': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&h=300&fit=crop',
        'features': [
          'Minimal business disruption',
          'After-hours scheduling',
          'Industrial-grade coatings',
          'Safety compliance',
          'Large-scale project management',
        ],
      },
      {
        'title': 'Specialty Finishes',
        'description': 'Cabinet painting, decorative finishes, and specialty coating applications for unique projects.',
        'icon': Icons.palette,
        'color': const Color(0xFF8B5CF6),
        'image': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400&h=300&fit=crop',
        'features': [
          'Kitchen cabinet refinishing',
          'Decorative wall treatments',
          'Textured finishes',
          'Staining and varnishing',
          'Custom color matching',
        ],
      },
    ];
  }
}
