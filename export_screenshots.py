import urllib.request
import os
import zipfile
import json
import base64

screens = [
    {
        "filename": "00_Splash_Screen.png",
        "title": "Screen 0 - Splash & Brand Launch",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1UCcg8s-b6qfejzGIJFlU5GQJv0CCOYEuzsanrtfJk8IH4ORFmgOduk1ZSrbZeecoXGZTDHH8kS9PsxMd4yaxDZu5pq_c0r4nSleXUptejh_jtyMYxcwmrjUewhUbe5xWYYdEhNuEOPPNNGcftqKuy33XD6uw60SDoB1g91aBO_XK3t3NbIsFsh0e-qUBclKoaoLmS_Zq0O9i2fp5_nt8u8dM5Aw_lT_PQLlqjsyAEwxywzz1BR0zRLYHw"
    },
    {
        "filename": "01_WhatsApp_Bridge_Setup.png",
        "title": "Screen 1 - WhatsApp Bridge & Setup",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1XXxdUjztfLEkCFhtOpyhpXgRcfbdR27NTad86jw9nT9OnAAS0eDZ_GiJ_j0YaCL0TpxqgPr3m3Vov0GVNFkyWQk0IwJng5UygnW3acZ5UWqBhL_QuY0TGGyGucv3OmQBYaHz-RYpayxqxujHxuDxVjurYhuYQxa3dEc_lyp9w6bit5z9xEKoJ4RdYR42d2oaNuLiispzEIMKRNZh_aP52R_DQMbkjfxtPNgGWrz_2hV1IGnV7GB9RMoEU"
    },
    {
        "filename": "02_Unified_Veiled_Chat_Feed.png",
        "title": "Screen 2 - Unified Veiled Chat Feed",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1UEEsh4ByyW7tsVWQNN2aNXT8t-uEcnkqH967p4qkugNvPqeC7q5H_KXC0g5TWQTqWXuWFrmVpyNSLWW0ONviZS0ZYTy4ppgc2-Qe31nsFo1kFq5sq91VEUhqGDUCxvfbR5T-EB_mpIujLL-QI9DJFyNL5G5742HMnbrI3LAatvhG7BOTISjnbmIN0EqTqg51eHCQq2HEow5yghiPJC2zWMPMI856YE9IHQGHEH0kL9YcfujGEk2qnCXA"
    },
    {
        "filename": "03_Biometric_Keypad_Modal.png",
        "title": "Screen 3 - Biometric & Keypad Modal",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1WC487qmO0zzCEJm6yydQXP1ik1vz1FCdAyVeWxepepq0GIzG_CV-SdsUkyPV3H3Q9sMzuvQDimKpDD_CGzlcpCaxHKhor2_VR9mKPz8S8Dhraf-aPksQakQYdPu07LreehOL8KlXFCde-sN98n5iU_xzl8cQFJsSK_gTH9T_S4O3MgDgIgJzGW_9-eoaZ3ma9ko5bv4dH_ogC6UfAdw_I9YzNG9EV8OP_8UQJqBvwk_evxcKNvDnGVoS8"
    },
    {
        "filename": "04_Unlocked_Conversation_View.png",
        "title": "Screen 4 - Unlocked Conversation View",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1VOedCCBnOuJbiy0ckx4mQXQcllVjHpeO6QPCg9ARX_AEuZBZIZoCIWofel--DSgyP9J10A3u6BI21SIhmIj9lCRLnFZU6iGfO3CB3jR70k72qc26qumRvWTg-XEpCsQIkgZGmP99EFSbPU82TC4MYjIx41QlgzmXTQLKqQUXNWuf7gdJJlYNtMXrPRt7AxkjJAs2SbEWVoqb_aPYf1uAkAH3r26iAc3QxLLoc3Hb-iY2eEAkdaIXRrQ4s"
    },
    {
        "filename": "05_Decoy_Mode_Chat.png",
        "title": "Screen 5 - Decoy Mode Chat",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1XzXY_Zzlu9u59uLO8BdcBB41mQetZQ3TrYy34pFlOWv4kJF5vuUw86RuNiFyadLEWCI2I6mTCezfZflegVBvXRmKoVf9Px4SJyfKAb4pftOVRVz9ewGLhD1K_6bG-3mE_dzLRynCO3fzRrQ23qFfNbRgEFjJlzdlpaeSeiwNOZxowiVLK8VoW4uoBz-lNX24t2dsGyLTKGeX3JgVTFPLFz-WXUH_izIZdCkv8-t3hBsR1eWUfBUDrk6g"
    },
    {
        "filename": "06_Privacy_Camouflage_Settings.png",
        "title": "Screen 6 - Privacy & Camouflage Settings",
        "url": "https://lh3.googleusercontent.com/aida/AEtjO1W_xmTjHJUGbGETfneryAiwqe05gQE2TxlBAbdNkW23WcZpBf7_ty6gPmx-9ADTFYEp7j0CalP8kZOryyJ_yjT1VUMvBP-EDhnpoXrPAUalsMYJPhBEChzO1Ovt-HqKjnqmmBDkiwrr4OZ7OwXRj_DQMm7S0ytNdtgv4wOQvHG-9sQGnrnbQM7UjHD_sZZFbhuZFTmL0RL4nDijjqXlvPsFTkh3dn0zw0hV-64SMWIEeHLxJezu_ZiT8Sk"
    }
]

output_dir = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(output_dir, exist_ok=True)

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

downloaded_files = []
for s in screens:
    dest_path = os.path.join(output_dir, s["filename"])
    print(f"Downloading {s['title']}...")
    req = urllib.request.Request(s["url"], headers=headers)
    try:
        with urllib.request.urlopen(req) as resp, open(dest_path, "wb") as f:
            f.write(resp.read())
        size_kb = os.path.getsize(dest_path) / 1024
        print(f"  -> Saved {s['filename']} ({size_kb:.1f} KB)")
        downloaded_files.append((dest_path, s["filename"]))
    except Exception as e:
        print(f"  -> Error downloading {s['filename']}: {e}")

zip_path = os.path.join(os.path.dirname(__file__), "VeilChat_Screenshots.zip")
print(f"Creating zip file: {zip_path}...")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
    for file_path, arcname in downloaded_files:
        zf.write(file_path, arcname)

zip_size_mb = os.path.getsize(zip_path) / (1024 * 1024)
print(f"Successfully created {zip_path} ({zip_size_mb:.2f} MB) with {len(downloaded_files)} high-resolution screenshots!")
