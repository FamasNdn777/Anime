const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
const chalk = require('chalk');

const app = express();

/* ============================================================
   SISTEMA DE LOGS PROFISSIONAL
   ============================================================ */

function timestamp() {
    const now = new Date();
    const d = now.toLocaleDateString('pt-BR');
    const t = now.toLocaleTimeString('pt-BR', { hour12: false });
    const ms = String(now.getMilliseconds()).padStart(3, '0');
    return `${d} ${t}.${ms}`;
}

const log = {
    info: (tag, msg) =>
        console.log(chalk.gray(`[${timestamp()}]`) + ' ' + chalk.cyan.bold(`[${tag}]`) + ' ' + chalk.white(msg)),
    success: (tag, msg) =>
        console.log(chalk.gray(`[${timestamp()}]`) + ' ' + chalk.green.bold(`[${tag}]`) + ' ' + chalk.greenBright(msg)),
    warn: (tag, msg) =>
        console.log(chalk.gray(`[${timestamp()}]`) + ' ' + chalk.yellow.bold(`[${tag}]`) + ' ' + chalk.yellowBright(msg)),
    error: (tag, msg) =>
        console.log(chalk.gray(`[${timestamp()}]`) + ' ' + chalk.red.bold(`[${tag}]`) + ' ' + chalk.redBright(msg)),
    request: (method, path, status, duration) => {
        const statusColor = status < 400 ? chalk.green : status < 500 ? chalk.yellow : chalk.red;
        console.log(
            chalk.gray(`[${timestamp()}]`) + ' ' +
            chalk.magenta.bold('[REQ]') + ' ' +
            chalk.bold(method) + ' ' +
            chalk.white(path) + ' → ' +
            statusColor.bold(status) + ' ' +
            chalk.gray(`(${duration}ms)`)
        );
    },
    scrape: (server, url, count) =>
        console.log(
            chalk.gray(`[${timestamp()}]`) + ' ' +
            chalk.blue.bold(`[SCRAPE ${server}]`) + ' ' +
            chalk.white(url) + ' → ' +
            chalk.greenBright.bold(`${count} resultados`)
        ),
};

app.use(cors());
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        log.request(req.method, req.originalUrl, res.statusCode, duration);
    });
    next();
});

// Servir arquivos HTML estáticos
app.use(express.static(__dirname + '/../webapp'));

const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
};

/* ============================================================
   SERVIDOR 1 — AnimeFire (animefire.io)
   ============================================================ */

async function scrapeAnimeFire(url, res) {
    try {
        log.info('S1', `Scraping: ${url}`);
        const { data } = await axios.get(url, { headers, timeout: 10000 });
        const $ = cheerio.load(data);
        const animes = [];
        $('article.cardUltimosEps').each((i, el) => {
            const link = $(el).find('a').attr('href');
            const titulo = $(el).find('.animeTitle').text().trim();
            const capa = $(el).find('img').attr('data-src') || $(el).find('img').attr('src');
            if (link && titulo) {
                animes.push({ titulo, slug: link.split('/').pop(), capa: capa || '' });
            }
        });
        log.scrape('S1', url, animes.length);
        if (animes.length === 0) log.warn('S1', 'Nenhum resultado encontrado');
        res.json(animes);
    } catch (e) {
        log.error('S1', `Falha ao acessar ${url}: ${e.message}`);
        res.status(500).json({ erro: "Erro ao conectar com a fonte (AnimeFire)" });
    }
}

