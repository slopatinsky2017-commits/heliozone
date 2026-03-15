# HelioZone v1 LED MCPCB Release

## Board definition
- Substrate: Aluminum MCPCB, single-sided top copper.
- Size: 600 mm x 500 mm.
- Service strip: 50 mm reserved at X=550..600 mm for connectors, NTC access, and service testpoints.
- Active LED field: 550 mm x 500 mm.

## Channel architecture
Logical channels:
1. Main White (split physically as CH1A + CH1B)
2. Warm White (CH2)
3. Blue 450 nm (CH3)
4. Deep Red 660 nm (CH4)
5. Far-Red 730 nm (CH5)

## Uniformity strategy
A quasi-interleaved matrix was selected over a perfect square matrix:
- Main White LEDs are checkerboard split into CH1A/CH1B to minimize striping under partial dim scenarios.
- Spectral LEDs are distributed as sparse overlays with phase offsets by row to suppress color hotspots.
- Edge compensation places additional white emitters closer to perimeter rows to flatten PPFD roll-off.

## Electrical notes
- 48 V architecture with external constant-current driver outputs from control board.
- String topology keeps per-string Vf under 48 V compliance with thermal drift margin.
- Copper traces sized for low current density and thermal spreading.
