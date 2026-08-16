# 📜 MASTER PROJECT CONTEXT & BRAINSTORMING SPECIFICATION
## Project: "Arkeolog Gembul" (Godot 4.6 2D)
> **Untuk AI Planner / Architect (GPT):** Dokumen ini memuat arsitektur teknis lengkap, status implementasi terkini, keputusan game design, aturan engine Godot 4.6, dan daftar backlog fitur yang perlu dirancang secara mendalam.

---

## 🎯 1. Game Overview & MDA Framework

### A. Core Identity
* **Judul:** *Arkeolog Gembul* (Working Title)
* **Engine:** Godot 4.6 (GDScript 2.0 static typing, Mobile / `gl_compatibility` renderer)
* **Resolusi:** FHD `1920 × 1080` (Canvas Items stretch mode)
* **Genre:** 2D Top-Down Cozy Exploration, Excavation & Restoration
* **Target Feeling:** Rileks, memuaskan (tactile & juicy feedback), penuh rasa penasaran arkeologis, visual hand-painted hangat.
* **Referensi Utama:**
  * *Gemporium* (Mekanik pembersihan relik close-up di meja kerja)
  * *Assemble with Care* (Meja kerja restorasi & perakitan puzzle)
  * *Don't Starve* (Gerak player, posisi cangkul/sekop otomatis saat berinteraksi)
  * *A Short Hike* (Eksplorasi alam santai, dialog bersahabat)

### B. MDA Framework (Mechanics, Dynamics, Aesthetics)
* **Mechanics:**
  * *Exploration:* WASD 8-arah, tebas semak dengan sabit (klik / tombol `E`).
  * *Excavation Trigger:* Sekop tanah (hold / klik gundukan) → transisi ke layar meja kerja ekskavasi.
  * *Relic Cleaning:* Mini-game 3 alat (Pahat untuk memecah batu → Kuas untuk menyapu debu tanah → Spray untuk memunculkan aksara emas).
  * *Collection:* Relik bersih menghasilkan kepingan (`FragmentData`) yang masuk otomatis ke `InventoryManager`.
  * *Restoration:* Membawa kepingan ke altar kuno di overworld → mini-game jigsaw assembly (susun kepingan hingga utuh).
* **Dynamics:** Loop penemuan kepingan bertahap (eksplorasi → gali → bersihkan → kumpulkan 3/3 kepingan → susun di altar → level selesai).
* **Aesthetics:** Visual hand-painted bernuansa earthy (tanah, kayu, lumut, batu kuno), audio clink pahat memuaskan, debu tanah tebal, getaran layar taktil.

---

## 👥 2. Tim & Pembagian Peran

```
┌──────────────────────────────────────────────────────────┐
│                   TIM PENGEMBANGAN                       │
├──────────────────────────┬───────────────────────────────┤
│ Abima (Lead / Designer)  │ Prototipe UI Figma, Assembler │
│ Pacar Abima (2D Artist)  │ Hand-painted 2D PNG Assets    │
│ GPT / Claude (Architect) │ GDD, Brainstorming, Task Spec │
│ Antigravity (AI Coder)   │ GDScript 2.0, Shaders, Scene  │
└──────────────────────────┴───────────────────────────────┘
```

---

## 🔄 3. Gameplay Loop Terkini (Final State)

```
[ 1. OVERWORLD ] ──> [ 2. DIGGING ] ──> [ 3. EXCAVATION ]
  WASD jalan,          Auto-posisi,        Meja galian 1920x1080,
  tebas semak          ayun sekop          Pahat → Kuas → Spray
                                                  │
                                                  ▼
[ 6. LEVEL WIN ] <── [ 5. RESTORATION ] <── [ 4. INVENTORY ]
  Foto polaroid,       Altar di map,       Kepingan tersimpan,
  lingkungan pulih     Jigsaw puzzle       mound jadi lubang
```

> ⚠️ **CATATAN DESAIN PENTING (ATURAN REVISI):**
> 1. **Mekanik Kamus Lama Dihapus:** Pada mini-game ekskavasi TIDAK ADA tombol/overlay kamus terjemahan manual. Ekskavasi murni 100% pembersihan relik.
> 2. **Tidak Ada Drop Batu di Tanah:** Pasca ekskavasi, tidak ada batu fisik yang jatuh di overworld. Kepingan langsung masuk ke data inventori player.
> 3. **Transisi Gundukan:** Setelah selesai digali ("Done!"), gundukan tanah berubah menjadi `lubang.png` dengan collision solid `AfterMinigameCol`.

---

## 🏗️ 4. Arsitektur Teknis Godot 4.6 (Engine Rules)

