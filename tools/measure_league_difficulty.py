# -*- coding: utf-8 -*-
"""Ligleri tahminle degil, veriyle siniflandirmak icin metrik uretir."""
import sqlite3, sys, io, statistics
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
con = sqlite3.connect(r'C:\Users\HP\proje\devam_eden\futgol\futgol_arsiv\dataset\futgol.db')
con.execute('PRAGMA cache_size = -40000')
cur = con.cursor()
def Q(q, p=()):
    return cur.execute(q, p).fetchall()

BIG5 = ('GB1', 'ES1', 'IT1', 'L1', 'FR1')

leagues = Q("""SELECT competition_id, country_name, name FROM competitions
               WHERE type='domestic_league' ORDER BY competition_id""")

# Her lig icin: o ligde forma giymis oyuncularin peak degerleri
print("Lig metrikleri hesaplaniyor (%d lig)...\n" % len(leagues))

rows = []
for cid, country, lname in leagues:
    # O ligin kuluplerinde forma giymis oyuncular
    players = Q("""SELECT DISTINCT p.player_id, COALESCE(p.highest_market_value_in_eur,0)
                   FROM players p
                   WHERE p.player_id IN (
                     SELECT a.player_id FROM appearances a
                     JOIN clubs c ON c.club_id = a.player_club_id
                     WHERE c.domestic_competition_id = ?)""", (cid,))
    if not players:
        continue
    vals = [v for _, v in players]
    ids = set(p for p, _ in players)

    n_total = len(vals)
    n_50 = sum(1 for v in vals if v >= 50_000_000)
    n_20 = sum(1 for v in vals if v >= 20_000_000)
    n_5 = sum(1 for v in vals if v >= 5_000_000)
    median = statistics.median(vals) if vals else 0

    # Crossover: bu ligin oyuncularindan kaci ayni zamanda BIG5'te de oynadi?
    cross = Q("""SELECT COUNT(DISTINCT a.player_id) FROM appearances a
                 JOIN clubs c ON c.club_id = a.player_club_id
                 WHERE c.domestic_competition_id IN %s
                   AND a.player_id IN (
                     SELECT a2.player_id FROM appearances a2
                     JOIN clubs c2 ON c2.club_id = a2.player_club_id
                     WHERE c2.domestic_competition_id = ?)""" % ('(' + ','.join("'%s'" % b for b in BIG5) + ')',), (cid,))[0][0]

    # Kulup gucu
    club = Q("""SELECT COUNT(*), COALESCE(AVG(national_team_players),0), COALESCE(AVG(stadium_seats),0)
                FROM clubs WHERE domestic_competition_id = ?""", (cid,))[0]

    rows.append({
        'id': cid, 'country': country, 'name': lname,
        'players': n_total, 'p50m': n_50, 'p20m': n_20, 'p5m': n_5,
        'median': median, 'cross': cross,
        'cross_pct': 100.0 * cross / n_total if n_total else 0,
        'clubs': club[0], 'nt': club[1], 'seats': club[2],
    })

rows.sort(key=lambda r: (-r['p20m'], -r['cross_pct']))

hdr = "%-6s %-14s %7s %6s %6s %8s %8s %7s %6s" % (
    "KOD", "ÜLKE", "OYUNCU", "50M+", "20M+", "MEDYAN", "BIG5%", "KULÜP", "ORT.MS")
print(hdr); print("-" * len(hdr))
for r in rows:
    print("%-6s %-14s %7d %6d %6d %7.1fM %7.1f%% %7d %6.1f" % (
        r['id'], r['country'][:14], r['players'], r['p50m'], r['p20m'],
        r['median'] / 1e6, r['cross_pct'], r['clubs'], r['nt']))

# Puanlama: taninirlik skoru
print("\n\n=== TANINIRLIK SKORU ===")
print("skor = 50M+ sayisi*3 + 20M+ sayisi + BIG5 gecis yuzdesi*2 + medyan(M)*4\n")
for r in rows:
    r['score'] = r['p50m'] * 3 + r['p20m'] + r['cross_pct'] * 2 + (r['median'] / 1e6) * 4
srt = sorted(rows, key=lambda r: -r['score'])
for i, r in enumerate(srt, 1):
    print("%2d. %-6s %-14s skor=%8.1f  (50M+:%3d  20M+:%4d  BIG5:%5.1f%%  medyan:%5.2fM)" % (
        i, r['id'], r['country'][:14], r['score'], r['p50m'], r['p20m'], r['cross_pct'], r['median'] / 1e6))
