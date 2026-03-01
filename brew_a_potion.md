

GAME DESIGN DOCUMENT & IMPLEMENTATION ROADMAP

**BREW A POTION**

A Cozy Alchemy Simulator for Roblox

From Zero to Launch in 8 Weeks

Complete Systems Design, Economy Model, Development Phases & Hiring Guide

February 2026 | Version 1.0

# **1\. GAME VISION & CORE CONCEPT**

## **1.1 Elevator Pitch**

Brew a Potion is a cozy alchemy simulator where players gather magical ingredients, discover potion recipes through experimentation, and build a potion shop empire. Think Grow a Garden meets a crafting system — the same idle-collect-sell loop that drove 21 billion visits, but with a combination/discovery mechanic that adds depth and shareability.

## **1.2 Design Pillars**

**Pillar 1 — 60-Second Hook:** A brand new player must understand the core loop (gather, brew, sell, upgrade) within their first minute. No tutorials, no text walls. The environment teaches through affordance, exactly like Grow a Garden.

**Pillar 2 — Discovery & Surprise:** Combining ingredients produces unpredictable results. Rare combinations create visually spectacular potions that players screenshot and share. Every brewing session has the potential for a viral moment.

**Pillar 3 — Identity Through Your Shop:** Your potion shop is your expression. Shelves, cauldrons, decorations, and rare potion displays let players show status and taste. This is Brookhaven-style identity spending applied to a sim.

**Pillar 4 — Always Something New:** Weekly ingredient drops, seasonal events, and rotating shop stock create appointment play and FOMO, the two most powerful retention drivers on Roblox.

## **1.3 Target Audience**

Primary: Ages 9–17, the core Roblox demographic who drove Grow a Garden to 21M+ CCU. They want cozy, social, collectible-driven experiences with visual flair.

Secondary: Ages 13–25, the growing older demographic (44% of Roblox users are 17+). The alchemy/fantasy theme has broader appeal than farming, and the crafting depth attracts players who want more than idle clicking.

# **2\. CORE GAMEPLAY LOOP**

| THE LOOP IN ONE SENTENCE: Gather ingredients → Brew potions in your cauldron → Sell potions for Coins → Buy better ingredients & equipment → Discover rarer recipes → Upgrade your shop → Repeat |
| :---- |

## **2.1 Gather Ingredients**

