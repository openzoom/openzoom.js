#!/usr/bin/env python
# -*- coding: utf-8 -*-

import deepzoom

# Create Deep Zoom Image creator with weird parameters
creator = deepzoom.ImageCreator()

# Create Deep Zoom image pyramid from source
for index in range(1, 7):
    source = "images/%d.jpg" % index
    destination = "images/%d.dzi" % index
    print(source, destination)
    creator.create(source, destination)
