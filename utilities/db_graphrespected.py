from dotenv import load_dotenv
import matplotlib.pyplot as plt
import mysql.connector
import os

# Load database settings from .env and connect
load_dotenv()
database = mysql.connector.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    user=os.getenv("DB_USERNAME"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_DATABASE"),
)
conn = database.cursor()

# Fetch the data we need
conn.execute(
    "SELECT d.date, COUNT(d.steamid64) AS amount FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 WHERE p.playtime < 36000 GROUP BY date"
)
users = dict(conn.fetchall())

conn.execute(
    "SELECT d.date, COUNT(d.steamid64) AS amount FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 WHERE p.playtime >= 36000 AND p.playtime < 86400 GROUP BY date"
)
respected1 = dict(conn.fetchall())

conn.execute(
    "SELECT d.date, COUNT(d.steamid64) AS amount FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 WHERE p.playtime >= 86400 AND p.playtime < 180000 GROUP BY date"
)
respected2 = dict(conn.fetchall())

conn.execute(
    "SELECT d.date, COUNT(d.steamid64) AS amount FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 WHERE p.playtime >= 180000 AND p.playtime < 360000 GROUP BY date"
)
respected3 = dict(conn.fetchall())

conn.execute(
    "SELECT d.date, COUNT(d.steamid64) AS amount FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 WHERE p.playtime >= 360000 GROUP BY date"
)
respected4 = dict(conn.fetchall())

dates = users.keys()

# Fill in gaps with 0
for date in dates:
    respected1[date] = respected2.get(date, 0)
    respected2[date] = respected2.get(date, 0)
    respected3[date] = respected3.get(date, 0)
    respected4[date] = respected4.get(date, 0)

# Convert to list
users = list(users.values())
respected1 = list(respected1.values())
respected2 = list(respected2.values())
respected3 = list(respected3.values())
respected4 = list(respected4.values())

# Generate the graph
fig, ax = plt.subplots()

# Plot a stacked bar chart
ax.bar(
    dates, users, label="Users",
)

ax.bar(
    dates, respected1, bottom=users, label="Respected 1",
)

ax.bar(
    dates,
    respected2,
    bottom=[sum(x) for x in zip(users, respected1)],
    label="Respected 2",
)

ax.bar(
    dates,
    respected3,
    bottom=[sum(x) for x in zip(users, respected1, respected2)],
    label="Respected 3",
)

ax.bar(
    dates,
    respected4,
    bottom=[sum(x) for x in zip(users, respected1, respected2, respected3)],
    label="Respected 4",
)

ax.set_ylabel("Players")
ax.set_title("Daily Respected Users")
ax.legend()

fig.tight_layout()
plt.show()
