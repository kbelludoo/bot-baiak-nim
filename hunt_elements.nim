type
  HuntElementProfile* = object
    weaknesses*: seq[string]
    resistances*: seq[string]

proc hasWeakness*(self: HuntElementProfile, element: string): bool =
  for w in self.weaknesses:
    if w == element: return true
  return false

proc hasResistance*(self: HuntElementProfile, element: string): bool =
  for r in self.resistances:
    if r == element: return true
  return false

proc getHuntElementProfile*(huntId: string): HuntElementProfile =
  case huntId
  of "troll-cave": HuntElementProfile(weaknesses: @["fire", "physical"], resistances: @[])
  of "elf-lair": HuntElementProfile(weaknesses: @["fire", "death", "physical"], resistances: @[])
  of "amazon-camp": HuntElementProfile(weaknesses: @["fire", "physical", "ice"], resistances: @[])
  of "minotaur": HuntElementProfile(weaknesses: @["ice", "death", "fire"], resistances: @[])
  of "cyclopolis": HuntElementProfile(weaknesses: @["earth", "death", "ice"], resistances: @["energy"])
  of "refiner-cave": HuntElementProfile(weaknesses: @["energy", "earth", "ice"], resistances: @["physical", "fire"])
  of "giant-spider": HuntElementProfile(weaknesses: @["fire", "ice"], resistances: @["earth"])
  of "glooth-cave": HuntElementProfile(weaknesses: @["physical", "energy", "fire"], resistances: @["earth"])
  of "dragon-lair": HuntElementProfile(weaknesses: @["ice", "earth", "physical"], resistances: @["fire"])
  of "werebadge-cave": HuntElementProfile(weaknesses: @["fire", "holy", "death"], resistances: @["earth"])
  of "hydra-cave": HuntElementProfile(weaknesses: @["energy", "fire", "physical"], resistances: @["earth", "ice"])
  of "wyrm-cave": HuntElementProfile(weaknesses: @["earth", "ice", "physical"], resistances: @["energy", "fire"])
  of "werehyaena-cave": HuntElementProfile(weaknesses: @["fire", "holy", "death"], resistances: @["earth"])
  of "asura-lair": HuntElementProfile(weaknesses: @["ice", "fire", "holy", "death"], resistances: @["earth"])
  of "draken-lair": HuntElementProfile(weaknesses: @["ice", "energy", "earth"], resistances: @["fire"])
  of "cobra-cave": HuntElementProfile(weaknesses: @["ice", "earth", "fire"], resistances: @["energy", "holy"])
  of "undeadragon-lair": HuntElementProfile(weaknesses: @["holy", "fire", "physical"], resistances: @["earth", "death", "ice"])
  of "falcon": HuntElementProfile(weaknesses: @["death", "earth", "ice"], resistances: @["holy", "energy"])
  of "grimeleech-cave": HuntElementProfile(weaknesses: @["holy", "ice", "energy"], resistances: @["fire", "death"])
  of "choking-cave": HuntElementProfile(weaknesses: @["holy", "fire", "energy"], resistances: @["death"])
  of "guzzlemaw-cave": HuntElementProfile(weaknesses: @["holy", "fire", "energy"], resistances: @["death", "earth"])
  else:
    HuntElementProfile(weaknesses: @[], resistances: @[])
