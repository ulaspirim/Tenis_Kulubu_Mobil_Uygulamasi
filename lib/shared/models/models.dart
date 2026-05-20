import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────
// KULLANICI MODELİ
// ─────────────────────────────────────────
class UserModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String membershipType;
  final String membershipStatus;
  final DateTime membershipExpiry;
  final String membershipNumber;
  final DateTime createdAt;
  final bool isAdmin;
  final bool isFirstLogin;
  final List<String> fcmTokens;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.membershipType,
    required this.membershipStatus,
    required this.membershipExpiry,
    required this.membershipNumber,
    required this.createdAt,
    this.isAdmin = false,
    this.fcmTokens = const [],
    this.isFirstLogin = true,
  });

  String get fullName => '$firstName $lastName';

  int get daysUntilExpiry =>
      membershipExpiry.difference(DateTime.now()).inDays;

  bool get isMembershipActive => membershipStatus == 'active';
  bool get isMembershipExpiringSoon => daysUntilExpiry <= 30;
  bool get isMembershipCritical => daysUntilExpiry <= 7;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      membershipType: data['membershipType'] ?? 'standard',
      membershipStatus: data['membershipStatus'] ?? 'active',
      membershipExpiry: (data['membershipExpiry'] as Timestamp).toDate(),
      membershipNumber: data['membershipNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      isFirstLogin: data['isFirstLogin'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'membershipType': membershipType,
    'membershipStatus': membershipStatus,
    'membershipExpiry': Timestamp.fromDate(membershipExpiry),
    'membershipNumber': membershipNumber,
    'createdAt': Timestamp.fromDate(createdAt),
    'isAdmin': isAdmin,
    'fcmTokens': fcmTokens,
    'isFirstLogin': isFirstLogin,
  };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
    String? membershipType,
    String? membershipStatus,
    DateTime? membershipExpiry,
    bool? isFirstLogin,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      membershipType: membershipType ?? this.membershipType,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      membershipNumber: membershipNumber,
      createdAt: createdAt,
      isAdmin: isAdmin,
      fcmTokens: fcmTokens,
      
    );
  }

  @override
  List<Object?> get props => [id, email, membershipStatus];
}

// ─────────────────────────────────────────
// TESİS MODELİ
// ─────────────────────────────────────────
class FacilityModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? description;
  final String? imageUrl;
  final int capacity;
  final bool isActive;
  final String openTime;
  final String closeTime;
  final List<String> amenities;

  const FacilityModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.imageUrl,
    required this.capacity,
    this.isActive = true,
    required this.openTime,
    required this.closeTime,
    this.amenities = const [],
  });

  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      capacity: data['capacity'] ?? 1,
      isActive: data['isActive'] ?? true,
      openTime: data['openTime'] ?? '07:00',
      closeTime: data['closeTime'] ?? '23:00',
      amenities: List<String>.from(data['amenities'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'description': description,
    'imageUrl': imageUrl,
    'capacity': capacity,
    'isActive': isActive,
    'openTime': openTime,
    'closeTime': closeTime,
    'amenities': amenities,
  };

  @override
  List<Object?> get props => [id, type, isActive];
}

// ─────────────────────────────────────────
// REZERVASYON MODELİ
// ─────────────────────────────────────────
class ReservationModel extends Equatable {
  final String id;
  final String userId;
  final String userFullName;
  final String facilityId;
  final String facilityName;
  final String facilityType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final int? playerCount;
  final List<String> guestNames;

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.facilityId,
    required this.facilityName,
    required this.facilityType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.playerCount,
    this.guestNames = const [],
  });

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isPast => date.isBefore(DateTime.now());

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userFullName: data['userFullName'] ?? '',
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      facilityType: data['facilityType'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      status: data['status'] ?? 'active',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      playerCount: data['playerCount'],
      guestNames: List<String>.from(data['guestNames'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userFullName': userFullName,
    'facilityId': facilityId,
    'facilityName': facilityName,
    'facilityType': facilityType,
    'date': Timestamp.fromDate(date),
    'startTime': startTime,
    'endTime': endTime,
    'status': status,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'playerCount': playerCount,
    'guestNames': guestNames,
  };

  @override
  List<Object?> get props => [id, userId, facilityId, date, startTime];
}

// ─────────────────────────────────────────
// DUYURU MODELİ
// ─────────────────────────────────────────
class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? imageUrl;
  final bool isPinned;
  final bool isPublished;
  final DateTime publishedAt;
  final DateTime? eventDate;
  final String? location;
  final String? registrationLink;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.isPinned = false,
    this.isPublished = true,
    required this.publishedAt,
    this.eventDate,
    this.location,
    this.registrationLink,
  });

  bool get isTournament => category == 'tournament';
  bool get isUpcoming =>
      eventDate != null && eventDate!.isAfter(DateTime.now());

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'general',
      imageUrl: data['imageUrl'],
      isPinned: data['isPinned'] ?? false,
      isPublished: data['isPublished'] ?? true,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      eventDate: data['eventDate'] != null
          ? (data['eventDate'] as Timestamp).toDate()
          : null,
      location: data['location'],
      registrationLink: data['registrationLink'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'content': content,
    'category': category,
    'imageUrl': imageUrl,
    'isPinned': isPinned,
    'isPublished': isPublished,
    'publishedAt': Timestamp.fromDate(publishedAt),
    'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
    'location': location,
    'registrationLink': registrationLink,
  };

  @override
  List<Object?> get props => [id, title, publishedAt];
}

// ─────────────────────────────────────────
// MESAJ MODELİ
// ─────────────────────────────────────────
class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String messageType; // 'text', 'image'
  final String? imageUrl;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.messageType = 'text',
    this.imageUrl,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'content': content,
    'sentAt': Timestamp.fromDate(sentAt),
    'isRead': isRead,
    'messageType': messageType,
    'imageUrl': imageUrl,
  };

  @override
  List<Object?> get props => [id, senderId, sentAt];
}