Players visit the Ingredient Market (equivalent to Grow a Garden's Seed Shop). The market has a rotating stock that refreshes every 5 minutes — the exact mechanic that creates urgency in Grow a Garden. Common ingredients are always available; rare and mythic ingredients appear randomly in limited quantities.

Ingredients have 4 properties: Element (Fire, Water, Earth, Air, Shadow, Light), Potency (Common through Divine), Freshness (degrades over time, encouraging active play), and a hidden Affinity tag that determines combination outcomes.

**Ingredient Rarity Tiers**

| Tier | Examples | Market Cost | Availability | Potion Value Multiplier |
| :---- | :---- | :---- | :---- | :---- |
| Common | Mushroom, Fern Leaf, River Water | 5–20 Coins | Always in stock | 1x |
| Uncommon | Moonpetal, Ember Root, Crystal Dust | 50–150 Coins | 60% chance per refresh | 2.5x |
| Rare | Dragon Scale, Phoenix Feather, Void Essence | 300–800 Coins | 15% chance per refresh | 8x |
| Mythic | Starfall Shard, Leviathan Tear, Time Sand | 2,000–5,000 Coins | 3% chance per refresh | 25x |
| Divine | Philosopher's Stone Fragment, Cosmic Ember | Robux Only or Event | Event/Premium only | 100x |

## **2.2 Brew Potions**

The cauldron is the central mechanic. Players drag 2–4 ingredients into a cauldron, stir (a simple click/tap interaction), and wait for the brew timer. What comes out depends on the combination of ingredients and their properties.

This is the key differentiator from Grow a Garden: instead of planting a seed and waiting for a known outcome, players experiment with combinations and discover new recipes. The first time a player discovers a rare recipe, they get a dramatic visual reveal — the kind of moment that gets screenshotted and posted on TikTok.

**Brewing System Rules**

**Known Recipes:** Once a player discovers a combination, it's saved to their Recipe Book. They can rebrew it anytime. This gives returning players efficiency while preserving the discovery thrill for new content.

**Mutation System:** Any brew has a chance to mutate based on weather conditions, cauldron quality, and random chance. Mutations include Glowing, Bubbling, Crystallized, Shadow, Rainbow, and Golden variants. Mutations multiply sell value by 2x–10x. This directly mirrors Grow a Garden's Wet/Gold/Rainbow mutation system.

**Brew Timer:** Common potions take 2–3 minutes. Rare potions take 5–10 minutes. Mythic potions take 15–30 minutes. This pacing mirrors the crop growth times that keep Grow a Garden players checking back.

**Failed Brews:** Bad combinations produce 'Sludge' worth minimal coins. This creates a risk/reward dynamic and makes discoveries feel earned.

**Recipe Discovery Matrix (Example)**

| Ingredient A | Ingredient B | Result | Sell Value | Discovery Rarity |
| :---- | :---- | :---- | :---- | :---- |
| Mushroom | River Water | Healing Salve | 25 Coins | Common (most will find) |
| Ember Root | Crystal Dust | Fire Shield Elixir | 180 Coins | Uncommon |
| Phoenix Feather | Moonpetal | Rebirth Potion | 1,200 Coins | Rare (bragging rights) |
| Dragon Scale | Time Sand | Chrono Draught | 8,500 Coins | Mythic (TikTok moment) |
| Starfall Shard | Cosmic Ember | Wish Potion | 50,000 Coins | Divine (legendary flex) |

The full recipe book at launch should contain approximately 50–75 discoverable recipes across all tiers, with 5–10 new recipes added with each weekly update.

## **2.3 Sell Potions**

Players sell potions at the Trading Post. Base prices are fixed per recipe, but a Daily Demand Board shows 3 potions with 2x–5x bonus value that day. This rotating demand creates strategic decisions about what to brew and mirrors the dynamic market pricing that keeps idle sim economies interesting.

Global announcements when a player brews a Divine-tier potion ("\[PlayerName\] just brewed a Wish Potion\!") create social proof and aspiration, exactly like Grow a Garden's global harvest announcements.

## **2.4 Upgrade & Expand**

Players spend coins on: better cauldrons (faster brew times, higher mutation chance), more brewing stations (brew multiple potions simultaneously), ingredient storage expansion, and shop decorations that display their rarest potions.

The progression curve should feel generous for the first 30 minutes (hook phase), then gradually slow to create natural monetization friction points — the same approach Grow a Garden uses with sprinkler tiers and garden plot expansion.

# **3\. SOCIAL & VIRAL MECHANICS**

Grow a Garden's most underappreciated feature is its social PvP (crop stealing) and gifting. These mechanics generate the emotional stories that fuel TikTok content. Brew a Potion needs equivalent systems.

## **3.1 Potion Effects on Other Players**

Certain potions can be used ON other players in the shared world. A Speed Potion makes someone run fast. A Shrink Potion makes them tiny. A Rainbow Potion changes their color. A Stink Potion creates a visual cloud around them. These effects are temporary (30–60 seconds), harmless, and inherently funny. They create the exact kind of moments that drive TikTok clips.

## **3.2 Ingredient Stealing**

Like Grow a Garden's crop stealing mechanic, players can attempt to snag rare ingredients from another player's storage — but only if that player hasn't locked their supply chest (a purchasable upgrade). This creates mischief, drama, and defensive strategy. It also creates content: 'Someone stole my Dragon Scale\!' videos are guaranteed engagement.

## **3.3 Gifting & Trading**

Players can gift potions to friends. Drinking a gifted potion together triggers a special visual effect. A lightweight trading system lets players exchange ingredients they don't need for ones they want. Trading creates community, repeat visits, and reasons to communicate.

## **3.4 Shareable Moments by Design**

**Visual spectacle:** Rare potion brews produce dramatic particle effects, screen shakes, and color explosions visible to nearby players.

**Global announcements:** Divine and Mythic discoveries are broadcast server-wide with the player's name.

**Shop tours:** Other players can walk into your shop and see your potion collection on display. Your shop is your profile.

**Weekly leaderboards:** Most valuable potions brewed, most recipes discovered, most impressive shop — all visible and reset weekly.

# **4\. MAP & ENVIRONMENT DESIGN**

The game world is a magical village with 4 core areas. Players teleport between them using buttons at the top of the screen (same UX pattern as Grow a Garden). The village should feel cozy and atmospheric — warm lighting, magical particle effects, ambient sounds of bubbling cauldrons and chirping creatures.

## **4.1 The Four Zones**

**Your Shop (Home Base):** A personal instance where your cauldron, storage, ingredient racks, and potion display shelves live. This is where you spend 60% of your time. Fully customizable. Other players can visit your shop. Equivalent to your garden in Grow a Garden.

**The Ingredient Market:** A shared NPC shop area where you buy ingredients. Stock refreshes every 5 minutes. Has a cozy market-stall aesthetic with lanterns and hanging herbs. This is where urgency and scarcity mechanics live.

**The Trading Post:** Where you sell potions and check the Daily Demand Board. Also where player-to-player trading happens. Social hub energy.

**The Wild Grove (Foraging Area):** An optional open area where players can gather free common ingredients by walking around and clicking on glowing plants/rocks/pools. This gives free-to-play players a grind path and creates exploration content. New forageable spots appear with weather events.

# **5\. MONETIZATION DESIGN**

Every monetization decision is modeled on what's working in Grow a Garden and other top-10 Roblox games. The philosophy is friction-based conversion: never paywall content, but make premium options feel like smart shortcuts.

## **5.1 Dual Currency System**

**Coins (Free Currency):** Earned by selling potions, completing daily quests, and foraging. Used for common/uncommon ingredients, basic cauldron upgrades, and some shop decorations.

**Gems (Premium Currency):** Purchased with Robux. Used for rare/divine ingredients, premium cauldrons, exclusive shop decorations, and convenience features. Also obtainable in tiny amounts through gameplay (1–2 per day via quests) so free players feel included.

## **5.2 Revenue Streams**

**Game Passes (One-Time Purchases)**

| Pass Name | Price (Robux) | What It Does | Conversion Driver |
| :---- | :---- | :---- | :---- |
| Auto-Brew Pass | 299 | Cauldrons continue brewing while AFK | Time-saving for active players |
| Double Storage | 199 | 2x ingredient and potion storage slots | Resolves inventory friction at mid-game |
| VIP Shop Theme | 499 | Exclusive animated shop decorations | Status/identity flex |
| Supply Lock | 149 | Locks your ingredient chest from thieves | Protection from social PvP grief |
| Recipe Hint Book | 99 | Shows vague hints for undiscovered recipes | Removes frustration for stuck players |

**Developer Products (Repeatable Purchases)**

| Product | Price (Robux) | What It Does |
| :---- | :---- | :---- |
| Gem Pack (50 Gems) | 49 | Instant premium currency |
| Gem Pack (250 Gems) | 199 | Bulk premium currency (20% bonus) |
| Gem Pack (750 Gems) | 499 | Large premium currency (50% bonus) |
| Instant Brew | 19 | Skip one brew timer completely |
| Rare Ingredient Crate | 99 | Random rare+ ingredient |
| Mutation Charm | 49 | Guarantees mutation on next brew |

**Subscriptions & Recurring Revenue**

Private Servers at 100 Robux/month are essential. In Grow a Garden, private servers are one of the biggest revenue drivers because players want a safe, theft-free environment. Brew a Potion should offer the same, with the added benefit that private server owners can control weather events (which affect mutations).

**Rewarded Video Ads**

For players aged 13+, offer optional 15-30 second video ads in exchange for: 1 free Gem, a 10-minute brew speed boost, or 1 extra ingredient market refresh. Brookhaven reportedly earns five figures monthly from rewarded ads alone. This monetizes the 95%+ of players who never spend Robux.

## **5.3 Revenue Projections**

| CONSERVATIVE REVENUE MODEL At 5,000 sustained CCU (small hit): \~$3,000-$8,000/month At 20,000 sustained CCU (medium hit): \~$15,000-$40,000/month At 100,000+ sustained CCU (breakout hit): \~$100,000-$300,000+/month Based on ARPDAU of $0.08-$0.15 (industry average for Roblox idle sims) These ranges include game passes, dev products, private servers, and ad revenue |
| :---- |

# **6\. RETENTION & LIVE OPS PLAN**

Grow a Garden's retention secret is that something new happens every week. The game doesn't just exist — it evolves. Brew a Potion must replicate this cadence from day one.

## **6.1 Daily Hooks (Why Come Back Today)**

**Daily Demand Board:** 3 potions with bonus sell prices, rotating every 24 hours. Players check daily to see if they can profit.

**Free Daily Gem:** Log in and claim 1 Gem. 7-day streak \= 10 bonus Gems. Simple but effective.

**Offline Brewing:** Potions continue brewing while you're gone. Coming back to a finished batch of potions feels rewarding (same as Grow a Garden's offline crop growth).

