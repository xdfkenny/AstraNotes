# AstraNotes UI Design System

> Design Read: **Native macOS product UI for IB students**, premium-consumer + productivity hybrid. Apple-HIG-native language (Liquid Glass materials, SF Symbols, SF Pro Rounded). Restrained asymmetry, calm focus, motivated spring motion.
>
> Dials: `VARIANCE: 6` (restrained asymmetry) · `MOTION: 5` (fluid springs, all < 300ms, purpose-driven) · `DENSITY: 4` (daily app, breathing room)
>
> Derived from: design-taste-frontend (anti-slop), high-end-visual-design (nested architecture, physics), typography (type discipline), emilkowal-animations (motion craft).

---

## 1. Design Principles

1. **Native first.** The app must feel like it belongs on macOS. System materials, SF Symbols, system fonts. No web-isms, no emoji in UI chrome, no hand-drawn SVG-style illustrations.
2. **One accent, locked.** Cobalt-teal accent used identically everywhere. Semantic colors (red, amber, emerald) only where they carry real state.
3. **One radius scale, locked.** Radius rules below are non-negotiable across all views.
4. **One type family system.** SF Pro Rounded for display, SF Pro for body, SF Mono for data. No decorative fonts.
5. **Motion must communicate.** Every animation answers: state feedback, hierarchy, or transition. Nothing "because it looks cool". All < 300ms, all spring-physics, all reduced-motion aware.
6. **Zero slop.** No AI-purple gradients, no glows, no pure black/white, no em-dashes in UI copy, no decorative status dots, no three-equal-cards.

---

## 2. Color System

### 2.1 Palette (single accent: Astra Teal)

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `accent` | `#0B7A6E` (deep teal) | `#59C9B8` (soft teal) | Primary actions, selection, active states, links |
| `accentContainer` | `#0B7A6E` at 12% alpha | `#59C9B8` at 16% alpha | Selected row backgrounds, tinted hero cell |
| `onAccent` | `#FFFFFF` | `#06251F` | Text on accent fills |

**Rule:** accent is a flat fill. No gradients, no glow, no purple. The teal is deliberately calm for long reading sessions.

### 2.2 Semantic colors (state only, used sparingly)

| Token | Light | Dark | Meaning |
|-------|-------|------|---------|
| `danger` | `#D64545` | `#FF6B6B` | Errors, stop, destructive |
| `warning` | `#C77E1F` | `#E8A44C` | AI processing, review needed |
| `success` | `#1E8E5A` | `#4BC48C` | Ready, complete, connected |
| `info` | accent teal | accent teal | Informational |

### 2.3 Neutrals (one family, no mixing warm/cool)

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | `#F7F7F8` | `#131316` | Window base |
| `surface` | `#FFFFFF` | `#1C1C1F` | Cards, panels |
| `surfaceElevated` | `#FFFFFF` | `#242428` | Popovers, sheets |
| `hairline` | `#000000` at 10% | `#FFFFFF` at 12% | Dividers, borders |
| `textPrimary` | `#1A1A1E` | `#F2F2F4` | Headings, body |
| `textSecondary` | `#5C5C66` | `#A0A0AA` | Body secondary |
| `textTertiary` | `#8E8E98` | `#6E6E78` | Captions, timestamps |

**Rule:** no pure `#000000`, no pure `#FFFFFF`. Hairlines instead of heavy shadows: macOS prefers edges over depth. If a shadow is ever used, tint it to the surface hue, never pure black.

### 2.4 Subject group colors (semantic, muted)

Used ONLY for the small roundel behind a subject's SF Symbol in the sidebar and pickers. Muted variants so they never compete with the accent.

| Group | Color (light/dark) |
|-------|-------------------|
| 1. Language & Literature | `#B4574E` / `#D98A83` |
| 2. Language Acquisition | `#2E6BA8` / `#7BB3E8` |
| 3. Individuals & Societies | `#8A6D2F` / `#C9A85C` |
| 4. Sciences | `#2E7D6E` / `#6FC3B2` |
| 5. Mathematics | `#5A5CA8` / `#A2A4E8` |
| 6. The Arts | `#A04A7D` / `#D88FB4` |
| Core (TOK/EE/CAS) | `#4A5568` / `#8B95A7` |

