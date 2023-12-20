#!/bin/sh

pip install mkdocs mkdocs-material
git add .
git commit -m "自动提交"
git push origin master
mkdocs gh-deploy
