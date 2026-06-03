---
title: Custom Dialogue Box
order: 4
---

# Custom Dialogue Interface

## Introduction

If your work requires a custom dialogue interface, you can modify the template dialogue interface to achieve it. Godot Engine itself also has a powerful theme system, so you can achieve the desired result by modifying a custom theme.

Please note that after modifying the template dialogue interface, you should not update the Konado plugin, otherwise your changes will be overwritten.

## Edit Template Files

`res://addons/konado/template/` contains the dialogue interface scene. You can customize the dialogue interface by modifying this file.

In general, do not modify scripts on nodes. Prefer changing node properties to achieve customization.
