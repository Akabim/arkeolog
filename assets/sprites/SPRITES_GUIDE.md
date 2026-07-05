# Panduan Aset Gambar (Sprite Guide) - Arkeolog Gembul

Gunakan panduan ini sebagai referensi ukuran dan nama file PNG yang perlu Anda gambar untuk menggantikan gambar prosedural bawaan. Proyek ini didesain menggunakan basis grid persegi **$80 \times 80$** piksel.

## 📂 Lokasi Folder Aset
Letakkan seluruh file PNG buatan Anda di folder:
👉 **`res://assets/sprites/`**

Sistem pembuat tekstur otomatis (`texture_baker.gd`) akan mendeteksi keberadaan file PNG ini secara otomatis saat game dijalankan. Jika ada file gambar yang belum Anda buat, game akan secara otomatis memakai gambar prosedural (vektor) sebagai cadangan (*fallback*).

---

## 🎨 Daftar Kebutuhan Aset Gambar (Daftar PNG)

| Nama File PNG | Ukuran Rekomendasi (Piksel) | Deskripsi Objek |
| :--- | :---: | :--- |
| **`player.png`** | $80 \times 80$ | Karakter Arkeolog imut bulat (Chiikawa-like). Karakter akan otomatis melakukan gerakan memantul (*squash/stretch*) saat berjalan. |
| **`shrub.png`** | $80 \times 80$ | Semak rintangan yang bisa dihancurkan. |
| **`tree.png`** | $64 \times 96$ | Pohon lebat kuno. Memiliki kedalaman (Y-sorting), karakter bisa berjalan di belakang daunnya. |
| **`dirt_mound.png`** | $64 \times 48$ | Gundukan tanah situs ekskavasi. |
| **`torch_off.png`** | $24 \times 40$ | Obor kuil dalam kondisi mati/belum menyala. |
| **`torch_on1.png`** | $24 \times 40$ | Frame animasi 1 obor menyala (api condong ke satu arah). |
| **`torch_on2.png`** | $24 \times 40$ | Frame animasi 2 obor menyala (api condong ke arah lain untuk flicker). |

### 🪨 Batu Prasasti (Stone Blocks)
Ini adalah batu yang didorong pemain setelah dibersihkan. Pastikan ukiran aksaranya terlihat jelas dan berwarna emas/kontras:

*   **`stone_ha.png`** ($40 \times 40$) - Batu Prasasti dengan Aksara **HA**
*   **`stone_na.png`** ($40 \times 40$) - Batu Prasasti dengan Aksara **NA**
*   **`stone_ca.png`** ($40 \times 40$) - Batu Prasasti dengan Aksara **CA**
*   **`stone_ra.png`** ($40 \times 40$) - Batu Prasasti dengan Aksara **RA**
*   **`stone_ka.png`** ($40 \times 40$) - Batu Prasasti dengan Aksara **KA**

### ⭕ Soket Prasasti (Sockets)
Soket terbagi menjadi dua kondisi: **`_off`** (belum terisi/tidak aktif) dan **`_on`** (sudah pas terisi batu/aktif menyala):

*   **Aksara HA:** `socket_ha_off.png` & `socket_ha_on.png` ($48 \times 48$)
*   **Aksara NA:** `socket_na_off.png` & `socket_na_on.png` ($48 \times 48$)
*   **Aksara CA:** `socket_ca_off.png` & `socket_ca_on.png` ($48 \times 48$)
*   **Aksara RA:** `socket_ra_off.png` & `socket_ra_on.png` ($48 \times 48$)
*   **Aksara KA:** `socket_ka_off.png` & `socket_ka_on.png` ($48 \times 48$)

---

> [!TIP]
> *   Gunakan latar belakang **transparan (transparent alpha)** saat menyimpan gambar ke format `.png`.
> *   Pertahankan gaya outline tinta hitam tebal (**thick ink outlines**) agar menyatu dengan visual antarmuka buku jurnal dan polaroid kuil.
