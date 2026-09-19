import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darkverse/theme/app_theme.dart';

class FakeIdentityPage extends StatefulWidget {
  const FakeIdentityPage({super.key});

  @override
  State<FakeIdentityPage> createState() => _FakeIdentityPageState();
}

class _FakeIdentityPageState extends State<FakeIdentityPage> {
  Map<String, String>? _identity;
  bool _isMale = true;

  final List<String> _maleNames = [
    'Budi Santoso', 'Agus Prasetyo', 'Eko Widodo', 'Fajar Nugroho',
    'Hendra Kurniawan', 'Irwan Susanto', 'Joko Purnomo', 'Krisna Wijaya',
    'Lukman Hakim', 'Muhammad Fauzi', 'Nanda Saputra', 'Oka Dharma',
    'Putu Ariana', 'Rizky Ramadhan', 'Sigit Hartono', 'Taufiq Rahman',
    'Umar Dani', 'Victor Salim', 'Wahyu Firmansyah', 'Yoga Pratama',
    'Zaki Maulana', 'Arif Hidayat', 'Bagas Wicaksono', 'Cahyo Setiawan',
    'Dony Kurniawan', 'Fikri Alamsyah', 'Galih Prayoga', 'Hamid Saiful',
  ];

  final List<String> _femaleNames = [
    'Siti Rahayu', 'Dewi Lestari', 'Rina Wati', 'Putri Handayani',
    'Nurul Aini', 'Maya Sari', 'Lestari Wulandari', 'Kartika Dewi',
    'Julia Permata', 'Indah Pratiwi', 'Hani Susilawati', 'Fitri Anggraeni',
    'Endang Wahyuni', 'Dian Ayu', 'Citra Nurhaliza', 'Bunga Citra',
    'Anita Rahma', 'Azzahra Putri', 'Bella Safira', 'Clara Amelia',
    'Dara Puspita', 'Elisa Nanda', 'Farida Hanum', 'Gita Swara',
  ];

  final List<String> _cities = ['Jakarta', 'Surabaya', 'Bandung', 'Medan', 'Semarang', 'Makassar', 'Palembang', 'Tangerang', 'Depok', 'Bekasi', 'Yogyakarta', 'Denpasar', 'Malang', 'Bogor', 'Pekanbaru', 'Banjarmasin', 'Padang', 'Pontianak', 'Balikpapan', 'Samarinda'];

  final List<String> _provinces = ['DKI Jakarta', 'Jawa Timur', 'Jawa Barat', 'Sumatera Utara', 'Jawa Tengah', 'Sulawesi Selatan', 'Sumatera Selatan', 'Banten', 'Jawa Barat', 'Jawa Barat', 'DI Yogyakarta', 'Bali', 'Jawa Timur', 'Jawa Barat', 'Riau', 'Kalimantan Selatan', 'Sumatera Barat', 'Kalimantan Barat', 'Kalimantan Timur', 'Kalimantan Timur'];

  final List<String> _jobs = ['Software Developer', 'Desainer Grafis', 'Guru', 'Dokter', 'Akuntan', 'Marketing Manager', 'Data Analyst', 'Content Creator', 'Fotografer', 'Konsultan IT', 'Pengusaha', 'Arsitek', 'Perawat', 'Jurnalis', 'Project Manager'];

  final List<String> _streetNames = ['Jl. Mawar', 'Jl. Melati', 'Jl. Anggrek', 'Jl. Sudirman', 'Jl. Diponegoro', 'Jl. Merdeka', 'Jl. Pahlawan', 'Jl. Pemuda', 'Jl. Kebangsaan', 'Jl. Setia Budi', 'Jl. Ahmad Yani'];

