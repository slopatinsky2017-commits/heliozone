# HelioZone Hardware v1 - Release Manifest

## Top-level governance files
- `ASSUMPTIONS.md`: Declared engineering assumptions.
- `OPEN_ISSUES.md`: Items requiring closure before production freeze.
- `OPEN_ME_FIRST.md`: Rebuild/import instructions for EasyEDA Standard.

## 1) HelioZone_v1_LED_MCPCB_release
- `README_LED_MCPCB.md`: Design intent, dimensions, and channel strategy.
- `fabrication_notes_LED_MCPCB.md`: Fab + assembly requirements for MCPCB.
- `design_rules_LED_MCPCB.json`: MCPCB rule deck used for layout constraints.
- `board_outline.dxf`: 600 x 500 mm board with 50 mm service strip.
- `assembly_drawing_LED_MCPCB.svg`: Mechanical + channel visual assembly drawing.
- `top_copper_preview.svg`: Copper/string routing preview.
- `top_silk_preview.svg`: Silk legends and service labeling.
- `led_placement_table.csv`: XY placement for all 324 LEDs.
- `channel_map.csv`: Logical channel to device references.
- `string_topology.csv`: Series string definitions and estimated Vf.
- `mounting_holes.csv`: Mechanical fixing points.
- `connector_points.csv`: Service-strip connector coordinates.
- `thermal_points.csv`: NTC/test point coordinates.
- `BOM_LED_MCPCB.csv`: Component procurement list.
- `PickPlace_LED_MCPCB.csv`: SMT centroid data.
- `Gerber_LED_MCPCB/*.gbr`: RS-274X fabrication layers.
- `Gerber_LED_MCPCB/*.drl`: Drill files.
- `Gerber_LED_MCPCB/fabrication_manifest.md`: Fabrication file map and checksum notes.
- `project_files/*`, `pcb_files/*`, `schematic_files/*`: EasyEDA Standard source payload.
- `build_easyeda_std_led_project.ps1`: Windows helper to reconstruct importable EasyEDA folder.

## 2) HelioZone_v1_Control_FR4_release
- `README_Control_FR4.md`: Control board architecture and bring-up notes.
- `schematic_control.md`: Human-readable schematic breakdown.
- `schematic_control.svg`: Visual top-level schematic blocks.
- `board_outline_control.dxf`: Control PCB board boundary.
- `pcb_control_preview.svg`: Component placement and key nets preview.
- `control_board_pinout.csv`: External connector pin assignment.
- `control_board_netlist.csv`: Critical net interconnect list.
- `firmware_pinmap.csv`: ESP32-S3 firmware GPIO mapping.
- `output_channel_map.csv`: 6 physical outputs to 5 logical channels.
- `BOM_Control_FR4.csv`: Control board BOM.
- `PickPlace_Control_FR4.csv`: Control board centroid data.
- `fabrication_notes_Control_FR4.md`: Fab and assembly notes.
- `assembly_drawing_Control_FR4.svg`: Connector and placement drawing.
- `design_rules_Control_FR4.json`: DRC setup for FR4 board.
- `project_files/*`, `pcb_files/*`, `schematic_files/*`: EasyEDA Standard source payload.
- `build_easyeda_std_control_project.ps1`: Windows helper to rebuild EasyEDA project.

## 3) HelioZone_v1_System_Integration_release
- `system_block_diagram.svg`: End-to-end electrical block diagram.
- `wiring_harness_pinout.csv`: Harness-level pin and wire color mapping.
- `LED_board_to_control_board_connector_map.csv`: Board-to-board mapping.
- `power_architecture.md`: 48 V rail strategy and conversion stages.
- `system_power_budget.csv`: Channel current/power and margin budget.
- `assembly_overview.svg`: Mechanical assembly relationship drawing.
- `mechanical_stackup_notes.md`: Stackup and mounting recommendations.
- `thermal_strategy.md`: Thermal control strategy and limits.
- `firmware_control_architecture.md`: Firmware data/control architecture.
- `commissioning_checklist.md`: Commissioning checklist for prototype bring-up.
- `test_plan.md`: Verification and validation plan.
- `manufacturing_release_checklist.md`: Release gate checklist.
