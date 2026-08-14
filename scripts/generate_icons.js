// scripts/generate_icons.js
// Regenerates DesignSystem/Icons/AstraIcon.swift from the Google Material
// Symbols codepoints file (Resources/Fonts/MaterialSymbolsOutlined.codepoints).
//
// Usage:  node scripts/generate_icons.js   (run from the project root)
//
// The SF Symbol -> Material Symbols mapping below is the single source of
// truth for which icons the app uses. Add new icons here, then re-run.

const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const codepointsPath = path.join(root, 'AstraNotes', 'Resources', 'Fonts', 'MaterialSymbolsOutlined.codepoints');
const outputPath = path.join(root, 'AstraNotes', 'DesignSystem', 'Icons', 'AstraIcon.swift');

// Load "name codepoint-hex" lines
const codepoints = new Map();
for (const line of fs.readFileSync(codepointsPath, 'utf8').trim().split('\n')) {
  const [name, hex] = line.trim().split(/\s+/);
  if (name && hex) codepoints.set(name, hex);
}

// SF Symbol name -> Material Symbols icon name
const mapping = [
  ['square.grid.2x2', 'grid_view'], ['mic.circle', 'mic'], ['text.document', 'description'],
  ['doc.text', 'description'], ['square.stack', 'style'], ['questionmark.circle', 'help'],
  ['book', 'menu_book'], ['brain', 'psychology'], ['graduationcap', 'school'],
  ['chart.bar', 'bar_chart'], ['heart.circle', 'favorite'], ['gearshape', 'settings'],
  ['mic', 'mic'], ['mic.fill', 'mic'], ['pause', 'pause'], ['pause.fill', 'pause'],
  ['play', 'play_arrow'], ['play.fill', 'play_arrow'], ['stop.fill', 'stop'],
  ['waveform', 'graphic_eq'], ['waveform.badge.mic', 'mic'], ['arrow.down.doc', 'download'],
  ['folder', 'folder'], ['timer', 'timer'], ['forward', 'arrow_forward'],
  ['arrow.right', 'arrow_forward'], ['arrow.left', 'arrow_back'], ['arrow.triangle.right', 'play_arrow'],
  ['arrow.triangle.2.circlepath', 'refresh'],
  ['checkmark', 'check'], ['checkmark.circle', 'check_circle'], ['checkmark.circle.fill', 'check_circle'],
  ['checkmark.seal', 'verified'], ['checkmark.seal.fill', 'verified'], ['xmark.circle.fill', 'cancel'],
  ['exclamationmark.triangle.fill', 'warning'], ['exclamationmark.triangle', 'warning'],
  ['plus', 'add'], ['plus.circle', 'add_circle'], ['plus.circle.fill', 'add_circle'],
  ['magnifyingglass', 'search'], ['sparkles', 'auto_awesome'], ['trash', 'delete'],
  ['paperplane', 'send'], ['square.and.arrow.up', 'share'], ['doc.on.doc', 'content_copy'],
  ['doc.richtext', 'article'], ['doc.fill', 'description'], ['star', 'star'], ['star.fill', 'star'],
  ['clock', 'schedule'], ['clock.arrow.2.circlepath', 'history'], ['calendar', 'calendar_month'],
  ['link.circle', 'link'], ['info.circle', 'info'], ['pencil', 'edit'], ['pencil.circle', 'edit'],
  ['pencil.and.outline', 'edit_note'], ['chevron.down', 'expand_more'], ['chevron.right', 'chevron_right'],
  ['checklist', 'checklist'], ['list.clipboard', 'checklist'], ['list.bullet.rectangle', 'notes'],
  ['list.bullet.indent', 'list'], ['lightbulb', 'lightbulb'], ['lightbulb.fill', 'lightbulb'],
  ['eye', 'visibility'], ['person', 'person'], ['person.2', 'group'], ['gauge', 'speed'],
  ['function', 'functions'], ['textformat.abc', 'abc'], ['text.quote', 'format_quote'],
  ['captions.bubble', 'subtitles'], ['flag.checkered', 'flag'], ['trophy.fill', 'emoji_events'],
  ['play.circle.fill', 'play_circle'], ['pause.circle', 'pause_circle'],
  ['square.stack.3d.up', 'layers'], ['square.stack.3d.up.slash', 'layers_clear'],
  ['book.closed', 'menu_book'], ['bubble.left.and.bubble.right', 'translate'],
  ['building.columns', 'account_balance'], ['testtube.2', 'science'], ['paintpalette', 'palette'],
  ['paintbrush', 'brush'], ['figure.run', 'directions_run'], ['heart', 'favorite'],
  ['sun.max', 'light_mode'], ['moon', 'dark_mode'], ['circle.lefthalf.filled', 'contrast'],
  ['circle', 'circle'], ['circle.dashed', 'radio_button_unchecked'],
  ['arrow.down.to.line', 'arrow_downward'], ['arrow.up.to.line', 'arrow_upward'],
  ['printer', 'print'],
  ['text.book.closed', 'menu_book'], ['1.circle', 'looks_one'], ['2.circle', 'looks_two'],
  ['3.circle', 'looks_3'], ['textformat', 'text_fields'], ['xmark.circle', 'cancel'],
  ['arrow.uturn.backward', 'undo'], ['bolt.circle', 'bolt'], ['hourglass', 'hourglass_empty'],
  ['chart.line.uptrend.xyaxis', 'show_chart'], ['globe', 'globe'], ['globe.americas', 'public'],
  ['target', 'target'], ['text.alignleft', 'notes'],
];

