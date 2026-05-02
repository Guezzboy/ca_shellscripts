'use strict';
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT ?? 3000;

// Path to the Flutter project's assets/collections/ directory.
// Run from the repo root: node server/index.js
const ASSETS_DIR = path.resolve(
  process.env.ASSETS_DIR ?? path.join(__dirname, '..', 'assets', 'collections'),
);

app.use(cors());
app.use(express.json());

// ── Utilities ─────────────────────────────────────────────────────────────────

function slugify(str) {
  return String(str)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/, '');
}

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Timed out after ${ms}ms`)), ms),
    ),
  ]);
}

const HTTP = axios.create({
  headers: {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
    Accept:
      'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  },
});

// ── Item normalisation ────────────────────────────────────────────────────────

function normalizeItem(raw, index) {
  const name =
    raw.name || raw.title || `Item ${String(index + 1).padStart(3, '0')}`;
  const id = raw.id || slugify(name) || `item-${index + 1}`;
  const images = Array.isArray(raw.images)
    ? raw.images.filter(Boolean)
    : raw.image_url
    ? [raw.image_url]
    : raw.thumbnail
    ? [raw.thumbnail]
    : [];
  return {
    id,
    name,
    subtitle: raw.subtitle ?? raw.number ?? '',
    year: raw.year ?? null,
    series: raw.series ?? null,
    description: raw.description ?? '',
    images,
    owned: false,
    notes: '',
  };
}

function calcImageCompleteness(items) {
  if (!items.length) return 0;
  return items.filter((i) => i.images.length > 0).length / items.length;
}

// ── Source 1: Local asset cache ───────────────────────────────────────────────

function sourceLocal(slug) {
  const fp = path.join(ASSETS_DIR, `${slug}.json`);
  if (!fs.existsSync(fp)) return null;
  try {
    return JSON.parse(fs.readFileSync(fp, 'utf8'));
  } catch {
    return null;
  }
}

// ── Source 2: Coleka.com ──────────────────────────────────────────────────────
// NOTE: CSS selectors below are best-effort. If Coleka updates their markup,
// adjust the selectors here — the rest of the pipeline stays the same.

async function sourceColeka(query) {
  // Step A: search results page
  const searchUrl = `https://www.coleka.com/fr/search?q=${encodeURIComponent(query)}`;
  const searchResp = await HTTP.get(searchUrl, { timeout: 8000 });
  const $s = cheerio.load(searchResp.data);

  // Pick the first collection link from search results.
  // Coleka uses cards with links like /fr/collection/{slug}
  const collectionHref =
    $s('a[href*="/collection/"]').first().attr('href') ??
    $s('.search-result a, .collection-link, h2 a, h3 a').first().attr('href');

  if (!collectionHref) return null;

  const collectionUrl = collectionHref.startsWith('http')
    ? collectionHref
    : `https://www.coleka.com${collectionHref}`;

  // Step B: collection detail page
  const colResp = await HTTP.get(collectionUrl, { timeout: 8000 });
  const $c = cheerio.load(colResp.data);

  const collectionName =
    $c('h1.collection-title, h1.titre, h1').first().text().trim() || query;
  const collectionDesc =
    $c('.collection-description, .description, .texte')
      .first()
      .text()
      .trim();
  const collectionId = slugify(collectionName) || slugify(query);

  // Step C: extract items
  // Coleka item cards are typically inside a grid; each has a name, image, link.
  const items = [];
  $c(
    '.collection-item, .item-card, .vignette, article.item, li.item',
  ).each((i, el) => {
    const $el = $c(el);

    const rawName = $el
      .find('.item-name, .item-title, .nom, h3, h4')
      .first()
      .text()
      .trim();
    if (!rawName) return;

    const thumbSrc =
      $el.find('img').first().attr('data-src') ??
      $el.find('img').first().attr('data-lazy-src') ??
      $el.find('img').first().attr('src') ??
      '';
    const thumb =
      thumbSrc && !thumbSrc.includes('placeholder') && !thumbSrc.includes('no-image')
        ? thumbSrc.startsWith('http')
          ? thumbSrc
          : `https://www.coleka.com${thumbSrc}`
        : null;

    const subtitle = $el
      .find('.item-subtitle, .item-number, .numero, .subtitle')
      .first()
      .text()
      .trim();
    const href = $el.find('a').first().attr('href') ?? '';
    const itemId =
      slugify(href.split('/').filter(Boolean).pop() ?? rawName) ||
      slugify(rawName);

    items.push(
      normalizeItem(
        { id: itemId, name: rawName, subtitle, images: thumb ? [thumb] : [] },
        i,
      ),
    );
  });

  if (!items.length) return null;

  return {
    collection: {
      id: collectionId,
      name: collectionName,
      description: collectionDesc,
      totalItems: items.length,
    },
    items,
    _meta: {
      source: 'coleka',
      imageCompleteness: calcImageCompleteness(items),
      collectionUrl,
    },
  };
}

// ── Source 3: Scaffold fallback ───────────────────────────────────────────────

function sourceScaffold(query) {
  const slug = slugify(query);
  const items = Array.from({ length: 10 }, (_, i) => {
    const n = String(i + 1).padStart(3, '0');
    return {
      id: `${slug}-${n}`,
      name: `Item ${n}`,
      subtitle: '',
      year: null,
      series: null,
      description: '',
      images: [],
      owned: false,
      notes: '',
    };
  });
  return {
    collection: { id: slug, name: query, description: '', totalItems: 10 },
    items,
    _meta: { source: 'scaffold', imageCompleteness: 0 },
  };
}

// ── Route ─────────────────────────────────────────────────────────────────────

app.post('/api/search-collection', async (req, res) => {
  const query = String(req.body?.query ?? '').trim();
  if (!query) return res.status(400).json({ error: 'query is required' });

  const slug = slugify(query);
  const t0 = Date.now();

  // 1. Local asset — synchronous, instant
  const localData = sourceLocal(slug);
  if (localData) {
    if (!localData._meta) localData._meta = {};
    localData._meta.source = 'local';
    localData._meta.imageCompleteness = calcImageCompleteness(
      localData.items ?? [],
    );
    localData._meta.searchMs = Date.now() - t0;
    return res.json(localData);
  }

  // 2. Coleka — async with 8 s hard timeout
  const [colekaSettled] = await Promise.allSettled([
    withTimeout(sourceColeka(query), 8000),
  ]);

  if (colekaSettled.status === 'fulfilled' && colekaSettled.value) {
    const data = colekaSettled.value;
    data._meta.searchMs = Date.now() - t0;
    return res.json(data);
  }

  const reason =
    colekaSettled.status === 'rejected'
      ? colekaSettled.reason?.message ?? 'unknown error'
      : 'no results';
  console.warn(`[coleka] failed for "${query}": ${reason}`);

  // 3. Scaffold
  const scaffold = sourceScaffold(query);
  scaffold._meta.searchMs = Date.now() - t0;
  return res.json(scaffold);
});

app.get('/health', (_, res) => res.json({ ok: true, assetsDir: ASSETS_DIR }));

app.listen(PORT, () =>
  console.log(
    `[collection-proxy] http://localhost:${PORT}  (assets: ${ASSETS_DIR})`,
  ),
);
