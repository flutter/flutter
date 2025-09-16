import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/landing_page_content_model.dart';
import '../repositories/landing_page_repository.dart';
import '../widgets/landing_page/lead_list.dart';
import '../utils/responsive_layout.dart';

class LandingPageAdminScreen extends StatefulWidget {
  const LandingPageAdminScreen({super.key});

  @override
  State<LandingPageAdminScreen> createState() => _LandingPageAdminScreenState();
}

class _LandingPageAdminScreenState extends State<LandingPageAdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final LandingPageRepository _repository = LandingPageRepository();
  
  // Hero Section Data
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _heroPrimaryCtaController = TextEditingController();
  final _heroSecondaryCtaController = TextEditingController();
  
  // Service Sections Data
  final List<Map<String, TextEditingController>> _services = [];
  
  // Portfolio Data
  final List<Map<String, dynamic>> _portfolioItems = [];
  
  // Business Info Data
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessHoursController = TextEditingController();

  LandingPageContentModel? _currentContent;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _heroPrimaryCtaController.dispose();
    _heroSecondaryCtaController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessHoursController.dispose();
    for (var service in _services) {
      service['title']?.dispose();
      service['description']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    
    try {
      final content = await _repository.getLandingPageContent();
      if (content != null) {
        _currentContent = content;
        _populateFields(content);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading content: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(LandingPageContentModel content) {
    _heroTitleController.text = content.heroTitle;
    _heroSubtitleController.text = content.heroSubtitle;
    _heroPrimaryCtaController.text = content.heroPrimaryCta;
    _heroSecondaryCtaController.text = content.heroSecondaryCta;

    // Clear existing services
    for (var service in _services) {
      service['title']?.dispose();
      service['description']?.dispose();
    }
    _services.clear();

    // Populate services
    for (var service in content.services) {
      _services.add({
        'id': TextEditingController(text: service.id),
        'title': TextEditingController(text: service.title),
        'description': TextEditingController(text: service.description),
        'imageUrl': TextEditingController(text: service.imageUrl),
      });
    }

    // Populate portfolio
    _portfolioItems.clear();
    _portfolioItems.addAll(content.portfolio.map((item) => {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'beforeImage': item.beforeImageUrl,
      'afterImage': item.afterImageUrl,
    }));

    // Populate business info
    _businessNameController.text = content.businessInfo.name;
    _businessAddressController.text = content.businessInfo.address;
    _businessPhoneController.text = content.businessInfo.phone;
    _businessEmailController.text = content.businessInfo.email;
    _businessHoursController.text = content.businessInfo.hours;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Landing Page Admin'),
          backgroundColor: const Color(0xFF2E5BBA),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page Admin'),
        backgroundColor: const Color(0xFF2E5BBA),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () => Navigator.of(context).pushNamed('/landing'),
            tooltip: 'Preview Landing Page',
          ),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hero Section'),
            Tab(text: 'Services'),
            Tab(text: 'Portfolio'),
            Tab(text: 'Business Info'),
            Tab(text: 'Leads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHeroSectionTab(),
          _buildServicesTab(),
          _buildPortfolioTab(),
          _buildBusinessInfoTab(),
          const LeadList(),
        ],
      ),
    );
  }

  Widget _buildHeroSectionTab() {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hero Section Content',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  TextFormField(
                    controller: _heroTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Main Headline',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  TextFormField(
                    controller: _heroSubtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  if (ResponsiveLayout.isMobileLayout(context))
                    ...[
                      TextFormField(
                        controller: _heroPrimaryCtaController,
                        decoration: const InputDecoration(
                          labelText: 'Primary CTA Button',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: ResponsiveLayout.getSpacing(context)),
                      TextFormField(
                        controller: _heroSecondaryCtaController,
                        decoration: const InputDecoration(
                          labelText: 'Secondary CTA Button',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ]
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heroPrimaryCtaController,
                            decoration: const InputDecoration(
                              labelText: 'Primary CTA Button',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveLayout.getSpacing(context)),
                        Expanded(
                          child: TextFormField(
                            controller: _heroSecondaryCtaController,
                            decoration: const InputDecoration(
                              labelText: 'Secondary CTA Button',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hero Image Management',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  Container(
                    height: ResponsiveLayout.isMobileLayout(context) ? 150 : 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image, 
                          size: ResponsiveLayout.isMobileLayout(context) ? 48 : 64, 
                          color: Colors.grey,
                        ),
                        SizedBox(height: ResponsiveLayout.getSpacing(context)),
                        const Text('Hero Background Image'),
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb ? 'Click to upload new image' : 'Tap to upload new image',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  if (ResponsiveLayout.isMobileLayout(context))
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload New Image'),
                            onPressed: () => _showUploadDialog('hero_image'),
                          ),
                        ),
                        SizedBox(height: ResponsiveLayout.getSpacing(context)),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Image'),
                            onPressed: () => _confirmRemoveImage('hero_image'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload New Image'),
                          onPressed: () => _showUploadDialog('hero_image'),
                        ),
                        SizedBox(width: ResponsiveLayout.getSpacing(context)),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove Image'),
                          onPressed: () => _confirmRemoveImage('hero_image'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Service Offerings',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(ResponsiveLayout.isMobileLayout(context) ? 'Add' : 'Add Service'),
                    onPressed: _addNewService,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          ..._services.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: ResponsiveLayout.getSpacing(context)),
              child: Padding(
                padding: ResponsiveLayout.getPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Service ${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeService(index),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveLayout.getSpacing(context)),
                    TextFormField(
                      controller: service['title'],
                      decoration: const InputDecoration(
                        labelText: 'Service Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: ResponsiveLayout.getSpacing(context)),
                    TextFormField(
                      controller: service['description'],
                      decoration: const InputDecoration(
                        labelText: 'Service Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: ResponsiveLayout.getSpacing(context)),
                    InkWell(
                      onTap: () => _showUploadDialog('service_$index'),
                      child: Container(
                        height: ResponsiveLayout.isMobileLayout(context) ? 100 : 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image, 
                              size: ResponsiveLayout.isMobileLayout(context) ? 24 : 32, 
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text('Service Image ${index + 1}'),
                            Text(
                              kIsWeb ? 'Click to upload' : 'Tap to upload',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Portfolio Gallery',
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(ResponsiveLayout.isMobileLayout(context) ? 'Add' : 'Add Project'),
                    onPressed: _addNewPortfolioItem,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          ..._portfolioItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: ResponsiveLayout.getSpacing(context)),
              child: Padding(
                padding: ResponsiveLayout.getPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? 'Portfolio Item ${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getFontSize(context, base: 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(item['category'] ?? 'Interior'),
                          backgroundColor: const Color(0xFF2E5BBA).withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editPortfolioItem(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePortfolioItem(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item['description'] ?? 'Portfolio description'),
                    SizedBox(height: ResponsiveLayout.getSpacing(context)),
                    if (ResponsiveLayout.isMobileLayout(context))
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _showUploadDialog('portfolio_before_$index'),
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 24, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Before Image', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveLayout.getSpacing(context)),
                          InkWell(
                            onTap: () => _showUploadDialog('portfolio_after_$index'),
                            child: Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 24, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('After Image', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showUploadDialog('portfolio_before_$index'),
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 32, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Before Image'),
                                    Text('Click to upload', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveLayout.getSpacing(context)),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showUploadDialog('portfolio_after_$index'),
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 32, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('After Image'),
                                    Text('Click to upload', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoTab() {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Information',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  if (ResponsiveLayout.isMobileLayout(context))
                    ...[
                      TextFormField(
                        controller: _businessPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: ResponsiveLayout.getSpacing(context)),
                      TextFormField(
                        controller: _businessEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ]
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _businessPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(width: ResponsiveLayout.getSpacing(context)),
                        Expanded(
                          child: TextFormField(
                            controller: _businessEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  TextFormField(
                    controller: _businessHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Business Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveLayout.getSpacing(context)),
          Card(
            child: Padding(
              padding: ResponsiveLayout.getPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Indicators',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(context, base: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveLayout.getSpacing(context)),
                  const ListTile(
                    leading: Icon(Icons.star, color: Colors.amber),
                    title: Text('Google Reviews'),
                    subtitle: Text('4.9/5 stars (127 reviews)'),
                    trailing: Icon(Icons.edit),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.verified, color: Colors.green),
                    title: Text('Master Painters Australia'),
                    subtitle: Text('Certified Member'),
                    trailing: Icon(Icons.edit),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.security, color: Colors.blue),
                    title: Text('Insurance & Licensing'),
                    subtitle: Text('Fully licensed and insured'),
                    trailing: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final services = _services.map((service) => ServiceContent(
        id: service['id']?.text ?? '',
        title: service['title']?.text ?? '',
        description: service['description']?.text ?? '',
        imageUrl: service['imageUrl']?.text ?? '',
      )).toList();

      final portfolio = _portfolioItems.map((item) => PortfolioItem(
        id: item['id'] ?? '',
        title: item['title'] ?? '',
        description: item['description'] ?? '',
        category: item['category'] ?? '',
        beforeImageUrl: item['beforeImage'] ?? '',
        afterImageUrl: item['afterImage'] ?? '',
      )).toList();

      final businessInfo = BusinessInfo(
        name: _businessNameController.text,
        address: _businessAddressController.text,
        phone: _businessPhoneController.text,
        email: _businessEmailController.text,
        hours: _businessHoursController.text,
      );

      final content = LandingPageContentModel(
        id: _currentContent?.id ?? 'main',
        heroTitle: _heroTitleController.text,
        heroSubtitle: _heroSubtitleController.text,
        heroPrimaryCta: _heroPrimaryCtaController.text,
        heroSecondaryCta: _heroSecondaryCtaController.text,
        heroImageUrl: _currentContent?.heroImageUrl ?? '',
        services: services,
        portfolio: portfolio,
        businessInfo: businessInfo,
        updatedAt: DateTime.now(),
      );

      final success = await _repository.saveLandingPageContent(content);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Changes saved successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        _currentContent = content;
      } else {
        throw Exception('Failed to save changes');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showUploadDialog(String imageType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kIsWeb) ...{
              const Text('On web, image upload functionality would include:'),
              SizedBox(height: ResponsiveLayout.getSpacing(context)),
              const Text('• File picker dialog for selecting images'),
              const Text('• Image compression and validation'),
              const Text('• Progress indication during upload'),
              const Text('• URL storage in Supabase database'),
            } else ...{
              const Text('Mobile image upload would provide:'),
              SizedBox(height: ResponsiveLayout.getSpacing(context)),
              const Text('• Camera or gallery picker options'),
              const Text('• Automatic image compression'),
              const Text('• Upload to Supabase Storage'),
              const Text('• URL saved to database'),
            }
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image upload feature will be implemented with ${kIsWeb ? 'file picker' : 'camera/gallery picker'} and Supabase Storage'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Select Image'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveImage(String imageType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addNewService() {
    setState(() {
      _services.add({
        'id': TextEditingController(text: 'service_${_services.length + 1}'),
        'title': TextEditingController(text: 'New Service'),
        'description': TextEditingController(text: 'Service description'),
        'imageUrl': TextEditingController(text: ''),
      });
    });
  }

  void _removeService(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Service'),
        content: const Text('Are you sure you want to remove this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services[index]['title']?.dispose();
                _services[index]['description']?.dispose();
                _services[index]['id']?.dispose();
                _services[index]['imageUrl']?.dispose();
                _services.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addNewPortfolioItem() {
    setState(() {
      _portfolioItems.add({
        'id': 'portfolio_${_portfolioItems.length + 1}',
        'title': 'New Project',
        'description': 'Project description',
        'category': 'Interior',
        'beforeImage': '',
        'afterImage': '',
      });
    });
  }

  void _editPortfolioItem(int index) {
    final item = _portfolioItems[index];
    final titleController = TextEditingController(text: item['title'] ?? '');
    final descController = TextEditingController(text: item['description'] ?? '');
    String selectedCategory = item['category'] ?? 'Interior';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Portfolio Item'),
          content: SizedBox(
            width: ResponsiveLayout.isMobileLayout(context) ? double.infinity : 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: ResponsiveLayout.getSpacing(context)),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                SizedBox(height: ResponsiveLayout.getSpacing(context)),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Interior', 'Exterior', 'Commercial', 'Specialty']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => selectedCategory = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _portfolioItems[index]['title'] = titleController.text;
                  _portfolioItems[index]['description'] = descController.text;
                  _portfolioItems[index]['category'] = selectedCategory;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removePortfolioItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Portfolio Item'),
        content: const Text('Are you sure you want to remove this portfolio item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _portfolioItems.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