## **6.2 Weekly Hooks (Why Come Back This Week)**

**New Ingredient Drop:** Every Saturday, 1-2 new ingredients appear in the market, enabling new recipe discoveries. Teased on social media Thursday/Friday. This mirrors Grow a Garden's weekend event strategy that drives 20M+ CCU surges.

**Weekly Brewing Challenge:** Brew a specific potion for bonus rewards. Creates shared community goals.

**Leaderboard Reset:** Weekly leaderboards for most valuable potions brewed, most recipes discovered, etc.

## **6.3 Seasonal Events (Why Come Back This Month)**

Monthly themed events introduce limited-time ingredients, exclusive recipes, and cosmetic rewards. Examples: Halloween (Spooky Ingredients, Ghost Potion, Haunted Shop theme), Winter (Frost Crystals, Blizzard Elixir, Snow decorations), Valentine's (Love Potion, Heart Cauldron). Events last 2-3 weeks and create intense FOMO.

## **6.4 Content Cadence Summary**

| Cadence | Content Drop | Purpose |
| :---- | :---- | :---- |
| Daily | Demand Board rotation, daily quest, free Gem | Habit formation |
| Every 5 Min | Ingredient market refresh | Session urgency (micro-FOMO) |
| Weekly (Saturday) | 1-2 new ingredients, new recipes, event teasers | Appointment play & CCU spikes |
| Bi-Weekly | Brewing challenge, leaderboard season | Community engagement |
| Monthly | Seasonal event with exclusive content | Re-engagement & FOMO |
| Quarterly | Major update (new zone, mechanic, or system) | Press coverage & returning players |