---

## 3. Typography

### 3.1 Type system (native)

| Level | Design | Size | Weight | Leading | Tracking | Use |
|-------|--------|------|--------|---------|----------|-----|
| Display | SF Pro Rounded | 28 | Semibold | 1.1 | -0.5 | Dashboard greeting, empty-state titles |
| Title | SF Pro Rounded | 22 | Semibold | 1.2 | -0.3 | View titles, note titles |
| Heading | SF Pro Rounded | 17 | Semibold | 1.2 | -0.2 | Section headings inside content |
| Subheading | SF Pro | 15 | Semibold | 1.3 | 0 | Card titles |
| Body | SF Pro | 13 | Regular | 1.5 | 0 | UI body, note metadata |
| BodyLarge | SF Pro | 15 | Regular | 1.6 | 0 | Markdown content rendering |
| Caption | SF Pro | 11 | Regular | 1.3 | +0.2 | Timestamps, helper text |
| Micro | SF Pro | 10 | Medium | 1.2 | +0.8 | Section labels, uppercase |

**Rules:**
- SF Pro Rounded (`Font.system(design: .rounded)`) for display only. Friendly, scholarly, never childish.
- SF Mono (`Font.system(design: .monospaced)`) + `.monospacedDigit()` for ALL data: timers, durations, word counts, token counts, timestamps. Tabular alignment is mandatory.
- Micro labels (uppercase, tracking +0.8) are rationed: **max 1 per 3 sections**. The sidebar's "STUDIO / LIBRARY / STUDY / IB CORE" group headers count against this.
- Body text lines stay under ~70 characters (`maxWidth: 640` for content columns).
- Dark mode: headings drop one weight (Semibold -> Medium feel) to counter perceived boldness.
- No all-caps anywhere except Micro labels, max 3 words.

### 3.2 Note content typography (markdown rendering)

- Body: 15pt, leading 1.6, `textSecondary`->`textPrimary`
- Headings inside notes use the Heading level, Rounded design
- `inline code` and formulas: SF Mono
- Blockquotes: accent-tinted left hairline, secondary text
- Tables: 13pt, header semibold, hairline row separators only under header + final row (no per-row borders)

---

## 4. Shape & Elevation

### 4.1 Radius scale (locked)

| Token | Value | Use |
|-------|-------|-----|
| `radiusMicro` | 6 | Chips, small badges, HL/SL badges |
| `radiusControl` | 8 | Buttons, inputs, menu buttons |
| `radiusCard` | 12 | Cards, note cells, waveform panel |
| `radiusPanel` | 16 | Inspector panels, sheets, popovers |
| `radiusPill` | Capsule | Primary CTA, recording button, tags |

**Rule:** interactive elements are `radiusControl` or pill. Containers are `radiusCard`. Overlays are `radiusPanel`. This exact mapping applies everywhere. No mixing.

### 4.2 Elevation strategy

- **Default:** hairline border (`hairline` color) + surface background. No shadow.
- **Elevated (popovers, sheets):** `surfaceElevated` + hairline + one soft tinted shadow (offset y 4, radius 16, surface-hue-tinted black at 12%).
- **Materials (glass):** system materials `.ultraThinMaterial` / `.regularMaterial` with a 1px inner highlight (`.white` at 12% light / 10% dark) to simulate refraction. Used for: floating recording bar, sidebar, toolbar. Never on scrolling content.

### 4.3 Double-bezel (nested architecture)

Premium cards use the nested structure: an outer hairline container (1px padding, radius +2) wrapping the inner content surface. See `AstraCard`.

---

## 5. Iconography

