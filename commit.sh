#!/bin/sh

# Activate the conda environment and run subsequent commands
/home/guanning/miniconda3/condabin/conda run -n RISCV git add .
/home/guanning/miniconda3/condabin/conda run -n RISCV git commit -m "自动提交"
/home/guanning/miniconda3/condabin/conda run -n RISCV git push origin master
/home/guanning/miniconda3/condabin/conda run -n RISCV mkdocs gh-deploy
