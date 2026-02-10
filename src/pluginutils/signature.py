from .manage import PluginPackage
from typing import Set, Optional
import os
import sys
import json
import shutil
import filehash
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_pem_public_key

def verify_plugin(plugin: PluginPackage) -> list[str]:
    install_dir = plugin.extract_dir
    manifest_path = os.path.join(install_dir, "META-INF", "signature", "manifest.json")
    signature_path = os.path.join(install_dir, "META-INF", "signature", "global.sig")
    cert_path = os.path.join(install_dir, "META-INF", "cert.key")

    # Check if all necessary files exist
    if not all(os.path.exists(p) for p in [manifest_path, signature_path, cert_path]):
        return ["Missing required files for verification"]

    try:
        # Read manifest
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
        
        # Read signature
        with open(signature_path, 'rb') as f:
            signature = f.read()
        
        # Read public key
        with open(cert_path, 'rb') as f:
            public_key = load_pem_public_key(f.read())
        
        # Verify signature against manifest
        public_key.verify(
            signature,
            json.dumps(manifest).encode('utf-8'),
            padding.PKCS1v15(),
            hashes.SHA256()
        )
    except Exception as e:
        return [f"Verification failed: {str(e)}"]
    
    untrusted_files = []
    for file_metadata in manifest:
        file_path = os.path.join(install_dir, file_metadata["filepath"])
        if not os.path.exists(file_path):
            untrusted_files.append(file_metadata["filepath"])
            continue
        
        actual_hash = filehash.FileHash("sha256").hash_file(file_path)
        expected_hash = file_metadata["metadata"]
        if actual_hash.lower() != expected_hash.lower():
            untrusted_files.append(file_metadata["filepath"])
    
    return untrusted_files
