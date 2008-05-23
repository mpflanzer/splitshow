#!/usr/bin/env bash

set -e

convert -size 1055x710 xc:transparent \
        shot_mirror.png -composite \
        shot_interleaved.png -geometry +150+250 -composite \
        shot_composite.png

convert shot_composite.png -resize 70% shot_composite_sm.png
