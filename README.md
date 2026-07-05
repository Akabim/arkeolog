# Project: Arkeolog Gembul (Working Title)

A cozy, minimalist, web-focused archaeology game built with **Godot 4.6**. The game features a 2D top-down perspective with a cute, round, chunky pixel art style (thick ink outlines, cute Chiikawa-like proportions, warm natural colors) inspired by *Poni's Math Quest*.

---

## 🎯 Core Pillar & Game Loop
- **Pacing:** Ultra-chill, no game over, no timers, ASMR-focused sound/visual effects.
- **Scope:** Scrollable 2D levels. The camera (Camera2D) follows the player with smooth lerping. One open area or shrine ruin per level.
- **Loop:**
  1. **Overworld (WASD):** Move around, clear grass/shrubs using basic collision/bashing.
  2. **Excavation Mode (Mouse UI):** Click dirt mounds to zoom-in for a 3-tool micro-cleaning game (Chisel -> Brush -> Spray).
  3. **Deciphering (Journal UI):** Match newly uncovered Hanacaraka scripts manually using an in-game dictionary notebook.
  4. **Restoration (Free Physics):** Push the cleaned stones using the character's physical collision body. NO grid limits, NO auto-snapping. Stones can be placed slightly messy/imperfectly.
  5. **Reward:** Level visual changes (water flows, torches light up), snap a photo for the album.

---

## 🛠️ Technical Architecture Guide (For CLI/AI Reference)

### 1. Scene Structure
- `Main.tscn` (Manages level loading, UI layers, and state machine).
- `Level_Base.tscn` (Base class for levels containing TileMapLayer, Shrub obstacles, and Socket points).
- `Player.tscn` (CharacterBody2D, top-down movement, simple squash/stretch animation state for pushing/bashing).
- `Excavation_Overlay.tscn` (CanvasLayer for mouse-controlled cleaning mini-game).
- `Journal_UI.tscn` (CanvasLayer for the translation notebook and photo album).

### 2. State Machine (Game States)
- `OVERWORLD`: Player moving using WASD, interacting with world elements.
- `EXCAVATION`: Player movement locked. Mouse interaction active for cleaning tool micro-tasks.
- `JOURNAL`: Menu open. Player matches symbols manually.

### 3. Translation & Physics Logic
- **No Auto-Translate:** Player must read the translated clue in their journal (e.g., *Hanacaraka symbol combo* = "Pilar Kiri") and deduce where it belongs based on the environment's physical clues.
- **No Snapping / No Grid:** When a stone block is pushed into its designated `Area2D` socket, the game calculates the distance to the socket's center. If it is within an acceptable tolerance radius (e.g., 10-15 pixels), count it as a correct placement. Keep the stone's final pushed transform intact to preserve the silly/imperfect alignment.
- **Level Clear Trigger:** Emit a `level_restored` signal only when ALL stones in the room are within their respective socket tolerance radii.

---

## 🎨 Color Palette Reference (For Shader/Theme Config)
- **Background/Grass:** `#4D7C59` (Cozy Moss)
- **Obstacles/Shrubs:** `#2F5233` (Ancient Shrub)
- **Dirt Mounds:** `#6F4E37` (Wet Soil)
- **Ancient Structures:** `#8C8D8A` (Ruined Stone)
- **Glint/Hanacaraka Script:** `#D4AF37` (Relic Gold)
- **Outlines/UI:** `#111827` (Thick Ink Black)
- **Character Body:** `#F3F4F6` (Cloud White)
- **Character Cheeks:** `#FCD34D` (Cheeky Yellow)

---

## 💻 Instructions for AI CLI
When asked to implement code, ensure to:
1. Use **Godot 4.6 GDScript syntax** (e.g., standard `TileMapLayer` nodes instead of the deprecated `TileMap`).
2. Keep scripts modular and decouple UI logic from gameplay state using Signals.
3. Prioritize satisfying/juice feedback loops (emit signals for screenshake, particle spawning, and sound triggers).