# **7\. DEVELOPMENT ROADMAP**

The goal is an 8-week sprint from zero to public launch. This is aggressive but achievable with a 2-3 person team, because the core systems are mechanically simple. Grow a Garden was built in 3 days by a solo teen developer — you don't need perfection at launch, you need a tight loop and fast iteration.

## **Phase 1: Foundation (Weeks 1–2)**

**Goal: Playable core loop with placeholder art**

**Week 1 — Infrastructure:** Set up Roblox Studio project, data store architecture (player inventory, recipe book, shop state, currency), basic server/client framework. Build the ingredient market with rotating stock (5-minute refresh timer, rarity-weighted random selection). This is the most critical system to get right early because it drives the entire economy.

**Week 2 — Brewing System:** Build the cauldron interaction (drag ingredients, stir animation, brew timer, result calculation). Implement the recipe lookup system (ingredient combination \-\> result mapping). Create 15-20 starter recipes. Build the sell interface at the Trading Post. At the end of Week 2, a player should be able to: buy ingredients, brew a potion, sell it, and buy more ingredients. The loop must work.

## **Phase 2: Depth & Polish (Weeks 3–4)**

**Goal: Systems that create retention and monetization**

**Week 3 — Progression & Economy:** Implement cauldron upgrade tiers (4 tiers, each with faster brew times and higher mutation chance). Build shop customization system (place shelves, display potions, buy decorations). Add the mutation system (random mutations based on weather, cauldron tier, and luck). Tune the economy: make sure a new player earns enough in 10 minutes to feel progress, but runs into natural friction by 30 minutes.

**Week 4 — Monetization:** Implement Gem currency and Robux purchase flow. Build game passes (Auto-Brew, Double Storage, VIP Shop, Supply Lock). Add developer products (Gem packs, Instant Brew, Mutation Charm). Set up private server support. Implement the Daily Demand Board and daily quest system. Add the daily login Gem reward.

## **Phase 3: Social & Viral (Weeks 5–6)**

**Goal: Mechanics that make people share the game**

**Week 5 — Social Systems:** Build potion effects on other players (Speed, Shrink, Rainbow, etc.). Implement ingredient stealing and the Supply Lock defense. Add gifting system. Build the global announcement system for rare discoveries. Make other players' shops visitable.

**Week 6 — Visual Polish:** This is the most important polish week. Add particle effects for rare brews. Create the dramatic reveal animation for new recipe discoveries. Polish the cauldron brewing animation. Add ambient environment effects (bubbling sounds, magical particles, weather). The game needs to LOOK good in a TikTok clip. Invest heavily here.

