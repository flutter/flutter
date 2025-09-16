import 'package:flutter/material.dart';
import '../widgets/landing_page/hero_section.dart';
import '../widgets/landing_page/trust_stack.dart';
import '../widgets/landing_page/service_sections.dart';
import '../widgets/landing_page/portfolio_gallery.dart';
import '../widgets/landing_page/lead_capture_form.dart';
import '../models/landing_page_content_model.dart';
import '../repositories/landing_page_repository.dart';
import '../screens/auth_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final LandingPageRepository _repository = LandingPageRepository();
  final ScrollController _scrollController = ScrollController();
  LandingPageContentModel? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    
    try {
      final content = await _repository.getLandingPageContent();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading landing page content: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF2E5BBA),
            foregroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            floating: false,
            expandedHeight: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/icons/icon.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.business, color: Colors.white, size: 20),
                  );
                },
              ),
            ),
            title: const Text(
              'HWR Painting Services',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _scrollToSection(4),
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: const Text('(08) 9123-4567', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showLoginDialog,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Staff Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2E5BBA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                HeroSection(onScrollToSection: (String sectionId) {
                  int section = 0;
                  switch (sectionId) {
                    case 'services':
                      section = 2;
                      break;
                    case 'portfolio':
                      section = 3;
                      break;
                    case 'contact':
                      section = 4;
                      break;
                    default:
                      section = 0;
                  }
                  _scrollToSection(section);
                }),
                const TrustStack(),
                const ServiceSections(),
                const PortfolioGallery(),
                const LeadCaptureForm(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scrollToSection(4),
        backgroundColor: const Color(0xFF2E5BBA),
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      color: const Color(0xFF1A365D),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'HWR Painting Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _content?.businessInfo.address ?? '123 Swan Street, Perth WA 6000',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_content?.businessInfo.phone ?? '(08) 9123-4567'} • ${_content?.businessInfo.email ?? 'info@hwrpainting.com.au'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _content?.businessInfo.hours ?? 'Mon-Fri: 7AM-6PM, Sat: 8AM-4PM',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _showLoginDialog,
                child: const Text(
                  'Staff Login',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} HWR Painting Services. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(int section) {
    double offset = 0;
    switch (section) {
      case 0: // Hero
        offset = 0;
        break;
      case 1: // Trust
        offset = 600;
        break;
      case 2: // Services
        offset = 1200;
        break;
      case 3: // Portfolio
        offset = 2000;
        break;
      case 4: // Contact
        offset = 2800;
        break;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5BBA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.login, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Staff Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: const AuthScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
