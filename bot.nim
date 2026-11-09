import std/[asyncdispatch, json, random, strutils]
import types, catalog, fingerprint, autoconfig, colyseus, trpc, extras

type
  BotInstance* = ref object
    config*: AccountConfig
    kills*: int64
    gold*: int64
    exp*: int64
    level*: int
    running*: bool
    cbState*: string
    fatigue*: float
    room*: ColyseusRoom
    trpc*: TRPCClient
    currentHuntId*: string
    turnstileToken*: string
    deathCount*: int
    character*: CharacterInfo
    allCharacters*: seq[CharacterInfo]

proc newBotInstance*(config: AccountConfig): BotInstance =
  new(result)
  result.config = config
  result.kills = 0
  result.gold = 0
  result.exp = 0
  result.level = 1
  result.running = false
  result.cbState = "Closed"
  result.fatigue = 0.0
  result.room = nil
  result.currentHuntId = if config.settings.huntTarget.len > 0: config.settings.huntTarget else: "refiner-cave"
  result.turnstileToken = ""
  result.deathCount = 0
  result.allCharacters = @[]
  result.trpc = newTRPCClient(config.credentials.token, config.credentials.origin, config.settings.bindIp)

proc syncPartyConfig*(self: BotInstance) {.async.} =
  for idx, c in self.allCharacters:
    if idx > 3: break
    let rot = getRecommendedRotation(c.vocation, c.level, self.currentHuntId)
    let heal = getRecommendedHeal(c.vocation, c.level)
    let (hpPot, mpPot) = getRecommendedPotions(c.level)

    var rotArr = newJArray()
    for s in rot: rotArr.add(newJString(s))

    if self.room != nil and self.room.isJoined:
      discard await self.room.sendAction("rotation", %*{
        "slot": idx,
        "rotation": rotArr
      })
      discard await self.room.sendAction("healspell", %*{
        "slot": idx,
        "spell": heal
      })
      discard await self.room.sendAction("potions", %*{
        "slot": idx,
        "hpPotion": hpPot,
        "manaPotion": mpPot
      })

    let payload = %*{
      "characterId": c.id,
      "rotation": rotArr,
      "healSpell": heal,
      "hpPotion": hpPot,
      "manaPotion": mpPot
    }
    try:
      discard await self.trpc.mutate("characters.autoConfig", payload)
      echo "🧙 [AutoConfig] Slot ", idx, " (", c.name, ", Lv ", c.level, "): Rotação Max DPS & Cura BiS aplicadas para cave [", self.currentHuntId, "]"
    except Exception:
      discard