- **Google Material Symbols (Outlined)** — bundled variable font (`Resources/Fonts/MaterialSymbolsOutlined.ttf`, registered at launch by `FontRegistrar`). NOT SF Symbols.
- `AstraIcon` enum (`DesignSystem/Icons/AstraIcon.swift`) — generated from the Material Symbols codepoints file; each case carries the font PUA codepoint. Regenerate with `node scripts/generate_icons.js`.
- Render via `AstraIconView(.iconName, size: N)` — a `Text` glyph, tintable with `foregroundStyle`, any size. Never apply `.font()` on top (it would override the icon font).
- **Filled/active states are expressed with color, not glyph style** (Material Symbols Filled font is not bundled): active = accent, inactive = tertiary.
- **Zero emoji** in UI chrome. Note content uses clean markdown headers.
- Sizes: sidebar 13, toolbar 14, card adornments 13-16, empty states 24 in a 64pt tinted roundel.
- New icons: add an `['SF-alias', 'material-name']` entry to `scripts/generate_icons.js`, re-run, and add the case to any enum (`NavigationDestination.astraIcon`, `IBGroup.astraIcon`, `NoteType.astraIcon`, `EEStatus.astraIcon`, `CASCategory.astraIcon`, `ThemeMode.astraIcon`, `EESectionTab.astraIcon`).

---

## 6. Components

### 6.1 AstraButton
- **Primary:** accent pill fill, onAccent text, `radiusPill`. Trailing icon nested in its own circle (`background: .black.opacity(0.08)`, 20pt) flush with the right padding. Press feedback: scale 0.97 @ 100ms, release spring 200ms.
- **Secondary:** material + hairline, capsule. Same press physics.
- **IconButton:** 30pt, hairline circle on hover, no border at rest (native macOS feel).
- Labels: 1-3 words max. Never wraps.

### 6.2 AstraCard
Nested double-bezel:
- Outer: `surface` with hairline border, `radiusCard`, 1pt padding.
- Inner: `surface` (or tinted container), inner radius = `radiusCard - 2`.
- Content padding 14pt. Optional leading adornment (subject roundel, SF Symbol in tinted circle).
- Hover (only in interactive contexts): border lightens to accent at 40% alpha. `scaleEffect(0.995)` press feedback.

### 6.3 SectionHeader
- Icon (SF Symbol, accent or neutral by hierarchy) + Title (Heading level) + optional count chip.
- Hairline divider below, `divider` style.
- Used at most 1 Micro label per 3 sections (see Typography rules).

### 6.4 TagChip
- Capsule, `radiusMicro`-adjacent padding (6/2), secondary text 11pt, subtle hairline border.
- Selected state: accent container + accent text.

### 6.5 StatusDot
- Semantic ONLY: recording (danger, pulsing 1.2s ease-in-out opacity 1->0.35, reduce-motion aware), processing (warning, static), ready (success, static), idle (tertiary, static).
- Size 8pt, always paired with a label. Never decorative.

### 6.6 WaveformView
- Live audio bars from `AVAudioEngine` tap. 60 bars, idle = quiet baseline (3pt), active = amplitude-driven heights, spring-animated with 0.15s response. Recording bars tinted `danger`; paused dimmed to tertiary.
- No fake bars. Real data only.

### 6.7 EmptyStateView
- 48pt SF Symbol in a tinted roundel (accent at 10% bg), Display title, one line of secondary text, one primary AstraButton CTA. Composition: centered, 32pt stack spacing, generous vertical padding (40pt).

### 6.8 SkeletonView (AI generation loading)
- Structural skeleton matching final content: title bar (40% width, 22pt height), summary block (3 lines), formula block (accent-tinted), diagram block (rounded rect with 2:3 ratio). Shimmer via `opacity` animation 1.2s ease-in-out 0.6->1.0, staggered. **No spinners.**

### 6.9 LevelBadge
- "HL" / "SL" capsule, 10pt uppercase, tracking +0.6, `radiusMicro`. HL: accent container; SL: tertiary container. Max 3 chars.

### 6.10 SubjectRoundel
- 28pt circle, muted group color at 18% alpha, SF Symbol in the group color, 14pt. Used in sidebar rows and pickers.

---

## 7. Motion Spec

All motion uses SwiftUI springs. **Every animation has a stated purpose** (feedback, hierarchy, transition). All gated by `@Environment(\.accessibilityReduceMotion)` -> static state.

