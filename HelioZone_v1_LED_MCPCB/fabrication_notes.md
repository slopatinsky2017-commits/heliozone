# Fabrication Notes — HelioZone_v1_LED_MCPCB

- Board type: Aluminum MCPCB
- Overall size: 600 mm × 500 mm
- Unit system: mm
- Service/control-board zone: 50 mm strip on right edge (X=550 to 600 mm)
- LED matrix: 18 × 18 = 324 footprints

## Channel population
- Main White: 210
- Warm White: 42
- Blue 450nm: 24
- Deep Red 660nm: 36
- Far Red 730nm: 12

## Mechanical
- 8x non-plated mounting holes, Ø4.2 mm drill
- Coordinate origin at lower-left board corner

## Electrical interface pads
- Power pads: VIN+, VIN-, CH_RETURN
- Thermal pads: TH1, TH2
- NTC pads: NTC1_A, NTC1_B

## Manufacturing remarks
- Maintain LED polarity orientation per footprint silkscreen marker.
- Verify dielectric thickness and thermal conductivity based on selected aluminum core stackup.
- Keep service zone clear of LED footprints; reserve for control board interconnect.
