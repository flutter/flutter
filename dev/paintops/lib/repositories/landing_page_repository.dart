import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/landing_page_content_model.dart';

class LandingPageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<LandingPageContentModel?> getLandingPageContent() async {
    try {
      final response = await _supabase
          .from('landing_page_content')
          .select()
          .eq('id', 'main')
          .maybeSingle();

      if (response != null) {
        return LandingPageContentModel.fromJson(response);
      }
      
      // Return default content if none exists
      return _getDefaultContent();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading landing page content: $e');
      }
      return _getDefaultContent();
    }
  }

  Future<bool> saveLandingPageContent(LandingPageContentModel content) async {
    try {
      final data = content.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('landing_page_content')
          .upsert(data);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving landing page content: $e');
      }
      return false;
    }
  }

  Future<String?> uploadImage(String category, List<int> fileBytes, String fileName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$category/${timestamp}_$fileName';
      
      // Platform-specific file processing
      Uint8List processedBytes;
      if (kIsWeb) {
        processedBytes = await _processImageForWeb(Uint8List.fromList(fileBytes), fileName);
      } else {
        processedBytes = await _processImageForMobile(Uint8List.fromList(fileBytes), fileName);
      }
      
      await _supabase.storage
          .from('landing-page-images')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: kIsWeb ? _getMimeTypeFromFileName(fileName) : null,
            ),
          );

      final imageUrl = _supabase.storage
          .from('landing-page-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;
      
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2) {
        final filePath = pathSegments.sublist(pathSegments.length - 2).join('/');
        
        await _supabase.storage
            .from('landing-page-images')
            .remove([filePath]);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return false;
    }
  }

  Future<List<String>> getUploadedImages() async {
    try {
      final response = await _supabase.storage
          .from('landing-page-images')
          .list();

      return response
          .map((file) => _supabase.storage
              .from('landing-page-images')
              .getPublicUrl(file.name))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading uploaded images: $e');
      }
      return [];
    }
  }

  Future<bool> clearCache() async {
    try {
      // Force refresh by updating the timestamp
      await _supabase
          .from('landing_page_content')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', 'main');
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
      return false;
    }
  }

  // Platform-specific image processing
  Future<Uint8List> _processImageForWeb(Uint8List imageBytes, String fileName) async {
    // Web-specific processing
    // Could add client-side image compression, format conversion, etc.
    if (kDebugMode) {
      print('Processing image for web: $fileName (${imageBytes.length} bytes)');
    }
    
    // For web, we might want to ensure images aren't too large
    if (imageBytes.length > 5 * 1024 * 1024) { // 5MB limit
      throw Exception('Image too large. Please select an image smaller than 5MB.');
    }
    
    return imageBytes;
  }

  Future<Uint8List> _processImageForMobile(Uint8List imageBytes, String fileName) async {
    // Mobile-specific processing
    // Could add different compression settings, EXIF data handling, etc.
    if (kDebugMode) {
      print('Processing image for mobile: $fileName (${imageBytes.length} bytes)');
    }
    
    return imageBytes;
  }

  // Helper method to determine MIME type for web uploads
  String? _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  // Enhanced error handling with platform-specific messages
  String _getPlatformSpecificError(dynamic error, String operation) {
    final errorStr = error.toString().toLowerCase();
    
    if (kIsWeb) {
      if (errorStr.contains('413') || errorStr.contains('too large')) {
        return 'File too large for web upload. Please select a smaller image.';
      } else if (errorStr.contains('415') || errorStr.contains('unsupported')) {
        return 'Unsupported file format. Please use JPG, PNG, or GIF.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        return 'Network error. Please check your connection and try again.';
      }
    } else {
      if (errorStr.contains('storage')) {
        return 'Storage error. Please check available space and try again.';
      } else if (errorStr.contains('permission')) {
        return 'Permission denied. Please grant storage access and try again.';
      }
    }
    
    return 'Failed to $operation. Please try again.';
  }

  LandingPageContentModel _getDefaultContent() {
    return LandingPageContentModel(
      id: 'main',
      heroTitle: 'Transform Your Space with HWR Painting Services',
      heroSubtitle: 'Professional painters delivering exceptional results for homes and businesses across Perth',
      heroPrimaryCta: 'Get a Free Quote',
      heroSecondaryCta: 'Schedule an Estimate',
      heroImageUrl: '',
      services: [
        ServiceContent(
          id: 'interior',
          title: 'Interior Painting',
          description: 'Transform your indoor spaces with our professional interior painting services. We use premium paints and expert techniques to deliver stunning results that last.',
          imageUrl: '',
        ),
        ServiceContent(
          id: 'exterior',
          title: 'Exterior Painting',
          description: 'Protect and beautify your property with our weather-resistant exterior painting solutions designed for Perth\'s climate conditions.',
          imageUrl: '',
        ),
        ServiceContent(
          id: 'commercial',
          title: 'Commercial Painting',
          description: 'Professional painting services for offices, retail spaces, and commercial buildings with minimal disruption to your business operations.',
          imageUrl: '',
        ),
        ServiceContent(
          id: 'specialty',
          title: 'Specialty Finishes',
          description: 'Cabinet painting, decorative finishes, and specialty coatings to add unique character and value to your space.',
          imageUrl: '',
        ),
      ],
      portfolio: [
        PortfolioItem(
          id: 'sample1',
          title: 'Modern Home Interior',
          description: 'Complete interior transformation with premium finishes',
          category: 'Interior',
          beforeImageUrl: '',
          afterImageUrl: '',
        ),
        PortfolioItem(
          id: 'sample2',
          title: 'Commercial Office Renovation',
          description: 'Professional workspace upgrade with modern colors',
          category: 'Commercial',
          beforeImageUrl: '',
          afterImageUrl: '',
        ),
      ],
      businessInfo: BusinessInfo(
        name: 'HWR Painting Services',
        address: '123 Swan Street, Perth WA 6000',
        phone: '(08) 9123-4567',
        email: 'info@hwrpainting.com.au',
        hours: 'Mon-Fri: 7AM-6PM, Sat: 8AM-4PM',
      ),
      updatedAt: DateTime.now(),
    );
  }
}
