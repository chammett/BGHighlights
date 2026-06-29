# BGHighlights (BGH)
**The Scales of Fate are Balancing...**

BGHighlights is a competitive, stat-driven, Tarot-themed post-match highlight AddOn for World of Warcraft PvP. Instead of relying on raw, easily-padded numbers, BGHighlights uses statistical analysis (Z-Scores) to compare your performance directly against the lobby average. At the end of a Battleground, the Tarot evaluates the lobby and awards "Arcana" to the players who genuinely impacted the match.

Whether you are solitary defender holding a node, a vanguard healer pushing the frontline, or an objective-focused flag runner, the Tarot sees your contribution. 

## 🔮 Key Features

*   **The Spread (Match Highlights):** At the end of a Battleground, a custom UI reveals the top performers. Medals (Major Arcana) are distributed based on a dynamic weighted ranking system. 
*   **Z-Score Mathematics:** Medals aren't awarded for simply doing the most damage. BGH calculates the standard deviation of the lobby across multiple domains (Kills, Damage, Healing, Objectives, and Momentum). You must mathematically outperform your peers to trigger a medal drop.
*   **Minor Arcana (Combo Multipliers):** Exceptional raw stat performances grant minor cards (Swords, Cups, Wands, Coins) that act as percentage multipliers to your overall Medal Weight.
*   **The Glory Tax:** A built-in diminishing returns mechanic ensures that a single player cannot sweep the board, allowing diverse playstyles to shine.
*   **Collection & Lifetime Stats:** Track your lifetime performance, average Z-scores, and collection of rare, epic, and legendary medal drops across your PvP career.
*   **Inspect Integration:** BGH seamlessly integrates into the native Blizzard Inspect frame, adding an "Arcana" tab so you can view the achievements and lifetime stats of targeted players.

---

## 🛠️ Developer Guide: Code Architecture

BGHighlights is built with modularity in mind. If you are looking to contribute, tweak the balance, or hunt bugs, here is a breakdown of the 6 core files that make up the AddOn.

### 1. `BGH_Init.lua` (The Foundation)
This file handles the AddOn's initialization and database management. It intercepts the `PLAYER_LOGIN` event to set up initial saved variables and broadcast the welcome message. More importantly, it manages the migration engine for updating legacy data structures and handles the security layer (checksum generation) to prevent database tampering.

### 2. `BGH_Math.lua` (The Brain)
This is the statistical utility engine. It contains the logic for iterating over the scoreboard to determine the lobby's mean and variance. It houses the `GetZScore` function, which is the backbone of the AddOn's evaluation logic, alongside the piecewise math used to calculate Minor Arcana multiplier tiers.

### 3. `BGH_Tarot.lua` (The Rulebook)
This file dictates how the game is scored. It contains the `BGHL_MedalRegistry`, which defines the exact statistical thresholds required for every Major Arcana. At the end of a match, this file evaluates the raw data, applies synthetic proxies (like the "Isolation Bonus" or "Triage Index"), calculates final Weights, applies the Glory Tax, and sorts the winning medals for rendering.

### 4. `BGH_Core.lua` (The Harvester)
The Core is responsible for actively listening to the game. It registers battleground events, parses the native Blizzard scoreboard, and reads PvP chat channels to manually track objective interactions (like flag pickups or node assaults) that the default UI obscures. It packages all of this raw data into a matrix and feeds it to the Tarot engine when the match ends.

### 5. `BGH_UI.lua` (The Canvas)
This file constructs the standalone BGHighlights interface. It builds the primary `BGHighlightsMainFrame`, handles the tab navigation (The Spread, My Arcana, Info, Dev, Settings), and generates the pagination logic for viewing historical matches. It also contains the pool-based rendering logic for dynamically animating the glowing medal rows. 

### 6. `BGH_Network.lua` (The Communicator)
This file manages all outbound and inbound communication between players. It enforces version control by silently pinging the lobby and generating kill-switch alerts if a user is out of date. Furthermore, it intercepts Blizzard's `Blizzard_InspectUI` load event to inject the custom "Arcana" tab into the character sheet, handling the serialization, transmission, and rendering of another player's lifetime stats over the AddOn messaging channel.

---

## 🤝 Contributing
Feedback, bug reports, and pull requests are highly encouraged as the scales of fate are always being balanced. If you find a stat-padding exploit, or feel a specific class is dominating a certain medal, open an issue!