app.get('/api/categorias', (req, res) => {
    const categorias = [
        { slug: 'acao', nome: 'Ação' },{ slug: 'aventura', nome: 'Aventura' },
        { slug: 'comedia', nome: 'Comédia' },{ slug: 'drama', nome: 'Drama' },
        { slug: 'ecchi', nome: 'Ecchi' },{ slug: 'fantasia', nome: 'Fantasia' },
        { slug: 'harem', nome: 'Harem' },{ slug: 'horror', nome: 'Horror' },
        { slug: 'isekai', nome: 'Isekai' },{ slug: 'josei', nome: 'Josei' },
        { slug: 'magia', nome: 'Magia' },{ slug: 'mecha', nome: 'Mecha' },
        { slug: 'militar', nome: 'Militar' },{ slug: 'misterio', nome: 'Mistério' },
        { slug: 'musical', nome: 'Musical' },{ slug: 'policial', nome: 'Policial' },
        { slug: 'psicologico', nome: 'Psicológico' },{ slug: 'romance', nome: 'Romance' },
        { slug: 'samurai', nome: 'Samurai' },{ slug: 'sci-fi', nome: 'Sci-Fi' },
        { slug: 'seinen', nome: 'Seinen' },{ slug: 'shoujo', nome: 'Shoujo' },
        { slug: 'shounen', nome: 'Shounen' },{ slug: 'slice-of-life', nome: 'Slice of Life' },
        { slug: 'sobrenatural', nome: 'Sobrenatural' },{ slug: 'sports', nome: 'Esportes' },
        { slug: 'super-poder', nome: 'Super Poder' },{ slug: 'suspense', nome: 'Suspense' },
        { slug: 'terror', nome: 'Terror' },{ slug: 'vida-escolar', nome: 'Vida Escolar' }
    ];
    log.success('S1', `Categorias enviadas: ${categorias.length} gêneros`);
    res.json(categorias);
});

app.get('/api/genero/:genero', (req, res) => {
    const page = req.query.page || 1;
    scrapeAnimeFire(`https://animefire.io/genero/${req.params.genero}/${page}`, res);
});

app.get('/api/legendados', (req, res) => {
    scrapeAnimeFire(`https://animefire.io/lista-de-animes-legendados/${req.query.page || 1}`, res);
});

app.get('/api/dublados', (req, res) => {
    scrapeAnimeFire(`https://animefire.io/lista-de-animes-dublados/${req.query.page || 1}`, res);
});

app.get('/api/lancamentos', (req, res) => {
    scrapeAnimeFire(`https://animefire.io/em-lancamento/${req.query.page || 1}`, res);
});

app.get('/api/detalhes', async (req, res) => {
    const slug = req.query.anime;
    if (!slug) return res.status(400).json({ erro: 'Parâmetro "anime" é obrigatório' });

    try {
        const url = `https://animefire.io/animes/${slug}`;
        log.info('S1', `Buscando detalhes: ${slug}`);
        const { data } = await axios.get(url, { headers, timeout: 10000 });
        const $ = cheerio.load(data);

        const titulo = $('h1.quicksand400, .animeHeaderTitulo h1, h1').first().text().trim() || slug;
        const capa = $('meta[property="og:image"]').attr('content') ||
                     $('.sub_animepage_img img').attr('data-src') ||
                     $('.sub_animepage_img img').attr('src') || '';
        const sinopse = $('.divSinopse, .sinopse_container_content, .animeDescription').first().text().trim() || '';

        let ano = '', estudio = '';
        $('.animeInfo span, .spanAnimeInfo').each((i, el) => {
            const txt = $(el).text().trim();
            if (/^\d{4}$/.test(txt)) ano = txt;
        });
        $('.animeInfo a, .spanAnimeInfo a').each((i, el) => {
            const href = $(el).attr('href') || '';
            if (href.includes('estudio') || href.includes('studio')) estudio = $(el).text().trim();
        });

        const generos = [];
        $('a[href*="/genero/"], .animeGen a').each((i, el) => {
            const g = $(el).text().trim();
            if (g && !generos.includes(g)) generos.push(g);
        });

        const episodios = [];
        $('a.lEp, .div_video_list a, a[href*="animefire.io/video"]').each((i, el) => {
            const link = $(el).attr('href') || '';
            const nome = $(el).text().trim() || `Episódio ${i + 1}`;
            const epCapa = $(el).find('img').attr('data-src') || $(el).find('img').attr('src') || '';
            if (link) episodios.push({ nome, link, capa: epCapa });
        });

        log.success('S1', `"${titulo}" — ${episodios.length} eps, ${generos.length} gêneros`);
        res.json({ titulo, capa, sinopse, ano, estudio, generos, episodios });
    } catch (e) {
        log.error('S1', `Detalhes falhou para "${slug}": ${e.message}`);
        res.status(500).json({ erro: "Erro ao buscar detalhes do anime (AnimeFire)" });
    }
});