| Element | Animation | Duration | Purpose |
|---------|-----------|----------|---------|
| Button press | `scale 0.97` | press 100ms / release 200ms | Feedback |
| Button hover | border lighten to accent 40% | 150ms ease-out | Feedback |
| View entrance | fade + translateY 8pt, spring | 250ms, stagger 0.06s | Hierarchy |
| Recording start | waveform panel scale-in, recording dot pulse starts | 250ms spring | State transition |
| Recording pause | waveform dims, dot stops | 200ms | State transition |
| Flashcard flip | `rotation3DEffect` Y 180, spring stiffness 140 damping 20 | 300ms | Content reveal |
| Card swipe (quiz) | translateX + opacity, spring | 250ms | Feedback |
| Sheet / popover | native macOS presentation | system | Transition |
| Status changes | dot color cross-fade 150ms | 150ms | Feedback |
| List reorder | native `withAnimation` move | 250ms | State transition |

**Rules:**
- Never animate layout properties (`frame`, `padding`, `position`). Transform and opacity only.
- Never `scale(0)`. Minimum enter scale 0.95.
- No infinite loops except the recording pulse (semantic: live state) and skeleton shimmer (loading state). Both reduced-motion aware.
- Keyboard-initiated actions render instantly, no entrance animation.

---

## 8. Layout Architecture

### 8.1 Window
- 1200x780 default, min 960x640. `NavigationSplitView`.
- Sidebar 240pt, `.sidebar` material. Content area `background` base. Inspector (note details) 300pt, optional, toggleable.

### 8.2 Sidebar (redesigned)

```
┌──────────────────────────┐
│ AstraNotes          ⚙︎  │   toolbar: wordmark + settings
├──────────────────────────┤
│ STUDIO                  │   Micro label (1 of 4 rationed)
│ ● New Recording   [red] │   primary action row, accent-tinted
│ Import Audio            │
│                         │
│ LIBRARY                 │   Micro label
│  Physics HL             │   subject row: SubjectRoundel + name
│  Mathematics HL         │   + level badge + note count (mono)
│  Chemistry HL           │
│  History SL             │
│  Spanish ab initio SL   │
│  Visual Arts SL         │
│  + Add Subject          │   secondary text row
│                         │
│ STUDY                   │   Micro label
│  Flashcards       12    │   count chip in mono, due today
│  Quizzes                │
│  Study Guides           │
│                         │
│ IB CORE                 │   Micro label
│  TOK                    │
│  Extended Essay   2,431 │   word count, mono tabular
│  Internal Assessments   │
│  CAS Journal      18h   │
├──────────────────────────┤
│ ● Whisper ready     ● ◐ │   status footer: semantic dots + labels
│ DeepSeek connected      │
└──────────────────────────┘
```

- Selected row: accent container background + accent text + left 3pt accent indicator.
- Subject rows: muted group roundel. Note counts in SF Mono tabular.
- Status footer: two semantic StatusDots (model ready = success, API disconnected = danger) with 10pt captions. Hairline top border.

### 8.3 Dashboard (bento, asymmetric)

```
┌────────────────────────────┬──────────────────────┐
│  Continue Recording        │  Today               │
│  [waveform preview]        │  · 09:00 Physics HL  │
│  Resume / New CTA          │  · 11:30 Math HL     │
│  (accent-tinted hero cell) │  · 14:00 TOK session │
├────────────────────────────┼──────────────────────┤
│  Recent notes (list)       │  Study streak  14    │
│  Note 1 · Physics HL · 45m │  [compact bar]       │
│  Note 2 · Math HL · 60m    │  Due today: 12      │
│  Note 3 · Chem HL · 40m    │  (number cell, mono) │
│  See all >                │                      │
├────────────────────────────┴──────────────────────┤
│  IB progress: EE 2,431/4,000 · TOK essay · IA     │
│  [3 progress cells, thin hairline dividers]       │
└───────────────────────────────────────────────────┘
```

- Asymmetric grid: 2fr / 1fr columns. Four distinct cell families (hero-tinted, list, number, progress). No three-equal-cards, no repetition.
- Hero cell: accent container at 8%, not a gradient.
- Numbers (streak, counts) always SF Mono tabular.

### 8.4 Recording View (asymmetric split)

