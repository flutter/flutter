import 'package:flutter/material.dart';
import '../../utils/responsive_layout.dart';

class PortfolioGallery extends StatefulWidget {
  const PortfolioGallery({super.key});

  @override
  State<PortfolioGallery> createState() => _PortfolioGalleryState();
}

class _PortfolioGalleryState extends State<PortfolioGallery> {
  String selectedCategory = 'All';
  
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
            'Our Recent Projects',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 28),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          
          Text(
            'See the quality and craftsmanship that sets us apart',
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
          
          _buildCategoryTabs(context),
          
          SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
          
          _buildPortfolioGrid(context),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final categories = ['All', 'Interior', 'Exterior', 'Commercial'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2E5BBA).withOpacity(0.1),
              checkmarkColor: const Color(0xFF2E5BBA),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2E5BBA) : const Color(0xFF718096),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2E5BBA) : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPortfolioGrid(BuildContext context) {
    final projects = _getFilteredProjects();
    
    if (ResponsiveLayout.isMobileLayout(context)) {
      return Column(
        children: projects.map((project) => 
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: _buildPortfolioCard(context, project),
          ),
        ).toList(),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isDesktopLayout(context) ? 3 : 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _buildPortfolioCard(context, projects[index]);
      },
    );
  }

  Widget _buildPortfolioCard(BuildContext context, Map<String, dynamic> project) {
    return GestureDetector(
      onTap: () => _showProjectDetails(context, project),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Before/After images
            Stack(
              children: [
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
                        image: NetworkImage(project['afterImage']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'After',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveLayout.getFontSize(context, base: 10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E5BBA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project['category'],
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 10),
                          color: const Color(0xFF2E5BBA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      project['title'],
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: const Color(0xFF718096),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project['location'],
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: Text(
                        project['description'],
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                          color: const Color(0xFF4A5568),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 12),
                            color: const Color(0xFF2E5BBA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: const Color(0xFF2E5BBA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isMobileLayout(context) ? double.infinity : 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Image carousel
              Container(
                height: 300,
                child: PageView(
                  children: [
                    _buildDetailImage(project['beforeImage'], 'Before'),
                    _buildDetailImage(project['afterImage'], 'After'),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFF718096),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project['location'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        project['fullDescription'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (project['details'] != null) ...{
                        const Text(
                          'Project Details:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(project['details'] as List<String>).map((detail) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      },
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailImage(String imageUrl, String label) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    final allProjects = _getAllProjects();
    
    if (selectedCategory == 'All') {
      return allProjects;
    }
    
    return allProjects.where((project) => project['category'] == selectedCategory).toList();
  }

  List<Map<String, dynamic>> _getAllProjects() {
    return [
      {
        'title': 'Modern Living Room Transformation',
        'category': 'Interior',
        'location': 'Cottesloe, WA',
        'description': 'Complete interior makeover with custom color scheme and premium finishes.',
        'fullDescription': 'A complete transformation of a 1960s living room featuring modern color palette, texture treatments, and high-end finishes. The project included wall preparation, primer application, and two coats of premium paint.',
        'beforeImage': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=600&h=400&fit=crop',
        'details': [
          'Complete wall preparation and repairs',
          'Custom mixed paint colors',
          'Ceiling and trim work',
          'Furniture and flooring protection',
          'Project completed in 3 days'
        ],
      },
      {
        'title': 'Heritage Home Exterior',
        'category': 'Exterior',
        'location': 'Fremantle, WA',
        'description': 'Restored heritage weatherboard home with period-appropriate colors.',
        'fullDescription': 'Careful restoration of a heritage-listed weatherboard home using traditional techniques and historically accurate color schemes. Special attention to preserving original character while providing modern protection.',
        'beforeImage': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=600&h=400&fit=crop',
        'details': [
          'Historical color research',
          'Lead-safe work practices',
          'Weatherboard restoration',
          'Period-appropriate finishes',
          'Heritage compliance approval'
        ],
      },
      {
        'title': 'Commercial Office Renovation',
        'category': 'Commercial',
        'location': 'Perth CBD, WA',
        'description': 'Corporate office space with modern branding colors and professional finish.',
        'fullDescription': 'Large-scale commercial painting project for a professional services firm. The project was completed during weekend hours to minimize business disruption and featured custom branding colors throughout.',
        'beforeImage': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=600&h=400&fit=crop',
        'details': [
          'Weekend and after-hours work',
          'Corporate branding colors',
          'High-traffic area coatings',
          'Minimal business disruption',
          'Professional project management'
        ],
      },
      {
        'title': 'Luxury Kitchen Cabinet Refinish',
        'category': 'Interior',
        'location': 'Subiaco, WA',
        'description': 'High-end kitchen cabinet painting with spray finish technique.',
        'fullDescription': 'Premium kitchen cabinet refinishing using professional spray equipment and high-durability coatings. The project transformed dated cabinets into a modern, luxury finish.',
        'beforeImage': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&h=400&fit=crop',
        'details': [
          'Professional spray finish',
          'Cabinet door removal and preparation',
          'High-durability coatings',
          'Hardware restoration',
          'Dust-free spray booth'
        ],
      },
      {
        'title': 'Retail Store Makeover',
        'category': 'Commercial',
        'location': 'Joondalup, WA',
        'description': 'Vibrant retail space transformation with brand-focused design.',
        'fullDescription': 'Complete retail space transformation featuring bold brand colors and creative accent walls. The project was completed in phases to maintain store operations throughout the renovation.',
        'beforeImage': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600&h=400&fit=crop',
        'details': [
          'Phased completion schedule',
          'Brand color matching',
          'Creative accent features',
          'Retail-grade finishes',
          'Customer area protection'
        ],
      },
      {
        'title': 'Coastal Home Exterior',
        'category': 'Exterior',
        'location': 'Scarborough, WA',
        'description': 'Weather-resistant coastal property painting with salt-air protection.',
        'fullDescription': 'Specialized coastal painting project using marine-grade coatings designed to withstand salt air and harsh coastal conditions. Complete exterior preparation and application.',
        'beforeImage': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=600&h=400&fit=crop',
        'afterImage': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600&h=400&fit=crop',
        'details': [
          'Marine-grade coatings',
          'Salt-air resistance',
          'Extensive preparation work',
          'Coastal condition protection',
          'Long-term durability focus'
        ],
      },
    ];
  }
}
