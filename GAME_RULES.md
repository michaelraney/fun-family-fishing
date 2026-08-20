# Fishing Game Rules

## Overview

A 2D competitive fishing game for 3 players. Players drop fishing lines into the water to catch fish, compete for the highest score, and try to hook rare bonus targets like whales and treasure chests — while avoiding electric creatures.

## Players and Controls

- **Player 1** (left position) — Press **A** to cast
- **Player 2** (middle position) — Press **G** to cast
- **Player 3** (right position) — Press **L** to cast

## Game Length

- The game lasts **2 minutes** (countdown timer displayed at top center)
- The timer turns yellow at 30 seconds remaining and red at 10 seconds
- The game ends when the timer hits zero OR all players have used all their casts (whichever comes first)

## Casts

- Each player has **10 casts** per game
- A cast cannot be made while the hook is already in the water
- The hook drops at 300 px/sec and reels back up at 250 px/sec
- **Forfeit rule**: If a player does not throw their first hook within the first 45 seconds, they forfeit the game (all remaining casts are lost and "FORFEITED" is displayed)

## Hook Behavior

- The hook drops straight down from the player's position to the bottom
- If no fish is caught on the way down, the hook **waits 1 second** at the bottom before reeling back up
- If a fish is caught (on the way down or at the bottom), the hook **immediately starts reeling back up**
- If the hook enters an open treasure chest, it **immediately starts reeling back up**

## Fish

### Types and Base Scores

| Size   | Base Points | Visual Scale | Spawn Rate |
|--------|-------------|--------------|------------|
| Small  | 10          | 0.6x         | 45%        |
| Medium | 25          | 1.0x         | 35%        |
| Large  | 50          | 1.5x         | 20%        |

### Fish Variety

Fish come in 5 different body shapes:
- Normal (classic fish)
- Round (pufferfish/sunfish)
- Long (eel/barracuda)
- Angel (tall angelfish)
- Flat (flounder)

Fish come in 10 possible colors: orange, blue, golden, red, green, purple, pink, teal, silver, and amber.

### Fish Movement

- Fish swim horizontally across the screen at speeds between 50–300 px/sec
- Fish have a slight vertical wobble as they swim
- Fish swim at random depths between 230–600 pixels from the top
- Fish spawn every 0.4–1.4 seconds
- 8 fish are pre-spawned at game start so the water isn't empty

## Scoring

### Score Formula

```
Score = Base Points x Depth Multiplier x Speed Multiplier
```

- **Depth Multiplier**: 1.0x at the surface, up to 3.0x at the bottom (deeper = more points)
- **Speed Multiplier**: 1.0x for slow fish (50 px/sec), up to 2.5x for fast fish (300 px/sec)

### Bigger Fish Steals the Hook

While the hook is reeling up with a caught fish:
- If a **larger scoring fish** touches the hook, it steals the catch
- The original fish's score is **subtracted** from the player's total (shown as a red flash)
- The new fish's score is **added** (shown as a yellow flash)
- Smaller fish encountered while reeling are ignored

### Score Display

- When a fish is caught, the points flash in big arcade-style yellow text on the player's side
- When a fish is lost (stolen by a bigger fish), the lost points flash in red
- Scores cannot go below zero

### Catch Messages

Arcade-style messages flash alongside the score:

| Catch Type | Messages |
|------------|----------|
| Small fish | "What a guppy!" / "Can't live on shrimp!" / "This is bait!" |
| Medium fish | No message (score only) |
| Large fish | "Whoa momma!" / "We need a bigger boat!" / "Wowzeers!" / "BIG GUY!" |
| Whale | "There she blows!" / "The big momma!" |
| Treasure chest | "Arrr matey!" / "I'm rich!" / "Time to party!" |
| Electric creature | "Oohh that stings!" / "She shocked me!" / "Its electric!" |

## Electric Creatures

- **Electric eels** and **electric jellyfish** swim through the water
- They spawn at a **12% rate** (in place of a regular fish)
- They **blink** with an electric cyan/blue glow and visible sparks
- Electric eels have a long sinuous body; jellyfish have a dome bell with dangling tentacles
- Catching one costs **-50 points** (score cannot go below zero)
- The score flash appears in electric blue

## Treasure Chests

- Each player has a treasure chest sitting on the sand below their fishing line
- Chests open **randomly, roughly twice per minute** (every 20–40 seconds)
- When open, the chest glows gold with sparkles for **3 seconds**
- If the hook enters an open chest, the player receives a bonus of **300 points**
- After being collected or timing out, the chest closes and waits for its next random opening

## Whale

- A large whale appears **once per game** at a random time (between 20–100 seconds in)
- The whale can come from either the left or right side
- The whale swims slowly through the deep water (depth 480–580, speed 30–55 px/sec)
- The whale **can be hooked** — it is worth **105 base points x depth multiplier** (up to 315 points)
- The whale has a large hitbox (160x50 pixels) making it easier to catch
- Because of its high score, the whale will steal the hook from any smaller fish during reeling