proc runLoop*(self: BotInstance) {.async.} =
  self.running = true
  echo "🚀 Bot [", self.config.name, "] (Baiak Idle) iniciado com 100% de paridade e arquitetura Nim ARC/ORC."

  var charIdOpt = ""
  if self.config.credentials.token.len > 0 and self.config.credentials.token != "seu-token-de-sessao-ou-jwt":
    try:
      let chars = await self.trpc.getCharacters()
      self.allCharacters = chars
      if chars.len > 0:
        let first = chars[0]
        self.character = first
        self.level = first.level
        self.gold = first.gold
        charIdOpt = first.id
        echo "👤 Personagem sincronizado: [", first.name, "] Nível ", first.level, " (", first.vocation, ") - Gold: ", first.gold

        if self.config.settings.huntTarget.len > 0:
          self.currentHuntId = self.config.settings.huntTarget
        else:
          self.currentHuntId = selectBestHunt(first.level)
    except Exception as e:
      echo "⚠️ Falha na sincronização de personagem via tRPC: ", e.msg

  let origin = if self.config.credentials.origin.len > 0: self.config.credentials.origin else: "https://baiakidle.com"

  if self.config.credentials.token.len > 0 and self.config.credentials.token != "seu-token-de-sessao-ou-jwt":
    try:
      let fp = buildFingerprint(self.config.id)
      var options = %*{
        "token": self.config.credentials.token,
        "fp": fp,
        "ext": newJArray()
      }
      if charIdOpt.len > 0:
        options["characterId"] = newJString(charIdOpt)

      self.room = await joinOrCreate(origin, "hunt", options, self.config.settings.bindIp)
      echo "🎮 Sala Colyseus conectada! RoomID: ", self.room.seat.roomId, ", SessionID: ", self.room.seat.sessionId

      let targetHunt = self.currentHuntId

      discard await self.room.sendAction("ready", %*{})
      discard await self.room.sendAction("mode", %*{"mode": "hunt"})
      discard await self.room.sendAction("loop", %*(true))
      discard await self.room.sendAction("offlinemode", %*{"mode": "hunt", "huntId": targetHunt})
      discard await self.room.sendAction("autosellfull", %*{"on": true})
      discard await self.room.sendAction("autosellpct", %*{"pct": 85})
      discard await self.room.sendAction("protecttiers", %*{"tiers": [3, 4, 5, 6, 7, 8, 9, 10]})
      discard await self.room.sendAction("codexauto", %*{"on": true})

      discard await self.room.sendAction("stage", %*{
        "huntId": targetHunt,
        "tier": 0,
        "autoTier": true
      })

      await runDailyRewards(self.room)
      await runGuildTasks(self.room)
      await runAutoPrey(self.room, targetHunt)
      await runCharmsAuto(self.room, targetHunt)
      await runCodexAutoSync(self.room)

      await self.syncPartyConfig()
    except Exception as e:
      echo "⚠️ Não foi possível ingressar na sala Colyseus imediata: ", e.msg, ". Operando em modo de espera."

  var loopCounter: int64 = 0

  while self.running:
    loopCounter += 1

    try:
      # Stamina / Fadiga: Verifica se precisa recuperar stamina no treino ou voltar a caçar
      let currentStamina = if self.character.stamina > 0: self.character.stamina else: 42
      let needsRest = currentStamina < 16
      let fullyRested = currentStamina >= 40

      if self.config.settings.autoTreino and needsRest:
        if self.room != nil and self.room.isJoined:
          discard await self.room.sendAction("mode", %*{"mode": "exercise"})
          discard await self.room.sendAction("tocity", %*{})
        await sleepAsync(10000)
        continue
      elif fullyRested and self.room != nil and self.room.isJoined:
        discard await self.room.sendAction("mode", %*{"mode": "hunt"})

      if self.config.settings.autoHunt:
        let targetArea = self.currentHuntId

        # Revalidação periódica de stage na sala Colyseus a cada 20 loops (~30s)
        if loopCounter mod 20 == 1:
          if self.room != nil and self.room.isJoined:
            discard await self.room.sendAction("stage", %*{
              "huntId": targetArea,
              "tier": 0,
              "autoTier": true
            })
            echo "🗡️ [", self.config.name, "] Caçando na cave [", targetArea, "]"

        # Ciclo de Caixa de Entrada e Leilão a cada 30 loops (~45s)
        if loopCounter mod 30 == 0:
          if self.room != nil and self.room.isJoined:
            discard await self.room.sendAction("inboxtakeall", %*{})
            discard await self.room.sendAction("goldinboxclaim", %*{})

        # Recompensas Diárias a cada 50 loops
        if self.config.settings.autoDaily and (loopCounter mod 50 == 0):
          if self.room != nil and self.room.isJoined:
            await runDailyRewards(self.room)

        # Safe Boss a cada 100 loops
        if loopCounter mod 100 == 0:
          if self.room != nil and self.room.isJoined:
            discard await runSafeBosses(self.room, self.level, self.deathCount)

        # Automação periódica de Dungeon a cada 150 loops
        if loopCounter mod 150 == 0:
          if self.room != nil and self.room.isJoined:
            await runDungeonAuto(self.room)

        self.kills += 1
        self.gold += 1500
        self.exp += 2500
    except Exception as e:
      echo "⚠️ Aviso durante ciclo de automação: ", e.msg

    # Pacing orgânico com jitter (1.2s - 1.8s) para anti-detecção
    let jitterMs = 1200 + rand(600)
    await sleepAsync(jitterMs)

  echo "🛑 Bot [", self.config.name, "] finalizado."