### A. Autoloads & State Machine
1. **`Global` (`res://src/core/global.gd`):**
   * **State Enum:** `enum State { OVERWORLD, EXCAVATION, JOURNAL }`
   * **Signals:**
     * `state_changed(new_state: State)`
     * `excavation_started(dirt_mound)`
     * `excavation_completed(relic_id: String, relic_name: String, symbol_char: String, translation: String)`
     * `camera_shake(intensity: float, duration: float)`
     * `play_sfx(sfx_name: String)`
     * `level_restored`
2. **`InventoryManager` (`res://src/core/inventory_manager.gd`):**
   * Menyimpan `collected_fragments: Dictionary` (ID -> Count) dan `assembled_artifacts: Array`.
   * Methods: `add_fragment(id)`, `remove_fragment(id, amount)`, `get_fragment_count(id)`, `add_artifact(id)`.
   * Signal: `inventory_updated`.

### B. Collision & Physics Layer Standards
* **Layer 1 (World / Solids):** Tembok, rintangan solid, `SolidBody` pada semak & gundukan tanah / lubang.
* **Layer 2 (Player):** Karakter utama (`CharacterBody2D`).
* **Layer 3 (Tools / Hitbox):** Sabit / Sekop tebasan.
* **Layer 4 (Interactables):** `Area2D` pemicu interaksi (Semak, Gundukan, Altar, NPC).

### C. Aturan 2D Y-Sorting & Origin Pivots
* Seluruh container entitas (`Entities`, `Shrubs`, `DirtMounds`) wajib `y_sort_enabled = true`.
* **Player Origin `(0, 0)`:** Tepat di telapak kaki player. Node `Visual` di-offset ke `Vector2(0, -35)`.
* **Obstacle Origin `(0, 0)`:** Tepat di titik kontak tanah. Texture menggunakan properti `offset` (contoh: Semak `offset = Vector2(0, -200)` untuk texture 400px).
* **DILARANG:** Melakukan modifikasi runtime `position.y` di `_ready()` (gunakan `offset` visual).

### D. UI Mouse Filtering & Click Masking
* Container `Control` yang mencakup 1920x1080 wajib memiliki `mouse_filter = MOUSE_FILTER_IGNORE` (`2`) agar tidak menelan input klik mouse ke canvas di bawahnya.
* `TextureButton` miring menggunakan `texture_click_mask` berbasis `BitMap` dengan dekompresi:
  ```gdscript
  var img: Image = button.texture_normal.get_image().duplicate()
  if img.is_compressed():
      img.decompress()
  var bitmap: BitMap = BitMap.new()
  bitmap.create_from_image_alpha(img, 0.1)
  button.texture_click_mask = bitmap
  ```

---

## 📂 5. Struktur Berkas & Scene Saat Ini

```text
D:/Project Game/arkeolog/
├── assets/
│   └── textures/
│       ├── characters/       # player.png, sekop.png, hand.png
│       ├── environment/      # bg.png, gundukan rumput.png, Gundukan Tanah 1.png, lubang.png, semak 1-2 new.png, pohon 1-2.png
│       ├── relics/           # Prasasti.png, Tulisan.png, Tanah.png, Batu 1-3.png
│       └── ui/
│           └── excavation_mode/ # table.png, cloth.png, brush.png, spray.png, hammer_chisel.png, done_button.png
├── src/
│   ├── core/
│   │   ├── global.gd                 # Autoload: State machine, sound, camera shake
│   │   ├── inventory_manager.gd      # Autoload: Data kepingan & artefak
│   │   ├── prompt_visual.gd          # Indikator visual tombol E / Hold / Click
│   │   └── resources/
│   │       ├── fragment_data.gd      # Resource schema kepingan
│   │       └── artifact_data.gd      # Resource schema artefak lengkap
│   ├── entities/
│   │   ├── player/                   # player.tscn, player.gd, shovel_clip.gdshader
│   │   ├── obstacles/                # shrub.tscn, shrub.gd
│   │   └── dirt_mound/               # dirt_mound.tscn, dirt_mound.gd (mound -> lubang)
│   ├── levels/
│   │   └── sandbox.tscn              # Level testing overworld
│   └── ui/
│       └── excavation/               # excavation_overlay.tscn, excavation_overlay.gd, relic_view.gd, tool_outline.gdshader
└── project.godot
```

---

## 🧩 6. Fitur yang SUDAH SELESAI (100% Functional)

1. **Player Movement & Camera:** WASD 8-arah halus, Camera2D zoom & boundary clamp.
2. **Y-Sorting Lingkungan:** Semak & pohon terurut sempurna terhadap posisi kaki player.
3. **Mekanik Tebas Semak:** Tebas semak dengan arit / klik mouse, partikel daun gugur.
4. **Mekanik Gali Gundukan:** Player auto-rotate menghadap gundukan, posisi snap halus, animasi sekop dengan shader klip tanah, transisi `GRASS` → `DIRT`.
5. **Meja Ekskavasi Diegetik (1920×1080):**
   - 3 Alat di atas meja (Kuas kiri atas, Spray kanan atas, Pahat/Palu kiri bawah).
   - Animasi hover: Alat terangkat 12px + outline putih shader.
   - Animasi klik: Scale pulse 1.1x membal (`_bounce_tool`) + SFX.
   - Pahat batu: Hover menggelapkan batu target (`Color(0.55, 0.55, 0.55)`), screen shake meja 4–10px, partikel serpihan batu bulat tebal.
   - Kuas debu: Sapuan tanah dengan partikel awan debu bulat tebal.
   - Spray air: Aksara emas mengilap muncul bertahap.
   - Tombol "Done!": Transisi fade out, gundukan overworld menjadi `lubang.png` dengan collision solid `AfterMinigameCol`.