## Giant Pink Squid

- A giant pink squid appears **once per game** at a random time (between 20–80 seconds in)
- Unlike the whale and shark, it does **not** swim in from an edge — it **materializes anywhere on the board** (any x across the play area, at a depth of 270–580)
- It **fades in over 3 seconds** while holding still, accompanied by a **shrill squeal**
- During the fade-in it **cannot be caught** — it is off the catchable layer, so a hook passes straight through
- Once fully faded in, it swims toward the **side of the board farthest from where it appeared** at 35–60 px/sec
- It **can be hooked** — worth **105 base points x depth multiplier** (up to 315 points), the same as the whale
- It is drawn at **95% scale**, giving it a 171x72 pixel hitbox
- Catch messages: "Release the kraken!" / "Ten arms of trouble!" / "Ink-credible!" / "That's a big pink one!"

## Bonus Points

Bonuses are awarded after the round ends and are added to the scores to produce the final tally.

| Bonus | Points | Earned by |
|-------|--------|-----------|
| **FIRST DONE!** | 100 per player beaten (**200** when both rivals played it out) | The first player to finish all their casts |
| **ALL 3 BEASTS!** | 100 | Catching the whale, the shark, **and** the squid in one round |
| **TREASURE HUNTER!** | 100 | Collecting **more than one** treasure chest in the round |
| **SHOCK FREE!** | 100 | Hooking **no** electric eels or jellyfish all round |
| **SMALLEST FISH!** | 100 | Landing the **shortest** ordinary fish of the round |
| **BIGGEST FISH!** | 100 | Landing the **longest** ordinary fish of the round |

- A player "finishes casts" when their **last cast is reeled back in**
- A player who **forfeits earns no bonuses at all** — not even SHOCK FREE
- **Forfeited players don't count as players beaten**, so finishing ahead of a forfeiter is
  worth nothing (beat one active rival = 100, beat two = 200, beat only forfeiters = no bonus)
- Only the **first** finisher earns the finish bonus; second place earns nothing for finishing
- If nobody uses all their casts before the timer expires, no finish bonus is awarded

### Size Awards

- Fish are measured **nose to tail tip**, so both the shape and the size class count —
  lengths run from **21.6** (small angelfish) to **105** (large eel), 15 distinct values
- The **whale, shark and squid don't count** for either award, and neither do electric creatures
- **Ties are paid in full** — every player holding the winning length collects the 100 points
- A player who never landed an ordinary fish is out of the running for both awards
- If one player is the only one to land a fish, that fish is both the smallest and the
  biggest, so they collect both awards

### Bonus Screen

- A **BONUS POINTS!** screen appears first, showing all three scores
- Each bonus is then revealed one at a time, about 0.7 seconds apart, as arcade text
  floating up over that player's side of the board (same style as catching a fish)
- Each message stays fully readable for **3 seconds**, then fades out over half a second,
  so several messages can be on screen at once (they stack upward per player)
- Each player's score climbs live as their bonuses land
- The winner and top ten only appear once the last message has faded
- Restarting is locked out until every bonus has been shown

## Game Over

- The game ends when the 2-minute timer expires OR all players use all 10 casts
- The bonus screen runs first, then a large, pulsing, color-cycling arcade text announces
  the winner (or tie) based on the **final tally including bonuses**
- Final scores for all 3 players are displayed
- Because bonuses are added before the winner is decided, they can **change who wins**
- To restart, press **any key except A, G, or L** (prevents accidental restarts from cast buttons)

## Leaderboard

- The **top ten** all-time scores are shown at the end of **every** game, whether or not a new score was added
- Only the **winning score of each game** is eligible — one entry per game, never one per player
- The score submitted is the **final tally including bonus points**
- A score is added only if it **beats the current tenth place** (or the list has fewer than ten entries)
- A score of **0 never qualifies**
- When a score qualifies, the winner types a name of **up to 8 characters** and presses **Enter**
  - Letters and digits only; input is uppercased automatically
  - Submitting an empty name stores **AAA**
  - Restart is disabled while a name is being typed, so cast keys can be used in the name
- The new entry is marked with **`<NEW`** on the list
- Tied scores are ranked below the scores already on the board
- Scores persist between sessions in `user://leaderboard.json`
  (macOS: `~/Library/Application Support/Godot/app_userdata/Fishing Game/leaderboard.json`)
- If a game ends in a tie, one entry is stored for the shared winning score

## Visual Elements

- Animated water with gradient (darker at depth) and wave surface
- Blue sky above the water line
- Sandy bottom with texture detail
- Fish have eyes, tail fins, dorsal fins, and colorful bodies
- Electric eels glow and spark with a sinuous animated body
- Electric jellyfish have a translucent bell with blinking tentacles
- Treasure chests show metal bands, locks, and sparkle effects when open
- Whale has animated tail, dorsal fin, pectoral fin, eye, and rising bubbles
