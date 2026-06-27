# Painel (Vercel)

Site estático. Basta apontar o Vercel para esta pasta `painel/` ou subir só este conteúdo.

- `index.html` é o painel completo. Não precisa de build.
- Comunica com o bot **somente via Firebase Realtime Database** (HTTPS), então funciona
  perfeitamente no Vercel mesmo com o bot rodando em HTTP na Lunes Host.

## Deploy rápido no Vercel

1. Faça login no Vercel e clique em **Add New → Project**.
2. Suba esta pasta (drag-and-drop) ou conecte um repositório que contenha estes arquivos.
3. Não precisa configurar build — é HTML puro.

## Como usar

1. Abra a URL do Vercel.
2. Digite a chave `igor77`.
3. Escolha QR Code ou Pareamento (com número).
4. Clique em **Solicitar nova conexão** — o bot na Lunes recebe pelo Firebase e devolve o QR/código no card do slot.