// ===== ENDPOINT PLAYER S1 — AnimeFire =====
app.get('/api/player', async (req, res) => {
    const link = req.query.link;
    if (!link) return res.status(400).json({ erro: 'Parâmetro "link" é obrigatório' });

    try {
        log.info('S1', `Buscando player: ${link}`);
        const { data } = await axios.get(link, { headers, timeout: 10000 });
        const $ = cheerio.load(data);

        const videoEl = $('video#my-video, video.video-js, video[data-video-src]').first();
        const videoSrcUrl = videoEl.attr('data-video-src') || '';

        let sources = [];
        let iframe = '';

        if (videoSrcUrl) {
            try {
                const fullUrl = videoSrcUrl.startsWith('http') ? videoSrcUrl : 'https://animefire.io' + videoSrcUrl;
                log.info('S1', `Buscando fontes de vídeo: ${fullUrl}`);
                const videoRes = await axios.get(fullUrl, {
                    headers: { ...headers, 'Referer': link, 'Accept': 'application/json, text/plain, */*' },
                    timeout: 10000
                });

                const vData = videoRes.data;
                if (vData && Array.isArray(vData.data)) {
                    sources = vData.data.map(s => ({
                        url: s.src || s.url || '',
                        label: s.label || s.quality || '',
                        quality: s.label || s.quality || ''
                    })).filter(s => s.url);
                } else if (vData && typeof vData === 'object' && vData.src) {
                    sources = [{ url: vData.src, label: 'Default', quality: 'Default' }];
                } else if (typeof vData === 'string') {
                    const urlMatches = vData.match(/https?:\/\/[^\s"'<>]+\.m3u8[^\s"'<>]*/gi) ||
                                       vData.match(/https?:\/\/[^\s"'<>]+\.mp4[^\s"'<>]*/gi) || [];
                    sources = urlMatches.map((u, i) => ({ url: u, label: 'Fonte ' + (i + 1), quality: 'Fonte ' + (i + 1) }));
                }
            } catch (e2) {
                log.warn('S1', `Falha ao buscar fontes de vídeo: ${e2.message}`);
            }
        }

        if (sources.length === 0) {
            const iframeSrc = $('iframe[src*="player"], iframe[src*="embed"], iframe[src*="video"]').first().attr('src') || '';
            if (iframeSrc) iframe = iframeSrc.startsWith('http') ? iframeSrc : 'https:' + iframeSrc;
        }

        if (sources.length === 0) {
            $('video source').each((i, el) => {
                const src = $(el).attr('src');
                const label = $(el).attr('label') || $(el).attr('size') || 'Fonte ' + (i + 1);
                if (src) sources.push({ url: src, label, quality: label });
            });
        }

        log.success('S1', `Player: ${sources.length} fontes, iframe: ${iframe ? 'sim' : 'não'}`);
        res.json({ sources, iframe });
    } catch (e) {
        log.error('S1', `Player falhou para "${link}": ${e.message}`);
        res.status(500).json({ erro: "Erro ao buscar player do episódio" });
    }
});


// ===== ENDPOINT PESQUISA S1 — AnimeFire (busca global por tela) =====
app.get('/api/pesquisar', async (req, res) => {
    const q = String(req.query.q || '').trim();
    const scope = String(req.query.scope || 'all').trim().toLowerCase();
    const genero = String(req.query.genero || '').trim().toLowerCase();
    const fallbackPages = Math.min(Math.max(parseInt(req.query.pages || '12', 10) || 12, 1), 30);

    if (!q) return res.status(400).json({ erro: 'Parametro "q" obrigatorio' });

    function normalizeText(value) {
        return String(value || '')
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .toLowerCase()
            .trim();
    }

    function getLetterToken(value) {
        const normalized = normalizeText(value);
        const firstChar = normalized.charAt(0);
        if (!firstChar) return 'a';
        if (/[0-9]/.test(firstChar)) return '0-9';
        if (/[a-z]/.test(firstChar)) return firstChar;
        return 'a';
    }

    async function scrapeAnimeFirePage(url) {
        const { data } = await axios.get(url, { headers, timeout: 12000 });
        const $ = cheerio.load(data);
        const animes = [];
        $('article.cardUltimosEps').each((i, el) => {
            const link = $(el).find('a').attr('href');
            const titulo = $(el).find('.animeTitle').text().trim();
            const capa = $(el).find('img').attr('data-src') || $(el).find('img').attr('src');
            if (link && titulo) {
                animes.push({ titulo, slug: link.split('/').pop(), capa: capa || '' });
            }
        });
        return animes;
    }

    async function collectUnique(urls) {
        const settled = await Promise.allSettled(urls.map(scrapeAnimeFirePage));
        const unique = [];
        const seen = new Set();
        settled.forEach((result, index) => {
            if (result.status !== 'fulfilled') return;
            result.value.forEach((anime) => {
                if (!anime.slug || seen.has(anime.slug)) return;
                seen.add(anime.slug);
                unique.push(anime);
            });
        });
        return unique;
    }

    function filterMatches(items) {
        const normalizedQuery = normalizeText(q);
        return items.filter((anime) => normalizeText(anime.titulo).includes(normalizedQuery));
    }

    function buildPrimaryUrls() {
        const letter = getLetterToken(q);
        if (scope === 'dublados') return [`https://animefire.io/lista-de-animes-dublados/${letter}`];
        if (scope === 'legendados') return [`https://animefire.io/lista-de-animes-legendados/${letter}`];
        if (scope === 'lancamentos') return Array.from({ length: Math.min(fallbackPages, 8) }, (_, i) => `https://animefire.io/em-lancamento/${i + 1}`);
        if (scope === 'genero' && genero) return Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/genero/${encodeURIComponent(genero)}/${i + 1}`);
        return [
            `https://animefire.io/lista-de-animes-dublados/${letter}`,
            `https://animefire.io/lista-de-animes-legendados/${letter}`,
            'https://animefire.io/em-lancamento/1',
            'https://animefire.io/em-lancamento/2'
        ];
    }

    function buildFallbackUrls() {
        if (scope === 'dublados') return Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/lista-de-animes-dublados/${i + 1}`);
        if (scope === 'legendados') return Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/lista-de-animes-legendados/${i + 1}`);
        if (scope === 'lancamentos') return Array.from({ length: Math.min(fallbackPages, 8) }, (_, i) => `https://animefire.io/em-lancamento/${i + 1}`);
        if (scope === 'genero' && genero) return Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/genero/${encodeURIComponent(genero)}/${i + 1}`);
        return [
            ...Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/lista-de-animes-dublados/${i + 1}`),
            ...Array.from({ length: fallbackPages }, (_, i) => `https://animefire.io/lista-de-animes-legendados/${i + 1}`),
            ...Array.from({ length: Math.min(fallbackPages, 8) }, (_, i) => `https://animefire.io/em-lancamento/${i + 1}`)
        ];
    }

    try {
        log.info('S1', `Pesquisa global: "${q}" | escopo=${scope || 'all'}`);
        const primaryResults = filterMatches(await collectUnique(buildPrimaryUrls()));
        if (primaryResults.length > 0) {
            log.success('S1', `Pesquisa "${q}" encontrou ${primaryResults.length} resultado(s) na busca primária`);
            return res.json(primaryResults);
        }
        const fallbackResults = filterMatches(await collectUnique(buildFallbackUrls()));
        log.success('S1', `Pesquisa "${q}" encontrou ${fallbackResults.length} resultado(s) no fallback`);
        return res.json(fallbackResults);
    } catch (e) {
        log.error('S1', `Pesquisa falhou: ${e.message}`);
        return res.status(500).json({ erro: 'Erro na pesquisa do AnimeFire' });
    }
});

