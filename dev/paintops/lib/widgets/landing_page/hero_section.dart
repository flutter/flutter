import 'package:flutter/material.dart';
import '../../utils/responsive_layout.dart';

class HeroSection extends StatefulWidget {
  final Function(String) onScrollToSection;

  const HeroSection({
    super.key,
    required this.onScrollToSection,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7FAFC),
            Color(0xFFEDF2F7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=1200&h=800&fit=crop',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Container(
              padding: ResponsiveLayout.getPadding(context),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ResponsiveLayout.isMobileLayout(context)
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Transform Your Space with HWR Painting Services',
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 32),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
        
        Text(
          'Professional painters delivering exceptional results for homes and businesses throughout Perth, Western Australia',
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 18),
            color: const Color(0xFF4A5568),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
        
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: ResponsiveLayout.getButtonHeight(context),
              child: ElevatedButton(
                onPressed: () => widget.onScrollToSection('contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BBA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone),
                    const SizedBox(width: 8),
                    Text(
                      'Get a Free Quote',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: ResponsiveLayout.getButtonHeight(context),
              child: OutlinedButton(
                onPressed: () => widget.onScrollToSection('services'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E5BBA),
                  side: const BorderSide(color: Color(0xFF2E5BBA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),

        _buildTrustIndicators(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transform Your Space with',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 48),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                  height: 1.1,
                ),
              ),
              Text(
                'HWR Painting Services',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 48),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E5BBA),
                  height: 1.1,
                ),
              ),
              
              SizedBox(height: ResponsiveLayout.getSpacing(context) * 2),
              
              Text(
                'Professional painters delivering exceptional results for homes and businesses throughout Perth, Western Australia. Quality craftsmanship, reliable service, and clear communication.',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                  color: const Color(0xFF4A5568),
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),
              
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => widget.onScrollToSection('contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BBA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone),
                        const SizedBox(width: 8),
                        Text(
                          'Get a Free Quote',
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  OutlinedButton(
                    onPressed: () => widget.onScrollToSection('services'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E5BBA),
                      side: const BorderSide(color: Color(0xFF2E5BBA)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Learn More',
                          style: TextStyle(
                            fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveLayout.getSpacing(context) * 3),

              _buildTrustIndicators(),
            ],
          ),
        ),
        
        const SizedBox(width: 60),
        
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=600&h=800&fit=crop',
                fit: BoxFit.cover,
                height: 500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ResponsiveLayout.isMobileLayout(context)
          ? Column(
              children: [
                _buildTrustItem(Icons.star, '4.9/5', 'Google Reviews'),
                const SizedBox(height: 12),
                _buildTrustItem(Icons.verified, '5+ Years', 'Experience'),
                const SizedBox(height: 12),
                _buildTrustItem(Icons.home_work, '500+', 'Projects Completed'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrustItem(Icons.star, '4.9/5', 'Google Reviews'),
                _buildTrustItem(Icons.verified, '5+ Years', 'Experience'),
                _buildTrustItem(Icons.home_work, '500+', 'Projects Completed'),
              ],
            ),
    );
  }

  Widget _buildTrustItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E5BBA),
          size: ResponsiveLayout.getIconSize(context, base: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 18),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(context, base: 12),
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}
