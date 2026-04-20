class Cities {
  Cities._();

  static const suggestions = <String>[
    'Bengaluru, Karnataka',
    'Mysuru, Karnataka',
    'Mangaluru, Karnataka',
    'Hubballi, Karnataka',
    'Chennai, Tamil Nadu',
    'Coimbatore, Tamil Nadu',
    'Madurai, Tamil Nadu',
    'Hyderabad, Telangana',
    'Warangal, Telangana',
    'Mumbai, Maharashtra',
    'Pune, Maharashtra',
    'Nagpur, Maharashtra',
    'Delhi, Delhi',
    'Gurugram, Haryana',
    'Noida, Uttar Pradesh',
    'Lucknow, Uttar Pradesh',
    'Kolkata, West Bengal',
    'Ahmedabad, Gujarat',
    'Surat, Gujarat',
    'Jaipur, Rajasthan',
    'Kochi, Kerala',
    'Thiruvananthapuram, Kerala',
    'Bhubaneswar, Odisha',
    'Chandigarh, Chandigarh',
    'Indore, Madhya Pradesh',
    'Bhopal, Madhya Pradesh',
    'Patna, Bihar',
    'Guwahati, Assam',
    'Visakhapatnam, Andhra Pradesh',
    'Vijayawada, Andhra Pradesh',
  ];

  static List<String> search(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase().trim();
    return suggestions
        .where((c) => c.toLowerCase().contains(q))
        .take(6)
        .toList();
  }
}

class Causes {
  Causes._();

  static const options = <String>[
    'Accident',
    'Surgery',
    'Anemia',
    'Thalassemia',
    'Childbirth',
    'Cancer Treatment',
    'Other',
  ];
}
