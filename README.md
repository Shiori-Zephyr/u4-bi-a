# U₄-BI-A

A macOS menu bar app that displays 27 calendar and timekeeping systems simultaneously. Lives in the status bar, runs in the background. Trilingual: English / 日本語 / Français.

## Architecture

**Status Bar (always visible):** Shows the current date in your selected 1–3 calendars, with emoji identifiers. Click to open a popover with more detail, today's festival matches, and controls.

**Main Window (on demand):** Displays all 27 calendars in a three-column grid with a festival section at the bottom. Open from the popover or by launching the app. Closing the window does not quit the app — it keeps running in the menu bar.

**Settings (⚙️ in main window):** Language, background (papyrus/solid color), font color, and menu bar calendar selection (which 1–3 calendars appear in the status bar). All settings persist across launches via UserDefaults.

## Build & Run

### Requirements
- macOS 14.0+ (Sonoma or later)
- Xcode 15+ or Swift 5.9+

### Download
Grab the latest `.app` from [Releases](https://github.com/Shiori-Zephyr/u4-bi-a/releases).

### Xcode
Open `U4BIA.swift` and `Package.swift` in Xcode, build and run.

### Swift Package Manager
```bash
cd u4-bi-a
swift build
swift run
```

## Supported Calendars (27)

### Apple Foundation API (13)
Gregorian, Chinese Lunar, Hebrew, Islamic Hijri (Umm al-Qura), Solar Hijri (Persian), Buddhist, Japanese (Imperial era), ROC/Minguo, Julian Day Number, Coptic, Ethiopic (Amete Mihret), Indian National (Saka), ISO 8601

### Manually Computed (9)

**Julian** — JDN-to-Julian conversion via the Meeus algorithm, valid across all centuries. The Gregorian–Julian day offset is computed dynamically from the century number rather than hardcoded.

**Pawukon (Bali)** — 210-day cycle, all 10 concurrent weeks computed. Simple cycling for 3/5/6/7-day weeks. Urip system for 1/2/10-day weeks. Penultimate-day repetition for 4/8-day weeks at day 72. First-day triple repetition for 9-day week. 30 Wuku names. Epoch: JDN 146 (Dershowitz & Reingold).

**Aztec Tonalpohualli** — 260-day sacred calendar. GMT correlation (584283) + offset 159. 13 numbers × 20 day signs.

**Aztec Xiuhpohualli** — 365-day solar calendar. Alfonso Caso correlation with Nicholson veintena alignment. Anchor: 1-Coatl = Aug 13, 1521 Julian (JDN 2277468). No leap year. Year bearers (Tochtli/Acatl/Tecpatl/Calli) in 52-year Calendar Round. Nemontemi at year end.

**Maya Long Count** — GMT correlation (584283). Baktun.Katun.Tun.Uinal.Kin decomposition.

**Tibetan (Phukpa)** — Full implementation of Svante Janson's formulas (arXiv:1401.6285), epoch E806. Constants: m0 = 2015501 + 4783/5656, m1 = 167025/5656, moon anomaly A1 = 253/3528, A0 = 475/3528, sun S1 = 65/804, S0 = 743/804. 8-point moon equation table and 4-point sun equation table with symmetry-derived full cycles, piecewise linear interpolation. Leap month detection via `ceil(12·S1·n + α)` with α = 1 + 827/1005, β = 123. Skipped/doubled tshes detection. Year/month conversion using `from_month_count` / `to_month_count`. 60-year element-animal-gender cycle. Tibetan year = Western year + 127.

**French Republican** — Epoch Sep 22, 1792. 12×30 days + Sansculottides. 10-day décade. Romme leap year rule (divisible by 4, except centuries, except 400s).

**International Fixed** — 13×28 days + Year Day + Leap Day. Mathematically exact.

**Positivist** — 13×28 days named after historical figures + festival days. Epoch 1789.

### Time-Based Systems (5)
Sumerian Sexagesimal (360 UŠ/day), Egyptian Seasonal Hours (12+12), Chinese Ke (100 ke/day + 12 shichen), Indian Ghati (60/day), French Decimal Time (10 h/day).

## Today's Festivals

The app matches the current date against a built-in database of festivals for each calendar system. Matching uses the respective calendar's own month/day via Apple's Foundation Calendar API (for supported calendars) or cycle-position arithmetic (for Pawukon, Aztec, etc.). Festivals display in the selected language.

## License

[The Unlicense](LICENSE) — public domain.

## References

- Dershowitz & Reingold, *Calendrical Calculations* (4th ed., 2018)
- Svante Janson, "Tibetan Calendar Mathematics," arXiv:1401.6285 (2014)
- Jean Meeus, *Astronomical Algorithms* (2nd ed., 1998)
- Alfonso Caso, *Los Calendarios Prehispánicos* (1967)
- azteccalendar.com (Caso-Nicholson correlation)
- forest-jiang/phugpa-cal (Phukpa reference implementation)
- Wikipedia (verified against primary sources for each calendar)
