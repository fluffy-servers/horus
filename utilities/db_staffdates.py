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
conn.execute("SELECT DISTINCT date FROM play_dates ORDER BY date;")
all_dates = [x[0] for x in conn.fetchall()]

conn.execute(
    """SELECT p.username, date FROM play_dates d LEFT JOIN playtime p ON p.steamid64 = d.steamid64 
    WHERE d.steamid64 IN (SELECT steamid64 FROM ranks WHERE rank != 'former');
    """
)
staff_data = conn.fetchall()

# Build a list of played dates
staff_dict = {}
for x in staff_data:
    name = x[0]
    date = x[1]
    staff_dict[name] = staff_dict.get(name, []) + [date]

# Sort staff by most played
staff_names = [x[0] for x in sorted(staff_dict.items(), key=lambda x: len(x[1]))]

colors = [
    "tab:blue",
    "tab:red",
    "tab:orange",
    "tab:green",
    "tab:purple",
    "tab:pink",
    "tab:cyan",
] * 2

# Generate the graph
fig, ax = plt.subplots()

for i, name in enumerate(staff_names):
    # Plot date k if played on that date
    data = []
    for k, date in enumerate(all_dates):
        if date in staff_dict[name]:
            data.append(k)
        else:
            data.append(None)

    # Plot the row
    col = colors[i]
    ax.scatter(data, [name] * len(all_dates), s=64, c=col)

# Set x ticks to be the dates
ax.set_xticks([i for i in range(len(all_dates))])
ax.set_xticklabels(all_dates)
for tick in ax.get_xticklabels():
    tick.set_rotation(60)

plt.show()
