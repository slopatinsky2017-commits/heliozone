# HelioZone Hardware v1 Assumptions

1. MCPCB stackup is 1.6 mm aluminum core, 2 oz Cu top layer, white soldermask.
2. LED board uses single-sided assembly only.
3. Total optical active area is 550 mm x 500 mm due to 50 mm service strip on X+ edge.
4. White channels use 3030 LEDs at nominal 65 V string potential with external constant-current drivers.
5. Spectral channels use 3535 LEDs and lower series counts per string to keep compliance margin.
6. Control board includes external 48 V supply and local buck conversion to 5 V and 3.3 V rails.
7. Firmware uses PWM+analog dimming control per TPS92518HV channel.
8. Safety earth/mechanical grounding strategy handled at luminaire chassis level.
