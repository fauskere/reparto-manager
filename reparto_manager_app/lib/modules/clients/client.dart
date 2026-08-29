class Client {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String address;
  final String nickname;
  final double balance;
  final bool isOpenContinuous;
  final String lastVisitDate;
  final String lastVisitStatus;
  final String type; // 'normal', 'especial', 'revendedor'
  final Map<String, double> customPrices; // Map de productId_variantName -> precio personalizado
  final String? groupId;
  final bool hidden;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    this.nickname = '',
    this.balance = 0.0,
    this.isOpenContinuous = false,
    this.lastVisitDate = '',
    this.lastVisitStatus = '',
    this.type = 'normal',
    this.customPrices = const {},
    this.groupId,
    this.hidden = false,
  });

  factory Client.fromMap(Map<String, dynamic> data, String documentId) {
    Map<String, double> parsedPrices = {};
    if (data['customPrices'] != null) {
      (data['customPrices'] as Map<dynamic, dynamic>).forEach((key, val) {
        parsedPrices[key.toString()] = (val as num).toDouble();
      });
    }

    return Client(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      nickname: data['nickname'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      isOpenContinuous: data['isOpenContinuous'] ?? false,
      lastVisitDate: data['lastVisitDate'] ?? '',
      lastVisitStatus: data['lastVisitStatus'] ?? '',
      type: data['type'] ?? 'normal',
      customPrices: parsedPrices,
      groupId: data['groupId'],
      hidden: data['hidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'city': city,
      'address': address,
      'nickname': nickname,
      'balance': balance,
      'isOpenContinuous': isOpenContinuous,
      'lastVisitDate': lastVisitDate,
      'lastVisitStatus': lastVisitStatus,
      'type': type,
      'customPrices': customPrices,
      'groupId': groupId,
      'hidden': hidden,
    };
  }
}