/* ============================================================
   SERVIDOR 2 — Animes Online (animesonlinecc.to)
   ============================================================
   CORREÇÕES APLICADAS:
   1. Seletor de imagem com fallback: data-src > data-lazy-src > src
   2. Seletor de título com fallback: .data h3 a > .data h3 > img[alt]
   3. /api/s2/lancamentos corrigido para URL certa (não legendado)
   4. Detalhes: múltiplos fallbacks para capa, título, sinopse
   5. Player: múltiplos fallbacks para iframe/video
   ============================================================ */

const S2_BASE = 'https://animesonlinecc.to';

// Helper para extrair imagem com múltiplos fallbacks (DooPlay lazy-load)
function extractImg($el) {
    const img = $el.find('.poster img, .thumbnail img, img').first();
    return img.attr('data-src')
        || img.attr('data-lazy-src')
        || img.attr('data-original')
        || img.attr('srcset')?.split(',')[0]?.trim()?.split(' ')[0]
        || img.attr('src')
        || '';
}

// Helper para extrair título com múltiplos fallbacks
function extractTitle($el) {
    return $el.find('.data h3 a').text().trim()
        || $el.find('.data h3').text().trim()
        || $el.find('h3 a').text().trim()
        || $el.find('h3').text().trim()
        || $el.find('.poster img, img').first().attr('alt')?.trim()
        || $el.find('a').attr('title')?.trim()
        || '';
}