## **Phase 4: Launch Prep (Weeks 7–8)**

**Goal: Soft launch, test, then full launch**

**Week 7 — Testing & Tuning:** Internal playtesting with 10-20 testers. Fix exploits (especially economy exploits — duplication, speed hacks). Tune the ingredient rarity rates. Tune potion sell values. Ensure the new player experience flows smoothly. Set up analytics to track: session length, retention (D1/D7/D30), conversion rate, ARPDAU, most/least brewed potions.

**Week 8 — Launch:** Soft launch on a Wednesday or Thursday (mid-week launches let you fix bugs before the weekend traffic spike). Prepare your first Saturday ingredient drop for Day 3-4. Have a Discord server ready for community feedback. Begin TikTok content strategy (see Section 9). If metrics look good after the first weekend, begin scaling marketing.

| CRITICAL LAUNCH CHECKLIST ✓ Core loop works flawlessly on mobile, PC, and Xbox ✓ Economy feels rewarding for first 30 minutes, creates friction by 60 minutes ✓ At least 30 discoverable recipes at launch ✓ All monetization flows tested and working ✓ Private servers enabled and purchasable ✓ Game icon, thumbnails, and description are polished (this is your conversion funnel) ✓ Analytics tracking session length, retention, and revenue ✓ First weekly content drop (new ingredients) is already built and ready to deploy ✓ Discord community server is live ✓ 5-10 TikTok/YouTube Short clips are ready to post on launch day |
| :---- |

# **8\. TEAM, HIRING & BUDGET**

## **8.1 Minimum Viable Team (2 people)**

| Role | Responsibilities | Hiring Rate (USD) | Where to Find |
| :---- | :---- | :---- | :---- |
| Lua Scripter / Gameplay Dev | Core systems, economy, server/client code, data stores, monetization implementation | $25-$50/hr freelance | Roblox Talent Hub, DevForum, Fiverr, Upwork |
| 3D Builder / UI Designer | Map building, shop environments, ingredient/potion models, UI layout, particle effects | $15-$35/hr freelance | Roblox Talent Hub, DevForum, Twitter/X |

## **8.2 Ideal Team (3-4 people)**

Add a dedicated UI/UX designer ($20-$40/hr) for the market interface, recipe book, and shop customization menus. Add a sound designer ($15-$25/hr, project-based) for ambient audio, brewing sounds, and discovery jingles. Sound design is undervalued on Roblox — the games that invest in audio (DOORS, Grow a Garden) retain dramatically better.

## **8.3 Budget Estimate**

| Line Item | Low Estimate | High Estimate | Notes |
| :---- | :---- | :---- | :---- |
| Scripter (320 hrs over 8 weeks) | $8,000 | $16,000 | Full-time for 8 weeks at $25-$50/hr |
| Builder/Artist (240 hrs) | $3,600 | $8,400 | Full-time for 6 weeks at $15-$35/hr |
| UI Designer (80 hrs) | $1,600 | $3,200 | Part-time weeks 3-6 at $20-$40/hr |
| Sound Design (project) | $500 | $1,500 | Ambient pack \+ 15-20 SFX |
| Marketing (TikTok/YT) | $500 | $2,000 | Small creator payments for launch coverage |
| Roblox Ads (launch week) | $500 | $2,000 | Sponsored placement for initial traffic |
| Contingency (15%) | $2,200 | $5,000 | Scope creep, bug fixing, extra polish |
| TOTAL | $16,900 | $38,100 | MVP to polished launch |

| BUDGET OPTIMIZATION TIPS Revenue share instead of upfront pay: Offer your scripter 30-40% of game revenue instead of (or in addition to) hourly pay. This aligns incentives and reduces upfront cash needs. Many Roblox devs prefer this model. Use free Roblox assets: The Creator Marketplace has thousands of free models, sounds, and plugins. Don't build from scratch what already exists. Start with placeholder art: Get the systems working with basic shapes first. Polish visuals only after the loop is proven fun. Phased hiring: Hire the scripter first (weeks 1-2 solo), then add the builder (weeks 2-8). Don't pay for art until you have systems to put it in. |
| :---- |

# **9\. MARKETING & GROWTH STRATEGY**

