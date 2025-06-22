# Aplikasi To-Do List CRUD (Flutter + Laravel)

## Deskripsi Aplikasi
Aplikasi **To-Do List** ini merupakan sistem manajemen tugas berbasis **Flutter** sebagai antarmuka pengguna (frontend) dan **Laravel** sebagai backend (REST API). Fitur utama aplikasi ini mencakup:

- Menambahkan tugas dengan judul, prioritas, dan batas waktu (deadline)
- Pencatatan otomatis tanggal dan waktu pembuatan serta pembaruan tugas (**created_at** dan **updated_at**) mengikuti waktu sistem lokal
- Mengedit detail tugas yang telah dibuat
- Menghapus tugas dari daftar
- Menampilkan seluruh tugas dalam tampilan modern berbasis Flutter Card

## Fitur Utama
- **Halaman Utama**: Menampilkan daftar seluruh tugas yang tersimpan
- **Form Tambah/Edit**: Input untuk judul, prioritas, batas waktu, waktu dibuat dan diperbarui
- **Checklist**: Menandai tugas sebagai selesai
- **Pencarian**: Mencari tugas berdasarkan kata kunci (*fitur tambahan*)

## Struktur Database
Menggunakan database **MySQL** dengan tabel `tasks`, yang terdiri dari kolom:
- `id`
- `title`
- `priority` (low, medium, high)
- `due_date`
- `is_done`
- `created_at`
- `updated_at`

## API (Laravel)
API terletak di direktori `/api/` dengan daftar endpoint sebagai berikut:
- `GET /api/tasks` — Mengambil seluruh data tugas
- `POST /api/tasks` — Menambahkan data tugas baru
- `PUT /api/tasks/{id}` — Memperbarui data tugas berdasarkan ID
- `DELETE /api/tasks/{id}` — Menghapus tugas berdasarkan ID

## Teknologi yang Digunakan
- **Flutter** (versi terbaru)
- **Laravel 10**
- **MySQL**
- **Postman** (untuk pengujian API)
- **Visual Studio Code**
- **Laragon** (sebagai local server)

---

## Panduan Instalasi

### 1. Kloning Repositori
```bash
git clone https://github.com/Ian7672/todolist-flutter-dart-api_laravel-v1
cd laravel
```

### 2. Backend (Laravel)
Masuk ke folder `api/`:
```bash
cd api
composer install
cp .env.example .env
php artisan key:generate
```

Atur konfigurasi database pada file `.env`:
```
DB_DATABASE=todo_app
DB_USERNAME=root
DB_PASSWORD=   # Kosongkan jika tidak menggunakan password
```

Lakukan migrasi database:
```bash
php artisan migrate
php artisan serve
```

### 3. Frontend (Flutter)
Masuk ke direktori aplikasi Flutter (misal: `flutter`):
```bash
cd flutter
flutter pub get
flutter run
```

---

## Menjalankan Aplikasi

1. Jalankan Laravel API dengan perintah:
   ```bash
   php artisan serve
   ```
2. Jalankan aplikasi Flutter dengan perintah:
   ```bash
   flutter run
   ```

---

## Demo Aplikasi

[Link Demo Aplikasi](https://github.com/user-attachments/assets/9659b1c1-5e24-4345-85f0-36b9377781da)

---

## 👨‍💻 Developer

Dikembangkan oleh **Ian7672** - [GitHub Profile](https://github.com/Ian7672)

---

© 2025 todolist-flutter-dart-api_laravel-v1. All rights reserved.
