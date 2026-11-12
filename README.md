# Modern Offline POS (Point of Sale) Mobile Application

Aplikasi kasir (**Point of Sale / POS**) modern berkinerja tinggi yang dirancang khusus untuk bisnis **Food & Beverage (F&B)** dan **Retail**. Dibangun secara native menggunakan **Flutter** dengan pendekatan arsitektur **Offline-First**, mengintegrasikan mesin database lokal **SQLite** berkecepatan tinggi, state management reaktif **Riverpod**, serta dukungan pencetakan struk termal via **Bluetooth ESC/POS Thermal Printer**.

---

## 1. Project Architecture

### Pola Arsitektur (Feature-First Clean Architecture)
Aplikasi dibangun mengikuti prinsip **Feature-First Clean Architecture** yang memisahkan kode berdasarkan modul bisnis (fitur) dan lapisan tanggung jawab (*layering*):

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (UI Screens, Custom Widgets, Modals, Riverpod Notifiers)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Watches & Dispatches Events
┌──────────────────────────────▼──────────────────────────────┐
│                       Domain Layer                          │
│     (Repository Interfaces, Use Cases, Providers, Models)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Implements & Mediates Data
┌──────────────────────────────▼──────────────────────────────┐
│                        Data Layer                           │
│  (Repository Implementations, Local SQLite Data Sources)    │
└──────────────────────────────┬──────────────────────────────┘
                               │ Direct Query / Transactions
┌──────────────────────────────▼──────────────────────────────┐
│                   Hardware & Local Storage                  │
│   (SQLite Database Engine, ESC/POS Bluetooth Printer)       │
└─────────────────────────────────────────────────────────────┘
```

1. **Presentation Layer**:
   - Berisi tampilan antarmuka (**Screen / Page**), komponen modular (**Widgets**), dan presenter reaktif (**Riverpod Notifiers**).
   - Meminimalkan *business logic* di dalam UI; seluruh kalkulasi didelegasikan ke Notifier atau Domain Layer.
2. **Domain Layer**:
   - Mendefinisikan kontrak repositori (**Abstract Repositories**) dan tipe data bisnis (**Entities / Models**).
   - Independen dari dependensi framework pihak ketiga.
3. **Data Layer**:
   - Implementasi konkret repositori (**Repository Implementation**), pemetaan data (**Table Models / Mappers**), dan akses database langsung (**Local Data Source**).
   - Melakukan transaksi atomik SQL dan pemetaan relasional data.
4. **Core Services**:
   - Layanan umum lintas fitur seperti koneksi hardware printer Bluetooth (`PrinterService`), inisialisasi basis data (`DatabaseHelper`), dan pembenihan data awal (`InitialDataSeeder`).

---

### Struktur Direktori Proyek

```
lib/
├── config/                         # Konfigurasi environment & konstanta global
├── core/
│   ├── data/
│   │   ├── local/
│   │   │   ├── database_helper.dart      # Singleton SQLite engine & migration manager
│   │   │   ├── initial_data_seeder.dart  # Data seeder otomatis (catalog F&B, users, settings)
│   │   │   └── tables.dart               # Definisi skema tabel & nama kolom terpusat
│   │   └── remote/                       # Skalabilitas sinkronisasi API masa depan
│   ├── models/
│   │   └── pos_models.dart               # Domain entities (PosProduct, PosAddon, CartItem, PosTransaction)
│   └── services/
│       └── printer/
│           ├── printer_service.dart      # Low-level ESC/POS bytecode generator & Bluetooth handler
│           └── printer_notifier.dart     # Riverpod state controller hardware printer
├── features/
│   ├── auth/                             # Modul Autentikasi Kasir & Admin
│   │   ├── data/                         # Auth local datasource, User table model, Auth repository impl
│   │   ├── domain/                       # Auth repository contract & Auth providers
│   │   └── presentation/                 # LoginScreen, SignupScreen, AuthNotifier
│   ├── pos/                              # Modul Utama POS / Kasir
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── pos_cart_notifier.dart# Keranjang belanja, kalkulasi subtotal, kuantitas item
│   │       └── screens/
│   │           └── pos_screen.dart       # Katalog grid, Addon modal sheet, Cart drawer, Hold bills
│   ├── checkout/                         # Modul Pembayaran Kasir
│   │   └── presentation/
│   │       └── screens/
│   │           └── checkout_screen.dart  # Ringkasan order, diskon %, nominal, quick cash, change engine
│   ├── receipt/                          # Modul Struk Transaksi Digital & Fisik
│   │   └── presentation/
│   │       └── screens/
│   │           └── receipt_screen.dart   # Pratinjau struk bergaya kertas termal, direct print ESC/POS
│   ├── products/                         # Modul Manajemen Katalog & Inventori
│   │   ├── data/                         # Product local datasource, query category, addon, & stock
│   │   ├── domain/                       # Product repository contract & Providers
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── product_notifiers.dart# Filter kategori, live search, sinkronisasi CRUD
│   │       └── screens/
│   │           ├── add_edit_product_screen.dart # Form tambah/edit produk, upload foto, binding addon
│   │           └── product_management_screen.dart # 3 Tab: Products, Categories, Add-ons
│   ├── transactions/                     # Modul Riwayat Transaksi Penjualan
│   │   ├── data/                         # Transaction local datasource, audit log query, report query
│   │   ├── domain/                       # Transaction repository contract & Providers
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── transaction_notifiers.dart # Filter tanggal, metode bayar, search
│   │       └── screens/
│   │           └── transaction_history_screen.dart # List riwayat pesanan, status offline, invoice preview
│   ├── reports/                          # Modul Laporan Penjualan & Sales Analytics
│   │   └── presentation/
│   │       └── screens/
│   │           └── reports_screen.dart   # KPI metrics, visual revenue bar chart, top 5 selling items
│   ├── settings/                         # Modul Pengaturan Toko & Hardware
│   │   └── presentation/
│   │       └── screens/
│   │           └── settings_screen.dart  # Profil kasir, Bluetooth pairing modal, status printer
│   └── splash/                           # Modul Splash Screen
│       └── presentation/
│           └── screens/
│               └── splash_screen.dart    # Pengecekan sesi & inisialisasi basis data
├── routers/
│   ├── app_router.dart                   # Definisi GoRouter & Custom Page Transitions
│   ├── app_routes.dart                   # Konstanta URI route
│   └── global_navigator.dart             # Global root navigator key
├── theme/
│   └── app_themes.dart                   # Definisi warna, font, style tombol, border, input decoration
└── widgets/                              # Global reusable widgets
    ├── labeled_text_field.dart
    └── loading_state_widget.dart
