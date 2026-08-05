import pandas as pd
import sqlite3
import os
import time

dataset_dir = r"C:\Users\HP\proje\devam_eden\futgol\dataset\players"
output_db = r"C:\Users\HP\proje\devam_eden\futgol\dataset\futgol.db"

# Mevcut veritabanı varsa silelim temiz başlangıç için
if os.path.exists(output_db):
    os.remove(output_db)

conn = sqlite3.connect(output_db)
cursor = conn.cursor()

# Hız optimizasyonları için SQLite PRAGMA komutları
cursor.execute("PRAGMA synchronous = OFF;")
cursor.execute("PRAGMA journal_mode = MEMORY;")
cursor.execute("PRAGMA temp_store = MEMORY;")

csv_files = [
    ("countries.csv", "countries"),
    ("competitions.csv", "competitions"),
    ("clubs.csv", "clubs"),
    ("players.csv", "players"),
    ("games.csv", "games"),
    ("club_games.csv", "club_games"),
    ("appearances.csv", "appearances"),
    ("game_events.csv", "game_events"),
    ("game_lineups.csv", "game_lineups"),
    ("player_valuations.csv", "player_valuations"),
    ("transfers.csv", "transfers")
]

for filename, table_name in csv_files:
    start_time = time.time()
    filepath = os.path.join(dataset_dir, filename)
    if not os.path.exists(filepath):
        print(f"Hata: {filename} bulunamadı, atlanıyor...")
        continue
        
    print(f"[{table_name.upper()}] Yükleniyor...")
    
    # Bellek şişmesini önlemek için büyük dosyaları chunk'lar (bloklar) halinde okuyup yazıyoruz
    chunk_size = 100000
    is_first = True
    
    for chunk in pd.read_csv(filepath, chunksize=chunk_size, low_memory=False):
        if is_first:
            chunk.to_sql(table_name, conn, if_exists='replace', index=False)
            is_first = False
        else:
            chunk.to_sql(table_name, conn, if_exists='append', index=False)
            
    end_time = time.time()
    print(f"-> {table_name} tablosu oluşturuldu. Süre: {end_time - start_time:.2f} saniye.")

# ----------------- İNDEKSLER (INDEXES) OLUŞTURMA -----------------
# Oyunlarda hızlı sorgulama yapabilmek için gerekli indeksler
print("\nİndeksler oluşturuluyor (Bu işlem büyük tablolarda biraz sürebilir)...")
index_start = time.time()

# Oyuncu aramaları için
cursor.execute("CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_players_id ON players(player_id);")

# Kulüp aramaları için
cursor.execute("CREATE INDEX IF NOT EXISTS idx_clubs_name ON clubs(name);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_clubs_id ON clubs(club_id);")

# Maç aramaları için
cursor.execute("CREATE INDEX IF NOT EXISTS idx_games_id ON games(game_id);")

# Oyuncu maç görünümleri (Ortak arkadaş vb. aramaları için en kritik indeksler)
cursor.execute("CREATE INDEX IF NOT EXISTS idx_app_player ON appearances(player_id);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_app_club ON appearances(player_club_id);")

# Maç kadroları (İlk 11 dizme veya kadro aramaları için)
cursor.execute("CREATE INDEX IF NOT EXISTS idx_lineups_game ON game_lineups(game_id);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_lineups_player ON game_lineups(player_id);")

# Maç içi olaylar
cursor.execute("CREATE INDEX IF NOT EXISTS idx_events_game ON game_events(game_id);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_events_player ON game_events(player_id);")

# Transferler
cursor.execute("CREATE INDEX IF NOT EXISTS idx_transfers_player ON transfers(player_id);")

conn.commit()
conn.close()

print(f"\nİndeksler başarıyla oluşturuldu. Süre: {time.time() - index_start:.2f} saniye.")
print(f"SQLite Veritabanı başarıyla hazırlandı: {output_db}")