  void _generate() {
    final rng = Random();
    final names = _isMale ? _maleNames : _femaleNames;
    final name = names[rng.nextInt(names.length)];
    final cityIdx = rng.nextInt(_cities.length);
    final city = _cities[cityIdx];
    final province = _provinces[cityIdx];
    final year = 70 + rng.nextInt(35);
    final month = rng.nextInt(12) + 1;
    final day = rng.nextInt(28) + 1;
    final nik = '${3100 + rng.nextInt(9900)}${_isMale ? day.toString().padLeft(2, '0') : (day + 40).toString()}${month.toString().padLeft(2, '0')}${year.toString().padLeft(2, '0')}${rng.nextInt(9000) + 1000}';
    final prefixes = ['0812', '0813', '0821', '0856', '0857', '0878', '0895'];
    final prefix = prefixes[rng.nextInt(prefixes.length)];
    final phone = '$prefix${rng.nextInt(90000000) + 10000000}';
    final nameParts = name.toLowerCase().replaceAll(' ', '.');
    final domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'];
    final email = '$nameParts${rng.nextInt(999)}@${domains[rng.nextInt(domains.length)]}';
    final street = _streetNames[rng.nextInt(_streetNames.length)];
    final no = rng.nextInt(200) + 1;
    final rt = rng.nextInt(20) + 1;
    final rw = rng.nextInt(10) + 1;
    final kode_pos = '${10000 + rng.nextInt(89999)}';
    final bloods = ['A', 'B', 'AB', 'O'];
    final blood = bloods[rng.nextInt(bloods.length)];

    setState(() {
      _identity = {
        'Nama Lengkap': name,
        'Jenis Kelamin': _isMale ? 'Laki-laki ♂' : 'Perempuan ♀',
        'NIK': nik,
        'Tanggal Lahir': '$day/${month.toString().padLeft(2, '0')}/${1950 + year - 70}',
        'Tempat Lahir': city,
        'Golongan Darah': blood,
        'Alamat': '$street No. $no, RT $rt/RW $rw',
        'Kota': city,
        'Provinsi': province,
        'Kode Pos': kode_pos,
        'Nomor Telepon': phone,
        'Email': email,
        'Pekerjaan': _jobs[rng.nextInt(_jobs.length)],
        'Status': rng.nextBool() ? 'Belum Menikah' : 'Menikah',
        'Agama': ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'][rng.nextInt(6)],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("FAKE IDENTITY", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.accentCardDecor(AppTheme.gold),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.gold, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text("Hanya untuk keperluan testing, form dummy, dan pengembangan aplikasi. Jangan disalahgunakan!", style: AppTheme.bodyM),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Gender Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMale = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isMale ? AppTheme.lavender.withValues(alpha: 0.2) : AppTheme.bgCard,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTheme.radiusM)),
                        border: Border.all(color: _isMale ? AppTheme.lavender.withValues(alpha: 0.5) : AppTheme.borderSubtle),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("♂", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text("Laki-laki", style: AppTheme.headingS.copyWith(color: _isMale ? AppTheme.textPrimary : AppTheme.textMuted)),
                      ]),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMale = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isMale ? AppTheme.lavender.withValues(alpha: 0.2) : AppTheme.bgCard,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppTheme.radiusM)),
                        border: Border.all(color: !_isMale ? AppTheme.lavender.withValues(alpha: 0.5) : AppTheme.borderSubtle),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("♀", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text("Perempuan", style: AppTheme.headingS.copyWith(color: !_isMale ? AppTheme.textPrimary : AppTheme.textMuted)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _generate,
                style: AppTheme.primaryButton(AppTheme.lavender),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("GENERATE IDENTITAS", style: AppTheme.headingS),
                ]),
              ),
            ),

            if (_identity != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecor(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("IDENTITAS PALSU", style: AppTheme.label.copyWith(color: AppTheme.lavender)),
                        IconButton(
                          onPressed: () {
                            final text = _identity!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text("Semua data disalin!"), backgroundColor: AppTheme.lavender, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS))),
                            );
                          },
                          icon: const Icon(Icons.copy_all, color: AppTheme.lavender),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    ..._identity!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 120, child: Text(entry.key, style: AppTheme.caption)),
                          Text(": ", style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted)),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Clipboard.setData(ClipboardData(text: entry.value)),
                              child: Text(entry.value, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text("Tap pada nilai untuk menyalin individual", style: AppTheme.caption)),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
