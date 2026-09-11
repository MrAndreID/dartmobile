import '../../../core/error/failure.dart';

/// Menerjemahkan error apa pun menjadi pesan yang ramah untuk ditampilkan di UI.
///
/// Repository menjamin hanya [Failure] yang keluar ke lapisan presentation,
/// sehingga pesan [Failure.message] sudah aman ditampilkan. Untuk error tak
/// terduga (mis. bug pemrograman), kita jatuh ke pesan generik agar detail
/// teknis tidak bocor ke pengguna.
String messageForError(Object error) {
  if (error is Failure) return error.message;
  return 'Terjadi kesalahan yang tidak terduga.';
}