Grow a Garden spent zero on paid influencer marketing and became the biggest game in Roblox history. The game marketed itself through shareable moments and content creator flywheel effects. Brew a Potion's marketing strategy is designed to replicate this.

## **9.1 Pre-Launch (Weeks 6–8)**

**Build a Discord:** Start a community server during development. Share behind-the-scenes clips of brewing animations, ingredient designs, and rare potion effects. Even 200-300 members at launch gives you a testing pool and Day 1 players.

**Create a Roblox Group:** This is your direct communication channel with players. Group members get notifications when you post updates.

**Tease on TikTok:** Post 3-5 short clips showing the most visually impressive brews. Use hashtags: \#Roblox \#BrewAPotion \#RobloxGames \#NewRobloxGame. The goal isn't viral reach yet — it's building anticipation in the Roblox content ecosystem.

## **9.2 Launch Week**

**Roblox Sponsored Ads:** Run $500-$2,000 in Roblox's native ad system to get your game onto the Discover page. Target the simulator and RPG categories. This gets you initial traffic; the game's retention and social mechanics must convert that traffic into organic growth.

**Seed Content Creators:** Identify 5-10 small-to-mid Roblox YouTubers/TikTokers (10K-100K followers). Offer them early access or a small payment ($50-$200 each) to cover the game. One video from a 50K-subscriber Roblox channel can drive 10,000+ visits.

**Community Codes:** Launch with 3-5 redeemable codes that give free Gems or exclusive ingredients. Post codes on Discord and social media. Codes are a proven traffic driver on Roblox — players actively search for them.

## **9.3 Post-Launch Growth Engine**

**The Content Flywheel:** Every Saturday ingredient drop should produce new discoverable recipes that are visually spectacular. Content creators will naturally cover these updates because their audience wants to see the new content. More creator coverage \-\> more players \-\> higher chart ranking \-\> more visibility \-\> more creators. This is the exact flywheel that powered Grow a Garden.

**Clip-Worthy Moments:** The potion effects on other players, dramatic rare brew reveals, and shop tours are all designed to produce TikTok-ready moments without any additional marketing spend.

**Roblox Algorithm:** Roblox's Recommended For You (RFY) algorithm rewards games with strong co-play signals (players inviting friends), high play days per week, and good session-quality metrics. The gifting system, shop visiting, and ingredient trading all create co-play signals.

# **10\. YOUR IMMEDIATE NEXT STEPS**

Here's exactly what to do this week, in order:

**Step 1: Secure a Scripter (Days 1–3)**

Post on the Roblox Developer Forum (devforum.roblox.com) Talent Hub and on Twitter/X with: "Hiring experienced Lua scripter for a new cozy simulator game. Revenue share \+ upfront pay. DM portfolio." Review portfolios — prioritize developers who have shipped a simulator or idle game before. A scripter who understands data stores, remote events, and economy balancing is more valuable than one who can build flashy features.

**Step 2: Set Up Infrastructure (Days 3–5)**

Create the Roblox game listing (even if private). Create the Roblox Group. Set up a Discord server with channels for: announcements, development updates, suggestions, and bug reports. Create the project's Trello or Notion board to track tasks.

**Step 3: Build the Core Loop First (Week 1–2)**

Do NOT start with art, map design, or monetization. Build the ingredient market with rotating stock. Build the cauldron with a basic recipe system. Build the sell interface. Test the loop: Can a player buy an ingredient, brew a potion, and sell it profitably? Does it feel satisfying? Is the timing right? If the core loop doesn't feel good with placeholder art, no amount of polish will save it.

**Step 4: Playtest Ruthlessly (Ongoing)**

Get 5 people to play your unfinished game every few days. Watch where they get confused, bored, or frustrated. The first-time player experience is everything — most Roblox players decide whether to stay within 60 seconds. If they don't understand what to do immediately, they leave and never come back.

**Step 5: Launch Imperfect, Iterate Fast**

Your launch version will not be perfect. Grow a Garden launched as a bare-bones farming sim and added mutations, pets, cooking, and trading over months of updates. Ship as soon as the core loop works, monetization is in, and the game looks presentable. Then update weekly based on player data and feedback. Speed of iteration is your competitive advantage over bigger studios.

**The single most important thing: SHIP FAST.**

Every week you spend in development is a week the cozy-sim wave could be cooling. Get the loop right, get it live, and let real player data guide your iteration. The market rewards speed over perfection.