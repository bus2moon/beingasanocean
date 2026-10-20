# Game Design Document (living)

Status: **foundation draft**. Items marked *(proposed)* await the creator's approval.

## Pitch
A third-person, movement-first coming-of-age game. Cub skates, climbs and runs through his hometown at 16. He and his friends turn a garage band into something real, and the story follows him into his twenties and onto bigger stages.

## Pillars
1. **Moving feels good with no objective at all.** Momentum is the currency, and nothing forces a dead stop.
2. **Every place can be traversed.** Walls, rails, roofs and fences are all ways through, not just backdrop.
3. **Music is the reason to move.** You race to rehearsal, sneak into shows and haul gear across town.
4. **The world grows up with Cub.** His age shows in his body, skills, friends, places and soundtrack.

## Core loop *(proposed)*
Explore → find spots, shortcuts, gear and song fragments → missions and sessions → Street Rep plus Band Rep → unlock moves, districts and venues → the next life chapter.

## Signature system: Lines *(proposed)*
Parkour and skate moves feed one combo chain, called a Line. The soundtrack adds stems (instrument layers) while a Line holds and drops them when you bail. This makes music part of the movement without turning the game into a rhythm game. It's built in Phase 3, once skating exists.

## Controls philosophy
- Two primary verbs: **Jump** handles jump, vault, step-up and climb by context. **Parkour** is reserved for wall-run, slide and roll in Phase 2.
- Sprinting into a low obstacle vaults it automatically.
- Players show skill through timing, not button count.

## World *(proposed)*
- Compact, dense districts rather than one large open world.
- Chapter 1 is the hometown: about 4 districts in a 600 × 600 m area.
- Later chapters bring back a changed hometown, plus small tour-city zones built around one venue each.

## Music gameplay *(proposed)*
- Short rehearsal and gig sections with a simple lane-based rhythm game.
- Riffs and lyric scraps are collectibles found while exploring. They unlock songs.
- Gig size grows each chapter.
- All tracks are data (`SongDef` resources), so placeholder audio can be swapped for cleared recordings later.

## Chapters *(proposed — depends on the creator's real timeline)*
Each age gets its own palette. The exact years and events are pending (see NARRATIVE_BIBLE.md).