// Helper para extrair link/slug
function extractSlugAndHref($el) {
    const href = $el.find('.poster a, a').first().attr('href') || '';
    const slug = href.replace(/\/$/, '').split('/').pop() || '';
    return { href, slug };
}

async function scrapeAnimesOnline(url, res) {
    try {
        log.info('S2', `Scraping: ${url}`);
        const { data } = await axios.get(url, { headers, timeout: 15000 });
        const $ = cheerio.load(data);
        const animes = [];
        const seen = new Set();

        // Seletor principal do DooPlay + fallbacks
        $('article.item, article.item.tvshows, .result-item, .search-page .result-item, div.TPost').each((i, el) => {
            const $el = $(el);
            const { href, slug } = extractSlugAndHref($el);
            const titulo = extractTitle($el);
            const capa = extractImg($el);

            if (slug && titulo && !seen.has(slug)) {
                seen.add(slug);
                animes.push({ titulo, slug, capa });
            }
        });

        log.scrape('S2', url, animes.length);
        if (animes.length === 0) log.warn('S2', 'Nenhum resultado encontrado — possível Cloudflare ou estrutura alterada');
        res.json(animes);
    } catch (e) {
        log.error('S2', `Falha ao acessar ${url}: ${e.message}`);
        if (e.response && e.response.status === 403) {
            log.warn('S2', 'HTTP 403 — Cloudflare bloqueando. Tente do celular.');
        }
        res.status(500).json({ erro: "Erro ao conectar com a fonte (Animes Online)" });
    }
}

app.get('/api/s2/categorias', (req, res) => {
    const categorias = [
        { slug: 'acao', nome: 'Ação' },{ slug: 'aventura', nome: 'Aventura' },
        { slug: 'comedia', nome: 'Comédia' },{ slug: 'drama', nome: 'Drama' },
        { slug: 'ecchi', nome: 'Ecchi' },{ slug: 'fantasia', nome: 'Fantasia' },
        { slug: 'harem', nome: 'Harem' },{ slug: 'horror', nome: 'Horror' },
        { slug: 'isekai', nome: 'Isekai' },{ slug: 'josei', nome: 'Josei' },
        { slug: 'magia', nome: 'Magia' },{ slug: 'mecha', nome: 'Mecha' },
        { slug: 'militar', nome: 'Militar' },{ slug: 'misterio', nome: 'Mistério' },
        { slug: 'musical', nome: 'Musical' },{ slug: 'policial', nome: 'Policial' },
        { slug: 'psicologico', nome: 'Psicológico' },{ slug: 'romance', nome: 'Romance' },
        { slug: 'samurai', nome: 'Samurai' },{ slug: 'sci-fi', nome: 'Sci-Fi' },
        { slug: 'seinen', nome: 'Seinen' },{ slug: 'shoujo', nome: 'Shoujo' },
        { slug: 'shounen', nome: 'Shounen' },{ slug: 'slice-of-life', nome: 'Slice of Life' },
        { slug: 'sobrenatural', nome: 'Sobrenatural' },{ slug: 'sports', nome: 'Esportes' },
        { slug: 'super-poder', nome: 'Super Poder' },{ slug: 'suspense', nome: 'Suspense' },
        { slug: 'terror', nome: 'Terror' },{ slug: 'vida-escolar', nome: 'Vida Escolar' }
    ];
    res.json(categorias);
});

app.get('/api/s2/genero/:genero', (req, res) => {
    const page = req.query.page || 1;
    const pageUrl = page > 1 ? `${S2_BASE}/genero/${req.params.genero}/page/${page}/` : `${S2_BASE}/genero/${req.params.genero}/`;
    scrapeAnimesOnline(pageUrl, res);
});

app.get('/api/s2/legendados', (req, res) => {
    const page = req.query.page || 1;
    const pageUrl = page > 1 ? `${S2_BASE}/genero/legendado/page/${page}/` : `${S2_BASE}/genero/legendado/`;
    scrapeAnimesOnline(pageUrl, res);
});

app.get('/api/s2/dublados', (req, res) => {
    const page = req.query.page || 1;
    const pageUrl = page > 1 ? `${S2_BASE}/genero/dublado/page/${page}/` : `${S2_BASE}/genero/dublado/`;
    scrapeAnimesOnline(pageUrl, res);
});

