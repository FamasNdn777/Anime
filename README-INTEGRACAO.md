# Draksyon — Frontend (modo Termux + APK)

Os HTMLs em `public/` agora são **idênticos aos embutidos no APK**
(`aide-android/app/src/main/assets/`). Você pode rodá-los de duas formas:

## 1. Termux / Node.js (modo dev)

```sh
node server.js
# acesse http://localhost:8080
```

O `server.js` continua igual: serve `public/`, expõe `/proxy` e `/stream`.

## 2. APK (modo produção)

Use o projeto `aide-android-adapted`. O servidor Java embutido cumpre
exatamente o mesmo contrato:

| Frontend usa  | Servido por (Termux)   | Servido por (APK)         |
|---------------|------------------------|---------------------------|
| `/`           | `server.js` (public/)  | `ServerService.java` (assets/) |
| `/proxy?url=` | `server.js`            | `ServerService.java`      |
| `/stream?url=`| `server.js`            | `ServerService.java`      |

Como ambos servem na **mesma origem do WebView**, **nenhuma mudança nos
HTMLs é necessária** — `fetch('/proxy?url=...')` simplesmente funciona.
