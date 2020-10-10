import os
import argparse
import re
import matplotlib.pyplot as plt


def getSteamID(line):
    """
    Extract a SteamID from a specific line
    This uses regex because I'm cool
    """
    matches = re.search(r"STEAM_[0-5]:[01]:\d+", line)
    if matches:
        return matches.group()
    else:
        return False


def parseFile(filename, id, results):
    """
    Parses a log file to generate a comprehensive report for that date
    This logs incidents with a specific ID according to a filter
    """
    current_players = set()

    # Filter through all the lines in the log file
    with open(filename, encoding="utf8") as f:
        for line in f:
            line = line.rstrip()

            # Keep track of players currently in the game
            if "joined the game" in line:
                player_id = getSteamID(line)
                if not player_id:
                    continue

                if player_id not in current_players:
                    current_players.add(player_id)
            elif "left the game" in line:
                player_id = getSteamID(line)
                if not player_id:
                    continue

                if player_id in current_players:
                    current_players.remove(player_id)

            # Logging of physgun stuff
            if not id in line:
                continue

            if "ms physgun" in line:
                count = len(current_players)
                current = results.get(count, 0)
                results[count] = current + 1

    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Search logs for specific command usages, while keeping track of playercounts"
    )
    parser.add_argument("id", help="SteamID to generate a report for")
    parser.add_argument("--directory", help="Input directory for logs.", default=".")
    args = parser.parse_args()

    total_results = {}

    # Run through all files in the directory
    for filename in os.listdir(args.directory):
        if filename.startswith("log_"):
            total_results = parseFile(
                args.directory + "/" + filename, args.id, total_results
            )

    # Plot the final results
    plt.bar(*zip(*total_results.items()))
    plt.ylabel("Command Usage")
    plt.xlabel("Players Online")
    plt.show()
