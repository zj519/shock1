#!/bin/bash
#SBATCH --job-name=shock_sim
#SBATCH --output=shock_sim.out
#SBATCH --error=shock_sim.err
#SBATCH --partition=ruixu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=72:00:00
#SBATCH --mem=16G

# === Set OpenMP threads ===
export OMP_NUM_THREADS=8

# === Go to working directory ===
cd /home1/zimengji/mylammps/MD

# === Print job info ===
echo "Job started on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo "Working directory: $(pwd)"
echo "OpenMP threads: $OMP_NUM_THREADS"
echo ""

# === Run LAMMPS ===
lmp -in in.shock -log shock.log

# === Print completion ===
echo ""
echo "Job finished at $(date)"

