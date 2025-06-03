class FormModel {
  final String namaLengkap;
  final String nik;
  final String phoneNumber;
  final String tanggalLahir;
  final String alamat;
  final String gender;
  final String agama;
  final String jobs;
  final String fotoProfil;
  final int userId;

  FormModel({
    required this.namaLengkap,
    required this.nik,
    required this.phoneNumber,
    required this.tanggalLahir,
    required this.alamat,
    required this.gender,
    required this.agama,
    required this.jobs,
    required this.fotoProfil,
    required this.userId,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      namaLengkap: json['namaLengkap'] ?? '',
      nik: json['nik'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      tanggalLahir: json['tanggalLahir'] ?? '',
      alamat: json['alamat'] ?? '',
      gender: json['gender'] ?? '',
      agama: json['agama'] ?? '',
      jobs: json['jobs'] ?? '',
      fotoProfil: json['fotoProfil'] ?? '',
      userId: json['userId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'namaLengkap': namaLengkap,
        'nik': nik,
        'phoneNumber': phoneNumber,
        'tanggalLahir': tanggalLahir,
        'alamat': alamat,
        'gender': gender,
        'agama': agama,
        'jobs': jobs,
        'fotoProfil': fotoProfil,
      };
}
