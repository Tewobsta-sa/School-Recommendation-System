enum AdPlacementType {
  banner,
  popup;

  String toWire() {
    switch (this) {
      case AdPlacementType.banner:
        return 'BANNER';
      case AdPlacementType.popup:
        return 'POPUP';
    }
  }

  static AdPlacementType fromWire(String? v) {
    switch (v) {
      case 'POPUP':
        return AdPlacementType.popup;
      default:
        return AdPlacementType.banner;
    }
  }

  String label() {
    switch (this) {
      case AdPlacementType.banner:
        return 'Banner';
      case AdPlacementType.popup:
        return 'Full-screen Popup';
    }
  }
}

enum AdStatus {
  pendingReview,
  awaitingPayment,
  active,
  rejected,
  expired;

  static AdStatus fromWire(String? v) {
    switch (v) {
      case 'AWAITING_PAYMENT':
        return AdStatus.awaitingPayment;
      case 'ACTIVE':
        return AdStatus.active;
      case 'REJECTED':
        return AdStatus.rejected;
      case 'EXPIRED':
        return AdStatus.expired;
      default:
        return AdStatus.pendingReview;
    }
  }

  String label() {
    switch (this) {
      case AdStatus.pendingReview:
        return 'Pending review';
      case AdStatus.awaitingPayment:
        return 'Awaiting payment';
      case AdStatus.active:
        return 'Active';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.expired:
        return 'Expired';
    }
  }
}

class AdPayment {
  final int id;
  final double amount;
  final String currency;
  final String? status;
  final String? transactionId;

  AdPayment({
    required this.id,
    required this.amount,
    required this.currency,
    this.status,
    this.transactionId,
  });

  factory AdPayment.fromJson(Map<String, dynamic> j) {
    double parseAmount(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return AdPayment(
      id: j['id'] as int,
      amount: parseAmount(j['amount']),
      currency: j['currency'] as String? ?? 'ETB',
      status: j['status'] as String?,
      transactionId: j['transactionId'] as String?,
    );
  }
}

class Advertisement {
  final int id;
  final String companyName;
  final String contactEmail;
  final String contactPhone;
  final String title;
  final String? description;
  final String? imageUrl;
  final String targetUrl;
  final AdPlacementType placementType;
  final int durationDays;
  final AdStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int impressions;
  final int clicks;
  final AdPayment? payment;
  final String? rejectReason;

  Advertisement({
    required this.id,
    required this.companyName,
    required this.contactEmail,
    required this.contactPhone,
    required this.title,
    this.description,
    this.imageUrl,
    required this.targetUrl,
    required this.placementType,
    required this.durationDays,
    required this.status,
    this.startDate,
    this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    this.payment,
    this.rejectReason,
  });

  factory Advertisement.fromJson(Map<String, dynamic> j) {
    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    AdPayment? payment;
    if (j['payment'] is Map) {
      payment = AdPayment.fromJson(
        (j['payment'] as Map).cast<String, dynamic>(),
      );
    }

    return Advertisement(
      id: j['id'] as int,
      companyName: j['companyName'] as String? ?? '',
      contactEmail: j['contactEmail'] as String? ?? '',
      contactPhone: j['contactPhone'] as String? ?? '',
      title: j['title'] as String,
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      targetUrl: j['targetUrl'] as String,
      placementType: AdPlacementType.fromWire(j['placementType'] as String?),
      durationDays: (j['durationDays'] as num?)?.toInt() ?? 0,
      status: AdStatus.fromWire(j['status'] as String?),
      startDate: parseDt(j['startDate']),
      endDate: parseDt(j['endDate']),
      impressions: (j['impressions'] as num?)?.toInt() ?? 0,
      clicks: (j['clicks'] as num?)?.toInt() ?? 0,
      payment: payment,
      rejectReason: j['rejectReason'] as String?,
    );
  }
}

class AdPricingInfo {
  final Map<String, double> rates;
  final double exampleAmount;

  AdPricingInfo({required this.rates, required this.exampleAmount});

  factory AdPricingInfo.fromJson(Map<String, dynamic> j) {
    final ratesRaw = (j['rates'] as Map?)?.cast<String, dynamic>() ?? {};
    final rates = ratesRaw.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final example = (j['example'] as Map?)?.cast<String, dynamic>() ?? {};
    return AdPricingInfo(
      rates: rates,
      exampleAmount: (example['amountEtb'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdRequestResult {
  final Advertisement advertisement;
  final double amountEtb;
  final double dailyRateEtb;
  final int durationDays;

  AdRequestResult({
    required this.advertisement,
    required this.amountEtb,
    required this.dailyRateEtb,
    required this.durationDays,
  });
}
