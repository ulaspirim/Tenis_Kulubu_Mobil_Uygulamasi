import 'package:cloud_firestore/cloud_firestore.dart'; 

enum BookingStatus { pending, confirmed, cancelled, completed }

class CoachBookingModel {
  final String id;
  final String coachId;
  final String coachName;
  final String userId;
  final String userName;
  final DateTime date;
  final String timeSlot;        // "10:00"
  final double price;
  final BookingStatus status;
  final String? note;           // Kullanıcının antrenöre notu

  CoachBookingModel({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.userId,
    required this.userName,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    this.note,
  });

  factory CoachBookingModel.fromMap(Map<String, dynamic> map, String id) {
    return CoachBookingModel(
      id: id,
      coachId: map['coachId'],
      coachName: map['coachName'],
      userId: map['userId'],
      userName: map['userName'],
      date: map['date'] is Timestamp
        ? (map['date'] as Timestamp).toDate()
        : DateTime.now(),
      timeSlot: map['timeSlot'],
      price: (map['price']).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'coachName': coachName,
      'userId': userId,
      'userName': userName,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot,
      'price': price,
      'status': status.name,
      'note': note,
    };
  }
}