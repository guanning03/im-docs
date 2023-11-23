#!/bin/sh
conda activate RISCV
git add .
git commit -m "自动提交"
git push origin master
mkdocs gh-deploy