// FIX: Lançamentos agora usa a URL correta do site, NÃO a de legendados
app.get('/api/s2/lancamentos', (req, res) => {
    const page = req.query.page || 1;
    // Tentar múltiplas rotas possíveis do DooPlay
    const pageUrl = page > 1 ? `${S2_BASE}/lancamentos/page/${page}/` : `${S2_BASE}/lancamentos/`;
    
    // Tentativa com fallback: se /lancamentos/ não funcionar, tenta a home
    (async () => {
        try {
            log.info('S2', `Scraping lancamentos: ${pageUrl}`);
            const { data } = await axios.get(pageUrl, { headers, timeout: 15000 });
            const $ = cheerio.load(data);
            const animes = [];
            const seen = new Set();

            $('article.item, article.item.tvshows, div.TPost').each((i, el) => {
                const $el = $(el);
                const { slug } = extractSlugAndHref($el);
                const titulo = extractTitle($el);
                const capa = extractImg($el);
                if (slug && titulo && !seen.has(slug)) {
                    seen.add(slug);
                    animes.push({ titulo, slug, capa });
                }
            });

            if (animes.length > 0) {
                log.scrape('S2', pageUrl, animes.length);
                return res.json(animes);
            }

            // Fallback: tentar a homepage que geralmente lista lançamentos
            log.warn('S2', 'Lancamentos vazio, tentando homepage como fallback...');
            const fallbackUrl = page > 1 ? `${S2_BASE}/page/${page}/` : `${S2_BASE}/`;
            const { data: data2 } = await axios.get(fallbackUrl, { headers, timeout: 15000 });
            const $2 = cheerio.load(data2);

            $2('article.item, article.item.tvshows, div.TPost').each((i, el) => {
                const $el = $2(el);
                const { slug } = extractSlugAndHref($el);
                const titulo = extractTitle($el);
                const capa = extractImg($el);
                if (slug && titulo && !seen.has(slug)) {
                    seen.add(slug);
                    animes.push({ titulo, slug, capa });
                }
            });

            log.scrape('S2', fallbackUrl, animes.length);
            res.json(animes);
        } catch (e) {
            log.error('S2', `Falha em lancamentos: ${e.message}`);
            res.status(500).json({ erro: "Erro ao conectar com a fonte (Animes Online)" });
        }
    })();
});

app.get('/api/s2/detalhes', async (req, res) => {
    const slug = req.query.anime;
    if (!slug) return res.status(400).json({ erro: 'Parâmetro "anime" é obrigatório' });

    try {
        const url = `${S2_BASE}/anime/${slug}/`;
        log.info('S2', `Buscando detalhes: ${slug}`);
        const { data } = await axios.get(url, { headers, timeout: 15000 });
        const $ = cheerio.load(data);

        // Título com múltiplos fallbacks
        let titulo = $('.sheader .data h1').first().text().trim()
            || $('h1.entry-title').first().text().trim()
            || $('h1').first().text().trim()
            || $('meta[property="og:title"]').attr('content')?.trim()
            || slug;
        titulo = titulo.replace(/ Todos os Episodios Online$/i, '').replace(/ Online$/i, '').trim();

        // Capa com múltiplos fallbacks
        const capa = $('meta[property="og:image"]').attr('content')
            || $('.sheader .poster img').attr('data-src')
            || $('.sheader .poster img').attr('data-lazy-src')
            || $('.sheader .poster img').attr('src')
            || $('img.wp-post-image').attr('data-src')
            || $('img.wp-post-image').attr('src')
            || '';

        // Sinopse com fallbacks
        const sinopse = $('.resumotemp .wp-content p').first().text().trim()
            || $('.wp-content p').first().text().trim()
            || $('meta[property="og:description"]').attr('content')?.trim()
            || '';

        let ano = '';
        const dateSpan = $('.sheader .extra .date').text().trim();
        if (/^\d{4}$/.test(dateSpan)) ano = dateSpan;

        const generos = [];
        $('.sgeneros a').each((i, el) => {
            const g = $(el).text().trim();
            if (g && g !== 'Legendado' && g !== 'Dublado' && !g.startsWith('Letra ') && !generos.includes(g)) generos.push(g);
        });

        const episodios = [];
        // Seletor principal DooPlay + fallbacks
        $('.episodios li, #episodios li, .episodelist li').each((i, el) => {
            const linkEl = $(el).find('.episodiotitle a, .numerando + .episodiotitle a, a').first();
            const link = linkEl.attr('href') || '';
            const nome = linkEl.text().trim()
                || $(el).find('.numerando').text().trim()
                || `Episódio ${i + 1}`;
            const epCapa = $(el).find('.imagen img').attr('data-src')
                || $(el).find('.imagen img').attr('data-lazy-src')
                || $(el).find('.imagen img').attr('src')
                || $(el).find('img').attr('src')
                || '';
            if (link) episodios.push({ nome, link, capa: epCapa });
        });

        log.success('S2', `"${titulo}" — ${episodios.length} eps, ${generos.length} gêneros`);
        res.json({ titulo, capa, sinopse, ano, estudio: '', generos, episodios });
    } catch (e) {
        log.error('S2', `Detalhes falhou para "${slug}": ${e.message}`);
        res.status(500).json({ erro: "Erro ao buscar detalhes do anime (Animes Online)" });
    }
});


