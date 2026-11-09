# ⚡ Bot Baiak Idle — Native Nim Engine (ARC/ORC)

Multi-account automation engine for **Baiak Idle** rewritten in native **Nim 2.2** with zero-overhead memory management (`--mm:orc`), asynchronous WebSocket & Colyseus RPC, and complete parity with Go and Rust implementations.

---

## 🚀 Características & Paridade 100%

- **Colyseus Room Socket**: Handshake com opcode 10 (`OP_JOIN_ROOM`) e serialização MessagePack (`OP_ROOM_DATA`) nativa via `msgpack4nim`.
- **tRPC API Integration**: Sincronização de personagens (`characters.list`), rotações (`characters.autoConfig`), e hunts (`hunts.enter`).
- **DPS & Cura BiS**: Otimização automática de spells por vocação (Knight, Paladin, Monk, Sorcerer, Druid) e resistências elementais da cave alvo.
- **Pacing Orgânico Anti-Detecção**: Jitter gaussiano contínuo (1.2s - 1.8s) e pausas de clique humano (300ms - 600ms) sem pausas offline forçadas.
- **Dashboard Telemetria HTTP (Porta 8090)**: Status JSON em `/api/status`, injeção de tokens Turnstile em `/api/ticket` e ações dinâmicas em `/api/action`.

---

## 🛠️ Compilação Cruzada (Cross-Compilation via Zig)

```bash
nim c --os:linux --cpu:amd64 --gcc.exe:zigcc-linux-gnu.bat --gcc.linkerexe:zigcc-linux-gnu.bat -d:ssl -d:release -o:bot-baiak-linux-nim main.nim
```

---

## ⚙️ Configuração

Copie o arquivo `accounts.example.json` para `accounts.json` e configure suas credenciais:

```bash
cp accounts.example.json accounts.json
```