6. **Backend Inventori:** `InventoryManager` singleton & Resource kepingan.

---

## 🎯 7. Roadmap Tugas Berikutnya untuk Di-brainstorm (Backlog)

Berikut adalah 4 sistem utama yang perlu dirancang arsitektur dan alurnya oleh GPT:

### 🎒 TASK 1: HUD & Inventory UI (Tampilan Kepingan di Layar)
* **Goal:** Player bisa melihat berapa kepingan prasasti yang sudah terkumpul saat berada di Overworld.
* **Pertanyaan Desain:**
  * Apakah berbentuk tas saku di pojok kanan atas yang bisa dibuka (pop-up drawer)?
  * Atau berupa bar ringkas di atas layar yang menampilkan slot kepingan (misal 3 slot kosong yang terisi ikon saat ditemukan)?
  * Bagaimana animasi/notifikasi saat kepingan baru didapatkan dari mini-game ekskavasi?

### 🏛️ TASK 2: Altar Kuno & Mini-Game Restorasi Jigsaw (Restoration Phase)
* **Goal:** Objek Altar di overworld tempat player menyatukan kepingan artefak.
* **Mekanik yang Diinginkan:**
  * Player mendekati Altar di map overworld → tekan `E` untuk membuka UI Restorasi.
  * Layar restorasi: Menampilkan cetakan/bingkai prasasti batu kosong di tengah.
  * Kepingan yang ada di tas ditarik (drag & drop) atau dipasang ke slot yang cocok.
  * Ada efek snapping magnetik + suara *"click/thud"* batu saat kepingan masuk dengan benar.
  * Ketika semua kepingan (misal 3/3) terpasang: Prasasti menyatu utuh, bercahaya emas, dan tercatat sebagai artefak selesai di `InventoryManager`.

### 💬 TASK 3: NPC Dosen / Profesor Arkeologi & Sistem Dialog
* **Goal:** Karakter pemandu di level yang memberi misi, narasi, dan konteks sejarah artefak.
* **Mekanik yang Diinginkan:**
  * NPC berdiri di dekat tenda/kemah penelitian di overworld.
  * Deteksi player (`Area2D`) → muncul tombol interaksi `E`.
  * Sistem dialog: Balon teks bergaya komik/cozy game di atas kepala NPC atau kotak dialog bawah.
  * Flow cerita:
    1. *Awal Level:* "Selamat datang di situs! Coba cari 3 kepingan prasasti yang terkubur di sekitar sini."
    2. *Saat kepingan belum lengkap:* "Kamu baru menemukan X kepingan. Terus cari di gundukan tanah!"
    3. *Saat semua kepingan lengkap:* "Luar biasa! Sekarang bawa kepingan itu ke Altar Kuno di utara dan susun kembali!"
    4. *Setelah altar selesai:* Memberi apresiasi & mengizinkan player lanjut ke level berikutnya.

### 📸 TASK 4: Level Win Condition & Polaroid Reward
* **Goal:** Memberikan reward emosional dan visual saat level berhasil diselesaikan.
* **Mekanik yang Diinginkan:**
  * Saat prasasti di Altar selesai dirakit:
    * Animasi kamera bergetar halus + partikel cahaya emas memancar.
    * Lingkungan sekitar (rumput/pohon) berubah menjadi lebih subur/berwarna cerah (`level_restored`).
    * Popup kartu foto polaroid karakter utama berpose di depan prasasti yang sudah utuh dengan tulisan nama situs dan tanggal.
    * Tombol "Lanjut ke Level Berikutnya" atau "Kembali ke Menu".

---

## 📝 8. Format Output yang Diinginkan dari GPT

Agar Antigravity (AI Coder) dapat langsung mengeksekusi instruksi tanpa kebingungan, minta GPT menghasilkan rancangan per fitur dengan format berikut:

```markdown
### [NAMA FITUR]
1. **Ringkasan Konsep & Alur Interaksi**
2. **Daftar Berkas yang Dibuat/Dimodifikasi (Full Path)**
3. **Struktur Node Tree Scene (`.tscn`)**
4. **Logika GDScript & Signal (Spesifikasi method & static typing)**
5. **Kriteria Selesai (Definition of Done)**
```