```
┌───────────────────────────────────────┬───────────────┐
│  New Recording                        │  Lecture      │
│  [SubjectPicker ▾] [Tags]             │  ▾ subject    │
│                                       │  Level: HL    │
│  ┌─────────────────────────────────┐  │  Tags:        │
│  │  WaveformView (glass panel)     │  │  Teacher:     │
│  │                                 │  │               │
│  │       00:00:00 (mono tabular)   │  │  Language:    │
│  │       ● Recording · 12:04       │  │  EN ▾         │
│  └─────────────────────────────────┘  │               │
│                                       │  Transcription │
│  ┌──────┐  ┌─────────────────────┐    │  ☑ after stop │
│  │  ◉  │  │  Pause     Stop     │    │  ☑ AI enhance │
│  └──────┘  └─────────────────────┘    │               │
│  record   controls                    │  Cancel  Start│
│  (danger)                             │        (accent)
└───────────────────────────────────────┴───────────────┘
```

- Record button: 64pt double-bezel. Outer: material ring with hairline. Inner: 40pt danger circle, pulses only when recording (semantic).
- Timer: SF Mono tabular 28pt. Micro label "RECORDING" + elapsed under it.
- Right inspector: `radiusPanel` surface, form rows with `radiusControl` inputs.
- Start button disabled until subject chosen and mic permission granted.

### 8.5 Note Detail

```
Toolbar: [← Back]  [SubjectRoundel Physics HL]  Title (Rounded 22)  ...  [Open in Obsidian]
Metadata row: date · duration · teacher · language   (caption, mono data)
────────────────────────────────────────────────────────────────
  Content column (max 640pt, centered-left)
  Summary / Key Concepts / Formulas / Diagrams / Study Questions
  Mermaid + LaTeX rendered via WebKit
────────────────────────────────────────────────────────────────
Footer: AI status · token usage (mono) · generated date
```

### 8.6 Flashcards / Quiz / IB tools

- **Flashcards:** center-stage 3D flip card (420x280, `radiusCard`), thin progress bar top (not a filled-track row), grade pills bottom (Again/Hard/Good/Easy), Space=flip, 1-4=grade. Keyboard-first.
- **Quiz:** question card + timer chip (mono) + option rows (hover = hairline highlight, selected = accent container). Results: score ring + weak-area list.
- **IB tools (TOK/EE/IA/CAS):** two-column workbench: left = progress list (word counts mono, status chips), right = active form/template editor. `radiusPanel` surfaces.

---

## 9. States

| State | Spec |
|-------|------|
| Loading | SkeletonView (structural shimmer) for AI work; progress hairline for transcription (width = progress, 150ms). Never spinners. |
| Empty | EmptyStateView per surface: Library ("No notes yet" + "Record your first lecture"), Flashcards ("Generate cards from your notes"), Dashboard (onboarding steps). |
| Error | Inline under the failing control, `danger` text 11pt, icon + message. Toasts only for transient successes ("Note saved to vault"). |
| Disabled | Opacity 0.4, no interaction, cursor not-allowed. Never gray-on-gray. |

---

## 10. Copy Rules

- **Zero em-dashes.** Periods, commas, colons only.
- No emoji in UI chrome or AI-generated note templates. Clean markdown headers.
- Button labels: 1-3 words. One label per intent ("Start Recording" everywhere, never "Begin Session" elsewhere).
- No version stamps, no "quietly", no decorative micro-meta under headers.
- No fake-precise numbers in UI copy. Real data only (actual counts, real durations).

---

## 11. Accessibility

- WCAG AA everywhere: body 4.5:1, large text 3:1. Audit every accent-on-accent combination.
- Full keyboard navigation: Tab order, Space activates, Esc cancels. Flashcard/Quiz are keyboard-first.
- `accessibilityReduceMotion` gates all motion. Recording pulse falls back to static dot.
- `accessibilityReduceTransparency`: materials fall back to solid `surface` colors.
- VoiceOver labels on every icon button (SF Symbols title is not enough).
- Focus rings: system default (accent), never removed.

---

## 12. Implementation Notes (SwiftUI)

- All tokens live in `DesignTokens.swift` as `Color`/`Font`/`CGFloat` statics. No hardcoded hex in views.
- Components in `Components/` folder. Every view file imports only `DesignTokens` for styling.
- Named colors in `Assets.xcassets` for accent/semantic colors (works with light/dark automatically).
- `@Environment(\.accessibilityReduceMotion)` read once per view that animates.
- Materials only on fixed/sticky surfaces (sidebar, floating bar, toolbar). Never on scrolling content.
- Avoid `withAnimation` on layout-affecting properties. Use `contentTransition` / transform-only.
