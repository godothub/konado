---
title: Konado Script
order: 1
---

# Konado Scripts

Konado Scripts is an authoring language tailored for visual novels. Its file extension is `.ks`.

You can think of it as a more powerful and more structured "novel script": developers can control story dialogue, character portraits, background switching, music and sound effects, story branches, and choices without writing complex code.

## Design Philosophy

The core design philosophy of Konado Script is to separate **story content** from **program logic**:
- Writers focus on narrative content without needing programming knowledge
- Programmers focus on engine development without intervening in story creation
- Resource management (images and audio) uses identifiers and is decoupled from scripts
- Modular instruction set, easy to extend with new features
- Compatible with version control systems such as Git
- Text format is naturally cross-platform
- Resource references are platform-independent

## FAQ

### 1. Saving after a parse failure does not trigger reparsing

The console will show an error message, but saving the file will not automatically trigger reparsing. This happens because reimport was not triggered successfully.

```text
Line 5 content: a1ctor show Kona normal at 2 5 scale 0.3
  ERROR: core/variant/variant_utility.cpp:1024 - Error: res://sample/demo/demo_01.ks [Line: 5] Parse failed: unrecognized syntax, parsing stopped: a1ctor show Kona normal at 2 5 scale 0.3 
  ERROR: Failed to process scripts
  ERROR: Error importing 'res://sample/demo/demo_01.ks'.
  ERROR: Failed loading resource: res://sample/demo/demo_01.ks.

```

Find the corresponding script file, right-click it, and select reimport.

![Reimport script](/images/tutorial/script/reimport.png)

### 2. Script file encoding issues

Make sure the script file is encoded as UTF-8, otherwise garbled text may appear. Script files created by default use UTF-8 encoding.
