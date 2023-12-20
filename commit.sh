#!/bin/sh

CONDA_PATH=$(conda info --base)
source $CONDA_PATH/etc/profile.d/conda.sh
conda init
conda activate base
git config --global user.email "auto@example.com"
git config --global user.name "auto"
pip install mkdocs mkdocs-material
git add .
git commit -m "自动提交"
git push origin master
mkdocs gh-deploy
