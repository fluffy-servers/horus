import os
import argparse


def filter_physgun(line):
    """
    Filter the logs to only show give commands and physgun usage
    This also will attempt to log things that look like propblocking warnings
    """
    # Log anything that looks like a propblocking warning
    if ("block" in line) or ("prop" in line):
        return True

    # Log any self-physgun gives
    if "ms physgun" in line:
        return True

    # Log any weapon gives (that aren't to everyone)
    if "ms give" in line and not "ms give *" in line:
        return True

    # Don't log anything else
    return False


def filter_all(line):
    """
    Comprehensive logging of all Maestro commands
    This excludes some unimportant things such as note checking and admin chats
    """
    # Don't log things that aren't Maestro commands
    if not ("ms " in line):
        return False

    # Don't log note checks
    if "ms notes" in line:
        return False

    # Don't log admin chat
    if "ms admin" in line:
        return False

    # All other commands should be logged
    return True


# Define the filter modes for command-line usage
filter_modes = {"all": filter_all, "physgun": filter_physgun}


def parseFile(filename, log, id):
    """
    Parses a log file to generate a comprehensive report for that date
    This logs incidents with a specific ID according to a filter
    """
    in_game = False

    # Write a date header for the filename
    print("=========", file=log)
    print(filename, file=log)
    print("=========", file=log)

    # Filter through all the lines in the log file
    with open(filename, encoding="utf8") as f:
        for line in f:
            line = line.rstrip()

            # We only care about incidents with a specific ID
            if not (id in line):
                continue

            # Keep track of joins and leaves
            if not in_game and "joined the game" in line:
                print(line, file=log)
                in_game = True
                continue
            elif "left the game" in line:
                print(line, file=log)
                in_game = False
                continue

            # Print anything else that flags the filter
            if filter_all(id, line):
                print(line, file=log)

    # Add two new lines at the end of each date block
    print("\n\n", file=log)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Combine and filter multiple logs into a single user report"
    )
    parser.add_argument("id", help="SteamID to generate a report for")
    parser.add_argument("--directory", help="Input directory for logs.", default=".")
    parser.add_argument("--output", help="Output report location", default="report.txt")
    args = parser.parse_args()

    # Open log file
    log_file = open(args.output, "w", encoding="utf8")

    # Run through all files in the directory
    for filename in os.listdir(args.directory):
        if filename.startswith("log_"):
            parseFile(filename, log_file, args.id)

