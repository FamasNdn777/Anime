# DRAKSYON ANIMES - Projeto Corrigido v4

## Estrutura do Projeto

### 📁 webapp/
Arquivos HTML do frontend - devem ficar no seu servidor (Vercel, etc.)
- `index.html` — Tela principal com lista de animes (dublados, legendados, lançamentos, categorias)
- `detalhes.html` — Detalhes do anime (sinopse, gêneros, lista de episódios)
- `player-animes.html` — Player de vídeo com seleção de qualidade

### 📁 aide-android/
Projeto Android (AIDE IDE) - O APK que roda no celular
- **MainActivity.java** — WebView que carrega o frontend do seu servidor
- **ServerService.java** — Servidor HTTP local (porta 3000) que faz scraping dos animes
- **PlayerActivity.java** — Activity fullscreen para reprodução de vídeo

### 📁 servidor-node/
Servidor Node.js alternativo (para rodar no PC/VPS)
- `server.js` — Mesmo servidor que roda no APK, mas em Node.js com Express

## Como Funciona

1. O APK inicia o `ServerService` na porta 3000 (API local)
2. O `MainActivity` carrega os HTMLs do seu servidor remoto (Vercel)
3. Os HTMLs fazem chamadas para `http://127.0.0.1:3000/api/...` (API local do APK)
4. O ServerService faz scraping do AnimeFire (S1) e AnimesOnline (S2)

## Configuração

### No APK (MainActivity.java):
Altere a variável `FRONTEND_URL` para o URL do seu servidor:
```java
private static final String FRONTEND_URL = "https://seu-servidor.vercel.app/";
```

### Nos HTMLs:
A variável `API_BASE` já está configurada para `http://127.0.0.1:3000` (API local do APK).

## Fluxo de Navegação
```
index.html → detalhes.html?anime=SLUG → player-animes.html?anime=SLUG&ep=LINK&nome=NOME&idx=N
```

## Endpoints da API (porta 3000)

### Servidor 1 (AnimeFire):
- GET /api/categorias
- GET /api/dublados?page=1
- GET /api/legendados?page=1
- GET /api/lancamentos?page=1
- GET /api/genero/:genero?page=1
- GET /api/detalhes?anime=SLUG
- GET /api/player?link=URL
- GET /api/pesquisar?q=TERMO

### Servidor 2 (AnimesOnline):
- GET /api/s2/categorias
- GET /api/s2/dublados?page=1
- GET /api/s2/legendados?page=1
- GET /api/s2/lancamentos?page=1
- GET /api/s2/genero/:genero?page=1
- GET /api/s2/detalhes?anime=SLUG
- GET /api/s2/player?link=URL
- GET /api/s2/pesquisar?q=TERMO
