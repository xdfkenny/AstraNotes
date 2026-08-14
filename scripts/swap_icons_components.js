// scripts/swap_icons_components.js
// Third migration pass: component call sites using the old `systemImage:`
// parameter names -> `icon:` with AstraIcon values, and native SwiftUI
// `Label(_:systemImage:)` -> Label with AstraIconView icon.
//
// Usage: node scripts/swap_icons_components.js

const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const src = path.join(root, 'AstraNotes');

const edits = [
  // AstraAdornment
  ['Views/Dashboard/DashboardView.swift',
   'AstraAdornment(systemImage: "mic.fill", tint: .accent)',
   'AstraAdornment(icon: .mic, tint: .accent)'],
  ['Views/Transcription/TranscriptionView.swift',
   'AstraAdornment(systemImage: "waveform", tint: .accent)',
   'AstraAdornment(icon: .graphicEq, tint: .accent)'],

  // AstraButton / AstraIconButton
  ['Views/Dashboard/DashboardView.swift',
   'systemImage: "mic.fill",',
   'icon: .mic,'],
  ['Views/Notes/NoteDetailView.swift',
   'AstraIconButton(systemImage: note.isFavorite ? "star.fill" : "star",',
   'AstraIconButton(icon: .star,'],
  ['Views/Notes/NoteDetailView.swift',
   'AstraIconButton(systemImage: "square.and.arrow.up", help: String(localized: "common.share")) {}',
   'AstraIconButton(icon: .share, help: String(localized: "common.share")) {}'],
  ['Views/Recording/RecordingView.swift',
   'systemImage: audioService.state == .paused ? "play.fill" : "pause.fill",',
   'icon: audioService.state == .paused ? .playArrow : .pause,'],
  ['Views/Recording/RecordingView.swift',
   'systemImage: "folder",',
   'icon: .folder,'],
  ['Views/Transcription/TranscriptionView.swift',
   'systemImage: "sparkles",',
   'icon: .autoAwesome,'],

  // SectionHeader
  ['Views/Dashboard/DashboardView.swift',
   'SectionHeader(title: String(localized: "dashboard.dueCards"), systemImage: "clock")',
   'SectionHeader(title: String(localized: "dashboard.dueCards"), icon: .schedule)'],
  ['Views/Dashboard/DashboardView.swift',
   'systemImage: "clock.arrow.circlepath"',
   'icon: .history'],
  ['Views/Dashboard/DashboardView.swift',
   'SectionHeader(title: String(localized: "dashboard.subjects"), systemImage: "book")',
   'SectionHeader(title: String(localized: "dashboard.subjects"), icon: .menuBook)'],
  ['Views/Dashboard/DashboardView.swift',
   'SectionHeader(title: String(localized: "sidebar.ibCore"), systemImage: "graduationcap")',
   'SectionHeader(title: String(localized: "sidebar.ibCore"), icon: .school)'],
  ['Views/Notes/NoteDetailView.swift',
   'SectionHeader(title: String(localized: "notes.title"), systemImage: "doc.text")',
   'SectionHeader(title: String(localized: "notes.title"), icon: .description)'],
  ['Views/Recording/RecordingView.swift',
   'SectionHeader(title: String(localized: "recording.lecture"), systemImage: "info.circle")',
   'SectionHeader(title: String(localized: "recording.lecture"), icon: .info)'],
  ['Views/Transcription/TranscriptionView.swift',
   'systemImage: "waveform.badge.mic"',
   'icon: .mic'],
  ['Views/Transcription/TranscriptionView.swift',
   'systemImage: "text.alignleft"',
   'icon: .notes'],
  ['Views/Transcription/TranscriptionView.swift',
   'systemImage: "square.and.arrow.up"',
   'icon: .share'],

  // EmptyStateView
  ['Views/Dashboard/DashboardView.swift',
   'systemImage: "mic",',
   'icon: .mic,'],
  ['Views/Notes/NoteDetailView.swift',
   'systemImage: "doc.text",',
   'icon: .description,'],
  ['Views/Transcription/TranscriptionView.swift',
   'systemImage: "waveform.badge.mic",',
   'icon: .mic,'],

  // SubjectRoundel
  ['Views/Sidebar/SidebarView.swift',
   'SubjectRoundel(systemImage: subject.group.icon, group: subject.ibGroup)',
   'SubjectRoundel(icon: subject.group.astraIcon, group: subject.ibGroup)'],

  // Native Label(_:systemImage:) -> Label { } icon: { AstraIconView }
  ['Views/IB/EETrackerView.swift',
   'Label(ee.subject, systemImage: "book")',
   'Label { Text(ee.subject) } icon: { AstraIconView(.menuBook, size: 12) }'],
  ['Views/IB/EETrackerView.swift',
   'Label(supervisor, systemImage: "person")',
   'Label { Text(supervisor) } icon: { AstraIconView(.person, size: 12) }'],
  ['Views/IB/EETrackerView.swift',
   'Label(String(localized: "ee.minWords"), systemImage: "arrow.down.to.line")',
   'Label { Text(String(localized: "ee.minWords")) } icon: { AstraIconView(.arrowDownward, size: 12) }'],
  ['Views/IB/EETrackerView.swift',
   'Label(String(format: String(localized: "ee.maxWords"), ee.maxWordCount), systemImage: "arrow.up.to.line")',
   'Label { Text(String(format: String(localized: "ee.maxWords"), ee.maxWordCount)) } icon: { AstraIconView(.arrowUpward, size: 12) }'],
  ['Views/IB/IAWorkbenchView.swift',
   'Label(ia.subject, systemImage: "book")',
   'Label { Text(ia.subject) } icon: { AstraIconView(.menuBook, size: 12) }'],
  ['Views/IB/IAWorkbenchView.swift',
   'Label(ia.type.displayName, systemImage: "doc.text")',
   'Label { Text(ia.type.displayName) } icon: { AstraIconView(.description, size: 12) }'],
  ['Utilities/MarkdownRenderer.swift',
   'Label("Export PDF", systemImage: "square.and.arrow.down")',
   'Label { Text("Export PDF") } icon: { AstraIconView(.download, size: 12) }'],
  ['Utilities/MarkdownRenderer.swift',
   'Label("Print", systemImage: "printer")',
   'Label { Text("Print") } icon: { AstraIconView(.print, size: 12) }'],
];

let total = 0;
for (const [file, old, nw] of edits) {
  const p = path.join(src, file);
  let text = fs.readFileSync(p, 'utf8');
  const n = text.split(old).length - 1;
  if (n === 0) {
    console.log('  SKIP: ' + file + ' :: ' + old.slice(0, 60));
    continue;
  }
  text = text.split(old).join(nw);
  fs.writeFileSync(p, text);
  total += n;
  console.log('  ' + file + ': ' + n + 'x');
}
console.log('Total: ' + total);
