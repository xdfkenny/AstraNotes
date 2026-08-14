// scripts/swap_icons.js
// One-off migration: replaces static `Image(systemName: "x")` usages with
// `AstraIconView(.x, size: N)` across Views/ and DesignSystem/.
// SF name -> AstraIcon case mapping is parsed from AstraIcon.swift comments.
//
// Usage: node scripts/swap_icons.js

const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const iconSource = fs.readFileSync(path.join(root, 'AstraNotes', 'DesignSystem', 'Icons', 'AstraIcon.swift'), 'utf8');

// Build SF name -> AstraIcon case name map from the fromSystemName switch
// (contains the COMPLETE mapping, including deduplicated SF aliases).
const sfToCase = new Map();
const fromSystemMatch = iconSource.match(/static func fromSystemName[\s\S]*?\}/);
if (fromSystemMatch) {
  const re = /case "([^"]+)": return \.(\w+)/g;
  let m;
  while ((m = re.exec(fromSystemMatch[0])) !== null) {
    sfToCase.set(m[1], m[2]);
  }
}
console.log('Mapping loaded: ' + sfToCase.size + ' icons');

function swapFile(file) {
  let text = fs.readFileSync(file, 'utf8');
  let count = 0;
  for (const [sf, caseName] of sfToCase) {
    // Pattern A: Image(systemName: "x") followed by .font(.system(size: N, ...))
    const reA = new RegExp(
      'Image\\(systemName: "' + sf + '"\\s*\\)\\s*\\n\\s*\\.font\\(\\.system\\(size: ([\\d.]+)(?:, weight: [^)]*)?\\)\\)',
      'g'
    );
    text = text.replace(reA, (match, size) => {
      count++;
      return 'AstraIconView(.' + caseName + ', size: ' + size + ')';
    });
    // Pattern B: bare Image(systemName: "x")
    const reB = new RegExp('Image\\(systemName: "' + sf + '"\\)', 'g');
    text = text.replace(reB, () => {
      count++;
      return 'AstraIconView(.' + caseName + ')';
    });
  }
  if (count > 0) {
    fs.writeFileSync(file, text);
    console.log('  ' + file + ': ' + count + ' replacements');
  }
  return count;
}

const targets = [
  path.join(root, 'AstraNotes', 'Views'),
  path.join(root, 'AstraNotes', 'DesignSystem'),
  path.join(root, 'AstraNotes', 'App'),
];

let total = 0;
const files = [];
(function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.swift')) files.push(p);
  }
})(targets.length > 0 ? targets[0] : '.');
for (let i = 1; i < targets.length; i++) {
  (function walk2(dir) {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk2(p);
      else if (e.name.endsWith('.swift')) files.push(p);
    }
  })(targets[i]);
}

for (const f of files) total += swapFile(f);
console.log('Total static replacements: ' + total);
