# NET2008 Week 9 — Bytown Web Service in Containers

Student: **Talal Al-Rufaye**  
Student ID: **101344712**  
Seed: **14** (7 + 1 + 2 + 4)

Ports: 8014 (Part 1), 8114 (Part 2), 8214 (Part 3), 8314 (Part 4).

## Status

This project contains the source files for the lab. Docker commands and evidence **must be run and generated** on a computer with Docker installed. Evidence is not fabricated or prefilled.

## Complete the hands-on portion

Open an Ubuntu/WSL2 terminal or Linux/macOS terminal with Docker running, change to this folder, and run:

```bash
bash run-lab.sh
```

The script runs all parts, generates evidence and tests the Compose stack. It keeps the images and volume for the instructor/self-check. It also records output in `evidence/`.

**Important:** Run the official course self-check while the Compose stack is running (the script attempts it if the default course path exists). To rerun the self-check manually while the stack runs:

```bash
python3 ~/net2008-devops/week09/lab/W09_Lab_selfcheck.py --seed 14
```

Then commit and push the generated evidence files. Submit the public GitHub repository URL to Brightspace.
