---
outline: deep
---

# Plugin API Usage

### 1. General

Usually, the Directory Structure of AndroidToolBox plugins are:
```filetree
plugin.7z
├─ entry.py # The entry file
├─ plugin.json # Final Manifest
└─ META-INF
   ├─ MANIFEST.MF # Onetime Manifest
   ├─ update
   │  └─ update_log.txt # Update logs
   └─ signature
      ├─ public_cert.key # Public key
      └─ signature # signature info
```