```

---

## 2. State Management

Aplikasi menggunakan **Riverpod 3 (`flutter_riverpod`)**, menghadirkan pengelolaan state yang *compile-time safe*, reaktif, modular, dan dapat diuji secara independen tanpa ketergantungan pada `BuildContext`.

### Arsitektur Riverpod 3 & Katalog Provider

| Jenis Provider | Komponen | Peran & Tanggung Jawab |
| :--- | :--- | :--- |
| **`NotifierProvider`** | `PosCartNotifier` | Mengelola *lifecycle* keranjang belanja: tambah produk, kurangi kuantitas, hitung total baris item berdasarkan harga produk + akumulasi addon terpilih, reset keranjang, dan restore order dari *Hold Bill*. |
| **`NotifierProvider`** | `PrinterNotifier` | Mengontrol siklus konektivitas Bluetooth printer termal, status scan perangkat, penyimpanan konfigurasi ukuran kertas (58mm/80mm), dan pemanggilan *test ticket*. |
| **`NotifierProvider`** | `AuthNotifier` | Mengatur sesi aktif kasir, login validasi PIN/password lokal, registrasi pengguna baru, dan sign out. |
| **`FutureProvider`** | `productsProvider` | Mengambil katalog produk terkini dari SQLite secara asinkron. Mendukung `ref.invalidate()` saat terjadi transaksi atau perubahan inventori. |
| **`FutureProvider`** | `categoriesProvider` | Mengambil daftar kategori menu aktif beserta jumlah item. |
| **`FutureProvider`** | `reportSummaryProvider` | Menghitung agregat finansial (Gross Revenue, Total Order, Average Ticket, Tax) berdasarkan rentang tanggal terpilih. |
| **`FutureProvider`** | `reportSalesChartProvider` | Mengambil data agregasi penjualan per jam (rentang hari ini) atau per tanggal untuk merender grafik batang. |
| **`StateProvider` / Simple Notifier** | `productSearchQueryProvider` | Menyimpan kata kunci pencarian katalog produk secara *real-time*. |
| **`StateProvider` / Simple Notifier** | `selectedCategoryProvider` | Menyaring produk berdasarkan ID kategori yang sedang aktif diklik. |

---

## 3. Database Table Structure (SQLite Engine)

Aplikasi beroperasi secara penuh **100% Offline-First** menggunakan mesin database **SQLite** yang dioptimalkan dengan indeks performa tinggi dan dukungan `PRAGMA foreign_keys = ON`.

### Spesifikasi Tabel & Kolom

#### 1. Tabel `users`
Menyimpan kredensial kasir dan manajer toko untuk autentikasi offline.
- `id` (TEXT, PK): UUID akun pengguna.
- `username` (TEXT, UNIQUE): Nama pengguna unik untuk login (contoh: `sarah`, `admin`).
- `name` (TEXT): Nama lengkap kasir.
- `email` (TEXT, Nullable): Alamat email.
- `phone` (TEXT, Nullable): Nomor telepon.
- `role` (TEXT): Hak akses (`cashier` atau `admin`).
- `pin_hash` (TEXT): Hash PIN / password kasir.
- `is_active` (INTEGER): Status akun aktif (1) atau nonaktif (0).
- `created_at` (TEXT): Timestamp ISO-8601 pembuatan akun.

#### 2. Tabel `categories`
Menyimpan kelompok kategori menu produk.
- `id` (TEXT, PK): ID kategori (`coffee`, `beverage`, `main`, `bakery`).
- `name` (TEXT): Nama label kategori.
- `icon_name` (TEXT, Nullable): Penanda ikon UI.
- `sort_order` (INTEGER): Urutan tampilan pada filter horizontal.
- `is_active` (INTEGER): Status aktif kategori.

#### 3. Tabel `products`
Menyimpan katalog produk makanan, minuman, dan barang dagangan.
- `id` (TEXT, PK): ID unik produk.
- `category_id` (TEXT, FK -> `categories.id` ON DELETE RESTRICT): Relasi kategori.
- `sku` (TEXT, UNIQUE): Nomor induk barang / barcode unik.
- `name` (TEXT): Nama produk.
- `price` (REAL): Harga jual retail per unit.
- `cost_price` (REAL): Harga pokok penjualan (HPP) per unit.
- `stock` (INTEGER): Jumlah ketersediaan stok fisik saat ini.
- `track_stock` (INTEGER): Saklar pelacakan stok (1 = stok berkurang saat terjual).
- `icon_name` (TEXT, Nullable): Nama icon default sistem.
- `image_path` (TEXT, Nullable): File path lokal foto produk dari kamera/galeri.
- `is_available` (INTEGER): Status ketersediaan menu (1 = tampil, 0 = disembunyikan).
- `created_at` (TEXT) & `updated_at` (TEXT): Timestamp mutasi data.

#### 4. Tabel `addons`
Menyimpan varian topping, ekstra shot, sirup, atau modifikasi menu tambahan.
- `id` (TEXT, PK): ID unik addon.
- `name` (TEXT): Nama varian addon (contoh: *Extra Espresso Shot*, *Oat Milk Upgrade*).
- `price` (REAL): Biaya tambahan yang ditambahkan ke harga produk dasar.
- `stock` (INTEGER): Ketersediaan stok fisik topping secara independen.
- `track_stock` (INTEGER): Saklar pelacakan stok addon.
- `is_active` (INTEGER): Status aktif addon.

#### 5. Tabel `product_addons` (Junction Table)
Menghubungkan relasi *Many-to-Many* antara produk dengan daftar addon yang diizinkan.
- `product_id` (TEXT, FK -> `products.id` ON DELETE CASCADE)
- `addon_id` (TEXT, FK -> `addons.id` ON DELETE CASCADE)
- **Primary Key Komposit**: `(product_id, addon_id)`

#### 6. Tabel `transactions`
Menyimpan entitas master transaksi faktur penjualan kasir.
- `id` (TEXT, PK): ID unik transaksi (contoh: `tx_1700000000000`).
- `receipt_no` (TEXT, UNIQUE): Nomor struk faktur berurutan (contoh: `TRX-20261112-0001`).
- `cashier_id` (TEXT, FK -> `users.id` ON DELETE SET NULL): Kasir penanggung jawab.
- `cashier_name` (TEXT): Nama kasir saat transaksi terjadi.
- `table_no` (TEXT, Nullable): Nomor meja pelanggan (*Dine In*).
- `customer_name` (TEXT, Nullable): Nama pelanggan / tamu.
- `subtotal` (REAL): Total kotor akumulasi seluruh produk dan addon.
- `discount_type` (TEXT): Format diskon (`fixed` atau `percentage`).
- `discount_rate` (REAL): Nilai persen diskon bila berlaku.
- `discount_amount` (REAL): Nominal potongan diskon dalam Rupiah.
- `tax_rate` (REAL): Persentase pajak PB1/PPN (default 10%).
- `tax_amount` (REAL): Nominal pajak terhitung.
- `service_rate` (REAL) & `service_amount` (REAL): Biaya layanan (opsional).
- `grand_total` (REAL): Nilai akhir faktur yang wajib dibayarkan pelanggan.
- `payment_method` (TEXT): Metode pembayaran (`Cash`, `QRIS`, `Debit Card`, `Credit Card`).
- `cash_received` (REAL): Nominal uang tunai yang diterima dari kasir.
- `change_given` (REAL): Nominal uang kembalian yang dihitung otomatis.
- `status` (TEXT): Status pesanan (`completed`, `held`, `cancelled`).
- `notes` (TEXT, Nullable): Catatan pesanan khusus.
- `created_at` (TEXT) & `updated_at` (TEXT): Timestamp transaksi.

#### 7. Tabel `transaction_items`
Menyimpan detail baris produk yang terjual dalam suatu transaksi faktur.
- `id` (TEXT, PK): ID baris transaksi item.
- `transaction_id` (TEXT, FK -> `transactions.id` ON DELETE CASCADE): ID transaksi induk.
- `product_id` (TEXT, FK -> `products.id` ON DELETE SET NULL): Relasi master produk.
- `product_name` (TEXT): Snapshot nama produk pada saat transaksi.
- `unit_price` (REAL): Snapshot harga jual produk saat dibeli.
- `cost_price` (REAL): Snapshot harga HPP produk untuk laporan laba kotor.
- `quantity` (INTEGER): Kuantitas yang dibeli.
- `subtotal` (REAL): Total harga baris item sebelum diskon faktur.
- `notes` (TEXT, Nullable): Catatan khusus per menu.

#### 8. Tabel `transaction_item_addons`
Menyimpan snapshot varian addon yang melekat pada suatu baris item pesanan.
- `id` (TEXT, PK): ID baris addon.
- `transaction_item_id` (TEXT, FK -> `transaction_items.id` ON DELETE CASCADE): ID baris item induk.
- `addon_id` (TEXT, FK -> `addons.id` ON DELETE SET NULL): Master addon.
- `addon_name` (TEXT): Snapshot nama addon.
- `addon_price` (REAL): Snapshot harga satuan addon.
- `quantity` (INTEGER): Kuantitas addon.
- `subtotal` (REAL): Total harga addon.

#### 9. Tabel `inventory_logs`
Buku besar audit mutasi keluar masuk stok (*Stock Card Audit Trail*).
- `id` (TEXT, PK): ID log mutasi.
- `item_type` (TEXT): Tipe item (`product` atau `addon`).
- `item_id` (TEXT): ID barang terkait.
- `quantity_change` (INTEGER): Nilai perubahan kuantitas (negatif untuk penjualan, positif untuk restock).
- `balance_after` (INTEGER): Sisa saldo stok fisik setelah mutasi dicatat.
- `mutation_type` (TEXT): Jenis peristiwa (`sale`, `restock`, `adjustment`).
- `reference_id` (TEXT, Nullable): ID referensi faktur transaksi penjualan.
- `notes` (TEXT, Nullable): Keterangan log mutasi.
- `created_at` (TEXT): Waktu terjadinya mutasi.

#### 10. Tabel `store_settings`
Menyimpan konfigurasi profil bisnis dan format cetak struk kasir.
- `id` (TEXT, PK): ID setelan.
- `store_name` (TEXT): Nama resmi toko / kafe.
- `address` (TEXT): Alamat fisik gerai.
- `phone` (TEXT): Nomor kontak gerai.
- `receipt_header` (TEXT): Kalimat salam pembuka di kepala struk cetak.
- `receipt_footer` (TEXT): Pesan penutup di ekor struk cetak.
- `tax_rate` (REAL): Tarif persentase pajak default.
- `service_rate` (REAL): Tarif persentase layanan default.
- `currency_code` (TEXT): Kode mata uang transaksi (`IDR`).

---

### Integritas Transaksi Atomik (Atomic Transactions)

Setiap proses checkout dieksekusi dalam blok **`db.transaction((txn) async { ... })`** untuk menjamin sifat **ACID (Atomicity, Consistency, Isolation, Durability)**:
1. Penyimpanan header faktur pada `transactions`.
2. Penyimpanan detail pesanan pada `transaction_items` dan `transaction_item_addons`.
3. Pengurangan kuantitas stok produk fisik secara atomik menggunakan klausul SQL `SET stock = MAX(0, stock - ?)`.
4. Pengurangan stok bahan/topping varian pada tabel `addons`.
5. Pencatatan otomatis kartu stok pada `inventory_logs`.

---

## 4. Bonus Features Implemented

Selain memenuhi seluruh kebutuhan layar standar, aplikasi ini dilengkapi berbagai fitur nilai tambah (*bonus features*) kelas komersial:

### 1. Integrasi Hardware Bluetooth Thermal Printer (ESC/POS)
- Terintegrasi langsung dengan pustaka `print_bluetooth_thermal` dan `esc_pos_utils_plus`.
- Menyediakan dialog konfigurasi pemindaian Bluetooth, status *Connecting*, *Connected*, hingga tombol *Disconnect*.
- Pilihan format lebar kertas termal **58mm** dan **80mm**.
- Opsi **Print Test Ticket** untuk memeriksa feed printer dan ketajaman teks.
- Tombol **Print Receipt** langsung dari `ReceiptScreen` yang menghasilkan barcode struk, garis pemisah putus-putus, rincian produk, pajak, kembalian, dan *footer message*.

### 2. Fitur Hold & Restore Bill (Parkir Pesanan)
- Memungkinkan kasir memarkir pesanan aktif seorang pelanggan saat pelanggan tersebut ingin menambah pesanan atau mengambil dompet, sehingga kasir dapat melayani pelanggan antrean berikutnya tanpa kehilangan isi keranjang.
- Dilengkapi badge penghitung pesanan tertahan (*Hold Badge*) pada bar atas kasir.
- Modal daftar pesanan tertahan dengan rincian subtotal, jam simpan, dan tombol sekali sentuh untuk **Restore Cart** atau **Delete Held Order**.

### 3. Quick Cash Shortcuts & Real-time Change Engine
- Tombol otomatis pecahan uang tunai cerdas (*Smart Cash Shortcuts*):
  - Tombol **Uang Pas (Exact)**.
  - Pembulatan ke atas kelipatan Rp 10.000, Rp 20.000, Rp 50.000, dan Rp 100.000 terdekat berdasarkan Grand Total faktur.
- Input manual nominal uang diterima dengan kalkulator kembalian instan (*instant change calculation*).
- Sistem validasi visual: tombol bayar otomatis terkunci (*disabled*) jika nominal uang tunai yang dimasukkan kasir kurang dari total tagihan.

### 4. Multi-level Stock Control & Real-time Depletion
- Indikator status stok langsung pada grid menu kasir:
  - **In Stock**: Badge kuantitas sisa stok normal.
  - **Low Stock Warning**: Label oranye terang saat sisa stok `≤ 5 unit`.
  - **Out of Stock**: Tampilan kartu redup (*disabled opacity*) dengan label merah jelas yang memblokir penambahan ke keranjang untuk mencegah *overselling*.
- Pemotongan kuantitas terjadi serentak untuk produk utama dan stok addon topping.

### 5. Dual-Mode Discount Engine
- Mendukung dua skenario diskon:
  1. **Diskon Persentase**: Preset praktis `10%`, `20%`, atau input persentase kustom.
  2. **Diskon Nominal Tetap (Fixed Amount)**: Preset potongan langsung `Rp 5.000`, `Rp 10.000`, atau nominal bebas.
- Nilai pajak (PB1 10%) secara akurat dihitung dari harga dasar yang telah dikurangi nilai diskon (*taxable subtotal*).

### 6. Visual Sales Analytics & Interactive Revenue Chart
- Dashboard analitik pada tab `Reports` menyajikan kartu ringkasan KPI:
  - **Gross Revenue** (Total Omzet Bersih).
  - **Total Orders** (Jumlah Transaksi Berhasil).
  - **Average Ticket Value** (Rata-rata Nilai Belanja Pelanggan).
  - **Items Sold** (Total Unit Barang Terjual).
- **Interactive Visual Bar Chart**: Grafik batang visual yang merender distribusi omzet penjualan per jam (untuk filter harian) atau tren hari ke hari.
- **Top 5 Best-Selling Items**: Peringkat 5 produk terlaris berdasarkan kuantitas penjualan dan kontribusi omzet.
