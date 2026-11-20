import 'package:intl/intl.dart';

/// Model ringan yang memetakan JSON dari API Django.

class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.phone = '',
    this.city = '',
    this.organizationType = '',
    this.organizationDescription = '',
    this.organizationStatus,
  });

  final int id;
  final String username;
  final String name;

  /// `volunteer`, `organizer`, atau `admin`.
  final String role;
  final String phone;
  final String city;
  final String organizationType;
  final String organizationDescription;
  final String? organizationStatus;

  bool get isVolunteer => role == 'volunteer';
  bool get isOrganizer => role == 'organizer';
  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        username: j['username'] as String,
        name: (j['name'] ?? '') as String,
        role: (j['role'] ?? 'volunteer') as String,
        phone: (j['phone_number'] ?? '') as String,
        city: (j['city'] ?? '') as String,
        organizationType: (j['organization_type'] ?? '') as String,
        organizationDescription: (j['organization_description'] ?? '') as String,
        organizationStatus: j['organization_status'] as String?,
      );
}

class Category {
  Category({required this.id, required this.name, this.description = '', this.isActive = true});
  final int id;
  final String name;
  final String description;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: j['name'] as String,
        description: (j['description'] ?? '') as String,
        isActive: (j['is_active'] ?? true) as bool,
      );
}

class Activity {
  Activity({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.tanggalMulai,
    required this.namaLokasi,
    required this.kota,
    required this.kuota,
    required this.sisaKuota,
    required this.status,
    required this.sudahLewat,
    required this.penyelenggara,
    this.latitude,
    this.longitude,
    this.deskripsi = '',
    this.alamat = '',
    this.isArchived = false,
    this.myRegistrationId,
    this.myRegistrationStatus,
    this.jumlahPendaftar = 0,
    this.pendaftarMenunggu = 0,
    this.bisaCatatDampak = false,
    this.dampak,
  });

  final int id;
  final String nama;
  final String kategori;
  final DateTime tanggalMulai;
  final String namaLokasi;
  final String kota;
  final int kuota;
  final int sisaKuota;
  final String status;
  final bool sudahLewat;
  final String penyelenggara;
  final double? latitude;
  final double? longitude;
  final String deskripsi;
  final String alamat;
  final bool isArchived;
  final String? myRegistrationId;
  final String? myRegistrationStatus;
  final int jumlahPendaftar;
  final int pendaftarMenunggu;
  final bool bisaCatatDampak;
  final Map<String, dynamic>? dampak;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory Activity.fromJson(Map<String, dynamic> j) {
    final reg = j['my_registration'] as Map<String, dynamic>?;
    return Activity(
      id: j['id'] as int,
      nama: j['nama'] as String,
      kategori: ((j['kategori'] as Map)['name'] ?? '') as String,
      tanggalMulai: DateTime.parse(j['tanggal_mulai'] as String).toLocal(),
      namaLokasi: (j['nama_lokasi'] ?? '') as String,
      kota: (j['kota'] ?? '') as String,
      kuota: j['kuota'] as int,
      sisaKuota: j['sisa_kuota'] as int,
      status: (j['status_publikasi'] ?? 'published') as String,
      sudahLewat: (j['sudah_lewat'] ?? false) as bool,
      penyelenggara: (j['penyelenggara'] ?? '') as String,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      deskripsi: (j['deskripsi'] ?? '') as String,
      alamat: (j['alamat'] ?? '') as String,
      isArchived: (j['is_archived'] ?? false) as bool,
      myRegistrationId: reg?['id'] as String?,
      myRegistrationStatus: reg?['status'] as String?,
      jumlahPendaftar: (j['jumlah_pendaftar'] ?? 0) as int,
      pendaftarMenunggu: (j['pendaftar_menunggu'] ?? 0) as int,
      bisaCatatDampak: (j['bisa_catat_dampak'] ?? false) as bool,
      dampak: j['dampak'] as Map<String, dynamic>?,
    );
  }
}

class Registration {
  Registration({
    required this.id,
    required this.kegiatanId,
    required this.kegiatanNama,
    required this.tanggalMulai,
    required this.lokasi,
    required this.status,
    required this.statusLabel,
    required this.motivasi,
    required this.kontakDarurat,
    required this.pengalaman,
    required this.kebutuhanKhusus,
    required this.pesanPenyelenggara,
    required this.bisaDiubah,
    required this.bisaDibatalkan,
    required this.alasanPembatalan,
    required this.jamKontribusi,
    required this.catatanDampak,
    required this.refleksi,
    required this.masukRiwayat,
    this.namaRelawan,
  });

  final String id;
  final int kegiatanId;
  final String kegiatanNama;
  final DateTime tanggalMulai;
  final String lokasi;
  final String status;
  final String statusLabel;
  final String motivasi;
  final String kontakDarurat;
  final String pengalaman;
  final String kebutuhanKhusus;
  final String pesanPenyelenggara;
  final bool bisaDiubah;
  final bool bisaDibatalkan;
  final String alasanPembatalan;
  final int jamKontribusi;
  final String catatanDampak;
  final String refleksi;
  final bool masukRiwayat;
  final String? namaRelawan;

  factory Registration.fromJson(Map<String, dynamic> j) {
    final k = j['kegiatan'] as Map<String, dynamic>;
    return Registration(
      id: j['id'] as String,
      kegiatanId: k['id'] as int,
      kegiatanNama: k['nama'] as String,
      tanggalMulai: DateTime.parse(k['tanggal_mulai'] as String).toLocal(),
      lokasi: [k['nama_lokasi'], k['kota']]
          .where((e) => e != null && '$e'.isNotEmpty)
          .join(', '),
      status: j['status'] as String,
      statusLabel: j['status_label'] as String,
      motivasi: (j['motivasi'] ?? '') as String,
      kontakDarurat: (j['kontak_darurat'] ?? '') as String,
      pengalaman: (j['pengalaman_relevan'] ?? '') as String,
      kebutuhanKhusus: (j['kebutuhan_khusus'] ?? '') as String,
      pesanPenyelenggara: (j['pesan_penyelenggara'] ?? '') as String,
      bisaDiubah: (j['bisa_diubah'] ?? false) as bool,
      bisaDibatalkan: (j['bisa_dibatalkan'] ?? false) as bool,
      alasanPembatalan: (j['alasan_pembatalan'] ?? '') as String,
      jamKontribusi: (j['jam_kontribusi'] ?? 0) as int,
      catatanDampak: (j['catatan_dampak'] ?? '') as String,
      refleksi: (j['refleksi_relawan'] ?? '') as String,
      masukRiwayat: (j['masuk_riwayat'] ?? false) as bool,
      namaRelawan: (j['relawan'] as Map<String, dynamic>?)?['nama'] as String?,
    );
  }
}

// ---------------------------------------------------------------- format
final _dateFmt = DateFormat('EEE, d MMM yyyy · HH.mm');

String formatDate(DateTime d) => _dateFmt.format(d);