const toCase = (name) => name.replace(/_([a-z])/g, (_, c) => c.toUpperCase());

const missing = [];
const out = [];
out.push('//');
out.push('//  AstraIcon.swift');
out.push('//  AstraNotes');
out.push('//');
out.push('//  Generated from Google Material Symbols (Outlined variable font).');
out.push('//  Codepoint source: Resources/Fonts/MaterialSymbolsOutlined.codepoints');
out.push('//  Regenerate: node scripts/generate_icons.js');
out.push('//');
out.push('');
out.push('import SwiftUI');
out.push('');
out.push('/// Google Material Symbols icons used across AstraNotes.');
out.push('/// Raw value is the font PUA codepoint; render via AstraIconView.');
out.push('enum AstraIcon: String, CaseIterable, Identifiable {');
out.push('    var id: String { rawValue }');
out.push('');

// Deduplicate: several SF Symbols map to the same Material icon.
const emitted = new Set();
for (const [sf, mat] of mapping) {
  const hex = codepoints.get(mat);
  if (!hex) { missing.push(mat + ' (from ' + sf + ')'); continue; }
  const caseName = toCase(mat);
  if (emitted.has(caseName)) continue; // already emitted for another SF name
  emitted.add(caseName);
  const glyph = String.fromCharCode(parseInt(hex, 16));
  out.push('    /// SF Symbols: "' + sf + '"');
  out.push('    case ' + caseName + ' = "' + glyph + '"');
}
out.push('}');
out.push('');
out.push('extension AstraIcon {');
out.push('    /// Resolves a legacy SF Symbol name to the closest Material icon.');
out.push('    static func fromSystemName(_ name: String) -> AstraIcon? {');
out.push('        switch name {');
for (const [sf, mat] of mapping) {
  const hex = codepoints.get(mat);
  if (!hex) continue;
  out.push('        case "' + sf + '": return .' + toCase(mat));
}
out.push('        default: return nil');
out.push('        }');
out.push('    }');
out.push('}');

if (missing.length > 0) {
  console.error('MISSING Material icons: ' + missing.join(', '));
  process.exit(1);
}
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, out.join('\n'), 'utf8');
console.log('Generated ' + outputPath + ' (' + mapping.length + ' icons)');
