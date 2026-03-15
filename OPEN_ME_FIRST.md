# OPEN ME FIRST - HelioZone Hardware v1 Release Package

## What is in this release
This repository contains plain-text engineering sources for:
- `HelioZone_v1_LED_MCPCB_release/`
- `HelioZone_v1_Control_FR4_release/`
- `HelioZone_v1_System_Integration_release/`

## Rebuild EasyEDA Standard package locally
### LED board
1. Open PowerShell in repo root.
2. Run: `./HelioZone_v1_LED_MCPCB_release/build_easyeda_std_led_project.ps1`
3. The script rebuilds `EasyEDA_STD_Project_LED/` from `project_files/`, `pcb_files/`, and `schematic_files/`.
4. Optional: run with `-CreateZip` to produce `HelioZone_v1_LED_MCPCB_EasyEDA_STD.zip`.
5. In EasyEDA Standard, choose **File -> Open Project** and point to rebuilt project folder.

### Control board
1. Open PowerShell in repo root.
2. Run: `./HelioZone_v1_Control_FR4_release/build_easyeda_std_control_project.ps1`
3. The script rebuilds `EasyEDA_STD_Project_Control/`.
4. Optional: run with `-CreateZip` to generate `HelioZone_v1_Control_FR4_EasyEDA_STD.zip`.
5. Import in EasyEDA Standard using project folder or ZIP.

## Notes
- All critical deliverables are human-readable text files in this repository.
- ZIP archives are optional extras and are not required for inspection.
