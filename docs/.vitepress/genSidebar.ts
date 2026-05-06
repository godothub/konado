import fs from 'fs'
import path from 'path'

interface ScanItem {
  text: string
  link?: string
  items?: ScanItem[]
  collapsed?: boolean
  order?: number
}

interface SidebarItem {
  text: string
  link?: string
  items?: SidebarItem[]
  collapsed?: boolean
}

function parseFrontmatter(content: string): Record<string, any> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const fm: Record<string, any> = {};
  for (const line of match[1].split('\n')) {
    const kv = line.match(/^(\w+):\s*(.+)$/);
    if (kv) {
      let value: any = kv[2].trim();
      if (value === 'true') value = true;
      else if (value === 'false') value = false;
      else if (/^-?\d+$/.test(value)) value = parseInt(value, 10);
      fm[kv[1]] = value;
    }
  }
  return fm;
}

function extractTitle(content: string): string | null {
  const match = content.match(/^#\s+(.+)/m);
  return match ? match[1].trim() : null;
}

function getTitleFromFile(filePath: string): string | null {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const fm = parseFrontmatter(content);
    return fm.title || extractTitle(content);
  } catch {
    return null;
  }
}

function readFrontmatter(filePath: string): Record<string, any> {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    return parseFrontmatter(content);
  } catch {
    return {};
  }
}

/**
 * Scan a directory to build canonical sidebar structure.
 * Used on zh/ to define the full tree.
 */
function scan(dirPath: string, relativePath: string): ScanItem[] {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true }).filter(
    e => !e.name.startsWith('.')
  );

  const items: ScanItem[] = [];

  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith('.md') && entry.name !== 'index.md') {
      const fullPath = path.join(dirPath, entry.name);
      const fm = readFrontmatter(fullPath);
      if (fm.sidebar_hidden) continue;

      const title = fm.title || extractTitle(fs.readFileSync(fullPath, 'utf-8')) || entry.name.replace(/\.md$/, '');
      const link = '/' + path.join(relativePath, entry.name.replace(/\.md$/, '')).replace(/\\/g, '/');

      items.push({
        text: title,
        link,
        order: fm.order !== undefined ? fm.order : 999,
      });
    }

    if (entry.isDirectory()) {
      const indexPath = path.join(dirPath, entry.name, 'index.md');
      if (!fs.existsSync(indexPath)) continue;

      const fm = readFrontmatter(indexPath);
      if (fm.sidebar_hidden) continue;

      const title = fm.title || getTitleFromFile(indexPath) || entry.name;
      const subDir = path.join(dirPath, entry.name);
      const subRelative = path.join(relativePath, entry.name);
      const childItems = scan(subDir, subRelative);

      const group: ScanItem = {
        text: title,
        collapsed: fm.sidebar_collapsed ?? true,
        order: fm.order !== undefined ? fm.order : 999,
      };

      if (childItems.length > 0) {
        group.items = childItems;
      }

      items.push(group);
    }
  }

  // Sort: positive asc → no order → negative desc
  items.sort((a, b) => {
    const ao = a.order ?? 999;
    const bo = b.order ?? 999;
    if (ao >= 0 && bo >= 0) return ao - bo;
    if (ao < 0 && bo < 0) return bo - ao; // descending for negatives
    if (ao < 0) return 1;
    if (bo < 0) return -1;
    return 0;
  });

  return items;
}

/**
 * Build locale-specific sidebar from canonical zh structure.
 * Falls back to zh when locale file is missing.
 */
function buildLocaleSidebar(
  canonical: ScanItem[],
  zhRoot: string,
  localePrefix: string,
  docsRoot: string
): SidebarItem[] {
  return canonical.map(item => {
    if (item.items) {
      // Try to find locale-specific group title from index.md
      let localeGroupText = item.text;
      if (item.items.length > 0) {
        // Derive dir from first child's link: /zh/script/background/background-switch → script/background
        const firstChildLink = item.items[0].link;
        if (firstChildLink) {
          const dirRel = firstChildLink.replace(/^\/zh\//, '').replace(/\/[^/]+$/, '');
          const localeIndex = path.join(docsRoot, localePrefix, dirRel, 'index.md');
          if (fs.existsSync(localeIndex)) {
            const localeFm = readFrontmatter(localeIndex);
            const localeTitle = localeFm.title || getTitleFromFile(localeIndex);
            if (localeTitle) localeGroupText = localeTitle;
          }
        }
      }
      return {
        text: localeGroupText,
        collapsed: item.collapsed,
        items: buildLocaleSidebar(item.items, zhRoot, localePrefix, docsRoot),
      };
    } else {
      // File: check if locale has this file
      const relativeFromZh = item.link!.replace(/^\/zh\//, '');
      const localeFilePath = path.join(docsRoot, localePrefix, relativeFromZh + '.md');

      if (fs.existsSync(localeFilePath)) {
        // Locale file exists: use locale's title
        const fm = readFrontmatter(localeFilePath);
        const title = fm.title || extractTitle(fs.readFileSync(localeFilePath, 'utf-8')) || item.text;
        return {
          text: title,
          link: '/' + localePrefix + '/' + relativeFromZh,
        };
      } else {
        // Locale file missing: fall back to zh's title and link
        return {
          text: item.text,
          link: item.link,
        };
      }
    }
  });
}

export function genZhSidebar(docsRoot: string): SidebarItem[] {
  const zhPath = path.join(docsRoot, 'zh');
  const canonical = scan(zhPath, 'zh');
  return canonical as SidebarItem[];
}

export function genEnSidebar(docsRoot: string): SidebarItem[] {
  const zhPath = path.join(docsRoot, 'zh');
  const canonical = scan(zhPath, 'zh');
  return buildLocaleSidebar(canonical, zhPath, 'en', docsRoot);
}

export function genTcSidebar(docsRoot: string): SidebarItem[] {
  const zhPath = path.join(docsRoot, 'zh');
  const canonical = scan(zhPath, 'zh');
  return buildLocaleSidebar(canonical, zhPath, 'tc', docsRoot);
}
