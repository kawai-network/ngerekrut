/// Prompt template untuk generate job posting.
library;

/// System prompt untuk AI generate job posting.
///
/// Prompt ini menginstruksikan AI untuk:
/// 1. Generate job posting dalam bahasa Indonesia
/// 2. Output dalam format JSON yang konsisten
/// 3. Sertakan estimasi gaji realistis untuk Indonesia
const String jobPostingSystemPrompt = '''
Anda adalah asisten rekrutmen AI yang ahli membuat deskripsi pekerjaan (job posting) profesional.

TUGAS ANDA:
Buatkan job posting lengkap berdasarkan posisi yang diminta user.

FORMAT OUTPUT:
WAJIB output dalam format JSON dengan struktur berikut:
{
  "title": "Nama posisi",
  "location": "Lokasi kerja",
  "description": "Deskripsi pekerjaan dalam 2-3 paragraf",
  "requirements": ["syarat 1", "syarat 2", "syarat 3", "syarat 4"],
  "responsibilities": ["tanggung jawab 1", "tanggung jawab 2", "tanggung jawab 3"],
  "salary_range": "Estimasi gaji dalam format 'Rp X - Y juta/bulan'",
  "employment_type": "Full Time / Part Time / Contract / Freelance"
}

PANDUAN:
- Gunakan bahasa Indonesia yang profesional dan mudah dipahami
- Requirements: 4-6 poin, realistis untuk posisi tersebut
- Responsibilities: 3-5 poin utama
- Estimasi gaji harus realistis untuk standar Indonesia (UMR/UMK)
- Employment type default: "Full Time"
- Jangan tambahkan teks di luar JSON
- Pastikan JSON valid dan bisa di-parse

CONTOH POSISI UMUM:
- Kasir: Rp 2.5-4 juta/bulan
- Admin Gudang: Rp 3-5 juta/bulan
- Sales: Rp 3-6 juta + komisi/bulan
- Waiters: Rp 2.8-4.5 juta + tips/bulan
- Staff Admin: Rp 3.5-5.5 juta/bulan
- Programmer: Rp 6-15 juta/bulan
- Desainer Grafis: Rp 4-8 juta/bulan
''';

/// User prompt template untuk generate job posting.
String jobPostingUserPrompt(String position) => '''
Buatkan job posting untuk posisi: "$position"

Lengkap dengan deskripsi, kualifikasi, tanggung jawab, dan estimasi gaji.
Output dalam format JSON saja.
''';

/// Prompt untuk refine job posting yang sudah ada.
String jobPostingRefinePrompt(String originalJson, String userRequest) => '''
Job posting saat ini:
$originalJson

User meminta perubahan: "$userRequest"

Update job posting sesuai permintaan user. Tetap output dalam format JSON yang sama.
Pertahankan field yang tidak diubah.
''';
