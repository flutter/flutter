class LandingPageContentModel {
  final String id;
  final String heroTitle;
  final String heroSubtitle;
  final String heroPrimaryCta;
  final String heroSecondaryCta;
  final String heroImageUrl;
  final List<ServiceContent> services;
  final List<PortfolioItem> portfolio;
  final BusinessInfo businessInfo;
  final DateTime updatedAt;

  LandingPageContentModel({
    required this.id,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroPrimaryCta,
    required this.heroSecondaryCta,
    required this.heroImageUrl,
    required this.services,
    required this.portfolio,
    required this.businessInfo,
    required this.updatedAt,
  });

  factory LandingPageContentModel.fromJson(Map<String, dynamic> json) {
    return LandingPageContentModel(
      id: json['id'] ?? '',
      heroTitle: json['hero_title'] ?? '',
      heroSubtitle: json['hero_subtitle'] ?? '',
      heroPrimaryCta: json['hero_primary_cta'] ?? '',
      heroSecondaryCta: json['hero_secondary_cta'] ?? '',
      heroImageUrl: json['hero_image_url'] ?? '',
      services: (json['services'] as List<dynamic>?)
          ?.map((service) => ServiceContent.fromJson(service))
          .toList() ?? [],
      portfolio: (json['portfolio'] as List<dynamic>?)
          ?.map((item) => PortfolioItem.fromJson(item))
          .toList() ?? [],
      businessInfo: BusinessInfo.fromJson(json['business_info'] ?? {}),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hero_title': heroTitle,
      'hero_subtitle': heroSubtitle,
      'hero_primary_cta': heroPrimaryCta,
      'hero_secondary_cta': heroSecondaryCta,
      'hero_image_url': heroImageUrl,
      'services': services.map((service) => service.toJson()).toList(),
      'portfolio': portfolio.map((item) => item.toJson()).toList(),
      'business_info': businessInfo.toJson(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LandingPageContentModel copyWith({
    String? id,
    String? heroTitle,
    String? heroSubtitle,
    String? heroPrimaryCta,
    String? heroSecondaryCta,
    String? heroImageUrl,
    List<ServiceContent>? services,
    List<PortfolioItem>? portfolio,
    BusinessInfo? businessInfo,
    DateTime? updatedAt,
  }) {
    return LandingPageContentModel(
      id: id ?? this.id,
      heroTitle: heroTitle ?? this.heroTitle,
      heroSubtitle: heroSubtitle ?? this.heroSubtitle,
      heroPrimaryCta: heroPrimaryCta ?? this.heroPrimaryCta,
      heroSecondaryCta: heroSecondaryCta ?? this.heroSecondaryCta,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      services: services ?? this.services,
      portfolio: portfolio ?? this.portfolio,
      businessInfo: businessInfo ?? this.businessInfo,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ServiceContent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  ServiceContent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  factory ServiceContent.fromJson(Map<String, dynamic> json) {
    return ServiceContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String beforeImageUrl;
  final String afterImageUrl;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      beforeImageUrl: json['before_image_url'] ?? '',
      afterImageUrl: json['after_image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'before_image_url': beforeImageUrl,
      'after_image_url': afterImageUrl,
    };
  }
}

class BusinessInfo {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String hours;

  BusinessInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.hours,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      hours: json['hours'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'hours': hours,
    };
  }
}
