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
conn.execute("SELECT date, COUNT(*) AS amount FROM play_dates GROUP BY date")
player_counts = dict(conn.fetchall())

conn.execute(
    "SELECT date, COUNT(*) AS amount FROM play_dates WHERE steamid64 IN (SELECT steamid64 FROM ranks WHERE rank != 'donor') GROUP BY date"
)
staff_counts = dict(conn.fetchall())

# Fill in gaps with no staff with 0
# If there are any players, then there must be staff
for date in player_counts.keys():
    if date not in staff_counts:
        staff_counts[date] = 0

# Generate the graph
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()

# Plot the data
dates, players = zip(*sorted(player_counts.items()))
ax1.plot(dates, players, color="tab:blue", label="Players")
dates, staff = zip(*sorted(staff_counts.items()))
ax2.plot(dates, staff, color="tab:orange", label="Staff")

# Configure axes
ax1.set_xlabel("Date")
ax1.set_ylabel("Total Players")
ax2.set_ylabel("Staff")

# Add a legend
ax1.legend(loc="upper left")
ax2.legend(loc="upper right")

# Rotate x labels
for tick in ax1.get_xticklabels():
    tick.set_rotation(60)

# Display the chart
fig.tight_layout()
plt.show()