// ===== ENDPOINT PESQUISA S2 — Animes Online =====
app.get('/api/s2/pesquisar', (req, res) => {
    const q = req.query.q;
    if (!q) return res.status(400).json({ erro: 'Parametro "q" obrigatorio' });
    scrapeAnimesOnline(`${S2_BASE}/?s=${encodeURIComponent(q)}`, res);
});

// ===== ENDPOINT PLAYER S2 — Animes Online =====
app.get('/api/s2/player', async (req, res) => {
    const link = req.query.link;
    if (!link) return res.status(400).json({ erro: 'Parâmetro "link" é obrigatório' });

    try {
        log.info('S2', `Buscando player: ${link}`);
        const { data } = await axios.get(link, { headers, timeout: 15000 });
        const $ = cheerio.load(data);

        let sources = [];
        let iframe = '';

        // DooPlay usa iframes - múltiplos seletores
        const iframeSrc = $('iframe[src*="player"], iframe[src*="embed"], iframe[src*="video"], .playex iframe, #playex iframe, .dooplay_player iframe, #dooplay_player_response iframe, .player iframe').first().attr('src')
            || $('iframe').first().attr('src')
            || '';
        if (iframeSrc && (iframeSrc.includes('player') || iframeSrc.includes('embed') || iframeSrc.includes('video') || iframeSrc.includes('http'))) {
            iframe = iframeSrc.startsWith('http') ? iframeSrc : 'https:' + iframeSrc;
        }

        // Tentar extrair vídeos diretos
        $('video source, source[src*=".mp4"], source[src*=".m3u8"]').each((i, el) => {
            const src = $(el).attr('src');
            const label = $(el).attr('label') || $(el).attr('size') || 'Fonte ' + (i + 1);
            if (src) sources.push({ url: src, label, quality: label });
        });

        // Tentar extrair URLs de vídeo do script inline
        if (sources.length === 0 && !iframe) {
            const scripts = $('script').map((i, el) => $(el).html()).get().join('\n');
            const videoUrls = scripts.match(/https?:\/\/[^\s"'<>]+\.(mp4|m3u8)[^\s"'<>]*/gi) || [];
            sources = videoUrls.map((u, i) => ({ url: u, label: 'Fonte ' + (i + 1), quality: 'Fonte ' + (i + 1) }));
        }

        log.success('S2', `Player: ${sources.length} fontes, iframe: ${iframe ? 'sim' : 'não'}`);
        res.json({ sources, iframe });
    } catch (e) {
        log.error('S2', `Player falhou para "${link}": ${e.message}`);
        res.status(500).json({ erro: "Erro ao buscar player do episódio" });
    }
});

/* ============================================================
   INICIAR SERVIDOR
   ============================================================ */
app.listen(3000, '0.0.0.0', () => {
    console.log('');
    console.log(chalk.bgMagenta(chalk.white.bold('  🐉 DRAKSYON SERVER — ONLINE 🐉  ')));
    console.log('');
    console.log(chalk.cyan('  📡 Porta:    ') + chalk.white.bold('3000'));
    console.log(chalk.cyan('  🔥 S1:       ') + chalk.white('AnimeFire'));
    console.log(chalk.cyan('  🌐 S2:       ') + chalk.white('Animes Online'));
    console.log('');
    log.success('SISTEMA', 'Aguardando requisições...');
});
