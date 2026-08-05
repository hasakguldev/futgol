# -*- coding: utf-8 -*-
"""Her futbolcunun KARIYERI boyunca forma giydigi ligleri bit maskesi olarak
   onceden hesaplayip uygulama asset'i uretir.

   Neden: bu bilgiyi calisma aninda cikarmak sorgu basina ~700 ms suruyor
   (1.88M satirlik appearances taramasi). Onceden hesaplanmis maske ile
   ayni bilgi 0 ms'e iner.
"""
import sqlite3, sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

DB = r'C:\Users\HP\proje\devam_eden\futgol\futgol_arsiv\dataset\futgol.db'
OUT = r'C:\Users\HP\proje\devam_eden\futgol\futgol_app\assets\data\player_leagues.csv'

con = sqlite3.connect(DB)
con.execute('PRAGMA cache_size = -60000')
cur = con.cursor()

# Lig kodlarini sabit bir sirayla numarala (maske biti = indeks)
leagues = [r[0] for r in cur.execute(
    "SELECT competition_id FROM competitions WHERE type='domestic_league' ORDER BY competition_id")]
idx = {code: i for i, code in enumerate(leagues)}
print("Lig sayisi: %d (maske %d bit)" % (len(leagues), len(leagues)))

MIN_VALUE = 1_000_000  # bu esigin altindaki oyuncular hicbir zorlukta secilmiyor

print("Kariyer ligleri cikariliyor...")
rows = cur.execute("""
    SELECT a.player_id, c.domestic_competition_id
    FROM appearances a
    JOIN clubs c ON c.club_id = a.player_club_id
    JOIN players p ON p.player_id = a.player_id
    WHERE c.domestic_competition_id IS NOT NULL
      AND COALESCE(p.highest_market_value_in_eur, 0) >= ?
    GROUP BY a.player_id, c.domestic_competition_id
""", (MIN_VALUE,)).fetchall()

masks = {}
for pid, code in rows:
    if code in idx:
        masks[pid] = masks.get(pid, 0) | (1 << idx[code])

print("Maske uretilen oyuncu: %d" % len(masks))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with io.open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    # 1. satir: surum + lig sirasi (Dart tarafi bit indekslerini buradan cozer)
    f.write("v1;" + ",".join(leagues) + "\n")
    for pid in sorted(masks):
        # base36 ile kompakt yazim
        m = masks[pid]
        s = ''
        if m == 0:
            s = '0'
        while m:
            m, r = divmod(m, 36)
            s = "0123456789abcdefghijklmnopqrstuvwxyz"[r] + s
        f.write("%s,%s\n" % (pid, s))

size = os.path.getsize(OUT)
print("Asset yazildi: %s" % OUT)
print("Boyut: %.1f KB (%d satir)" % (size / 1024, len(masks) + 1))

# Dogrulama
print("\nDogrulama:")
for pid, nm in [(28003, 'Messi'), (8198, 'C.Ronaldo'), (68290, 'Neymar'),
                (7607, 'Xavi'), (861410, 'Arda Güler')]:
    m = masks.get(pid, 0)
    got = sorted(code for code, i in idx.items() if m & (1 << i))
    print("   %-12s → %s" % (nm, got))
