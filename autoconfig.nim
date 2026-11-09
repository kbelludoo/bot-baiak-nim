import std/[strutils]
import hunt_elements

proc getRecommendedRotation*(voc: string, level: int, huntId: string): seq[string] =
  let v = voc.toLowerAscii()
  let profile = getHuntElementProfile(huntId)

  case v
  of "knight":
    if level >= 90:
      result = @["exori gran", "exori", "exori min", "exori mas"]
    elif level >= 70:
      result = @["exori", "exori min", "exori mas", "exori scu"]
    elif level >= 35:
      result = @["exori", "exori mas", "exori scu", "exori ico"]
    else:
      result = @["exori ico", "exori ico scu", "exori hur", "exori"]
  of "monk":
    if level >= 90:
      result = @["exori gran mas pug", "exori mas pug", "exori mas nia", "exori med pug"]
    elif level >= 60:
      result = @["exori mas pug", "exori mas nia", "exori amp pug", "exori pug"]
    else:
      result = @["exori pug", "exori nia", "exori amp pug", "exori mas pug"]
  of "paladin":
    if profile.hasResistance("holy"):
      if level >= 70:
        result = @["exori gran con", "exori dir moe", "exori con", "exori"]
      else:
        result = @["exori con", "exori", "exori hur", "exori min"]
    elif level >= 70:
      result = @["exevo mas san", "exori dir san", "exori dir moe", "exori gran con"]
    elif level >= 50:
      result = @["exevo mas san", "exori san", "exori con", "utori san"]
    else:
      result = @["exori con", "exori san", "utori san", "exori"]
  of "sorcerer":
    let useEnergy = profile.hasResistance("fire") or (profile.hasWeakness("energy") and not profile.hasWeakness("fire"))
    if useEnergy:
      if level >= 90:
        result = @["exevo gran mas vis", "exori max vis", "exori gran vis", "exevo vis hur"]
      else:
        result = @["exevo vis hur", "exori vis", "exori mort", "exori flam"]
    elif level >= 90:
      result = @["exevo gran mas flam", "exori max flam", "exori gran flam", "exevo vis hur"]
    else:
      result = @["exevo flam hur", "exori flam", "exori vis", "exori mort"]
  of "druid":
    let useEarth = profile.hasResistance("ice") or (profile.hasWeakness("earth") and not profile.hasWeakness("ice"))
    if useEarth:
      if level >= 90:
        result = @["exevo gran mas tera", "exori max tera", "exori gran tera", "exevo tera hur"]
      else:
        result = @["exevo tera hur", "exori tera", "exori mort", "exori frigo"]
    elif level >= 90:
      result = @["exevo gran mas frigo", "exori max frigo", "exori gran frigo", "exevo frigo hur"]
    else:
      result = @["exevo frigo hur", "exori frigo", "exori tera", "exori mort"]
  else:
    result = @["exori ico", "exori hur", "exori"]

proc getRecommendedHeal*(voc: string, level: int): string =
  let v = voc.toLowerAscii()
  case v
  of "knight":
    if level >= 300: "exura gran ico"
    elif level >= 130: "exura med ico"
    else: "exura ico"
  of "paladin":
    if level >= 80: "exura gran san"
    elif level >= 35: "exura san"
    else: "exura"
  of "sorcerer", "druid":
    if level >= 50: "exura vita"
    elif level >= 20: "exura gran"
    else: "exura"
  of "monk":
    if level >= 80: "exura gran pug"
    elif level >= 35: "exura pug"
    else: "exura"
  else:
    "exura"

proc getRecommendedPotions*(level: int): (string, string) =
  let hp = if level >= 260: "supreme health potion"
           elif level >= 200: "ultimate health potion"
           elif level >= 130: "great health potion"
           elif level >= 80: "strong health potion"
           else: "health potion"

  let mp = if level >= 260: "ultimate mana potion"
           elif level >= 130: "great mana potion"
           elif level >= 80: "strong mana potion"
           else: "mana potion"

  (hp, mp)
