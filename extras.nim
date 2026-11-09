import std/[asyncdispatch, json, random]
import types, catalog, colyseus

const SafeBossCatalog*: seq[SafeBoss] = @[
  SafeBoss(id: "shadowpelt", name: "Shadowpelt", minLevel: 5),
  SafeBoss(id: "darkfang", name: "Darkfang", minLevel: 15),
  SafeBoss(id: "bloodback", name: "Bloodback", minLevel: 15),
  SafeBoss(id: "black_vixen", name: "Black Vixen", minLevel: 20),
  SafeBoss(id: "sharpclaw", name: "Sharpclaw", minLevel: 20),
  SafeBoss(id: "utua_stone_sting", name: "Utua Stone Sting", minLevel: 35),
  SafeBoss(id: "amenef_the_burning", name: "Amenef the Burning", minLevel: 50),
  SafeBoss(id: "brokul", name: "Brokul", minLevel: 50),
  SafeBoss(id: "scarlett", name: "Scarlett Etzel", minLevel: 80),
  SafeBoss(id: "ahau", name: "Ahau", minLevel: 60),
  SafeBoss(id: "kusuma", name: "Kusuma", minLevel: 60),
  SafeBoss(id: "brain_head", name: "Brain Head", minLevel: 70),
  SafeBoss(id: "neferi_the_spy", name: "Neferi the Spy", minLevel: 70),
  SafeBoss(id: "drume", name: "Drume", minLevel: 90),
  SafeBoss(id: "oberon", name: "Grand Master Oberon", minLevel: 100)
]

proc runSafeBosses*(room: ColyseusRoom, playerLevel: int, recentDeaths: int): Future[bool] {.async.} =
  if recentDeaths > 0 or playerLevel < 120 or room == nil:
    return false

  for b in SafeBossCatalog:
    if playerLevel >= b.minLevel * 2 and playerLevel >= b.minLevel + 50:
      discard await room.sendAction("boss", %*{
        "bossId": b.id,
        "fromCity": false
      })
      echo "⚔️ [Auto-Boss] Iniciando combate com boss seguro: ", b.name, " (Lv ", b.minLevel, ")"
      return true
  return false

proc runDailyRewards*(room: ColyseusRoom) {.async.} =
  if room == nil: return
  discard await room.sendAction("dailyclaim", %*{})
  await sleepAsync(300 + rand(300))
  discard await room.sendAction("bpclaim", %*{})
  await sleepAsync(300 + rand(300))
  discard await room.sendAction("reward", %*{"action": "collectall"})
  await sleepAsync(300 + rand(300))
  discard await room.sendAction("sellreward", %*{})
  echo "🎁 [Daily] Resgatadas recompensas diárias, missões e baús com pacing humano"

proc runAutoPrey*(room: ColyseusRoom, currentHuntId: string) {.async.} =
  if room == nil: return
  let (found, facts) = getHuntFacts(currentHuntId)
  if not found or facts.monsters.len == 0: return
  let targetMob = facts.monsters[0]
  if targetMob.len == 0: return

  discard await room.sendAction("prey", %*{
    "slot": 0,
    "action": "pick",
    "monsterKey": targetMob
  })
  discard await room.sendAction("prey", %*{
    "slot": 0,
    "action": "lock"
  })
  echo "🎯 [Prey] Presa vinculada ao monstro '", targetMob, "' (Hunt: ", facts.name, ")"

proc runGuildTasks*(room: ColyseusRoom) {.async.} =
  if room == nil: return
  discard await room.sendAction("guildtaskflush", %*{})
  echo "🛡️ [Guild] Tarefas sincronizadas com a guilda"

proc runCharmsAuto*(room: ColyseusRoom, currentHuntId: string) {.async.} =
  if room == nil: return
  let (found, facts) = getHuntFacts(currentHuntId)
  if not found or facts.monsters.len == 0: return
  for i in 0 ..< min(3, facts.monsters.len):
    discard await room.sendAction("charmassign", %*{
      "charmId": i,
      "monsterKey": facts.monsters[i]
    })

proc runDungeonAuto*(room: ColyseusRoom) {.async.} =
  if room == nil: return
  discard await room.sendAction("dgAuto", %*{})
  echo "🏰 [Dungeon] Automação periódica de dungeon despachada"

proc runCodexAutoSync*(room: ColyseusRoom) {.async.} =
  if room == nil: return
  discard await room.sendAction("codexauto", %*{"on": true})
