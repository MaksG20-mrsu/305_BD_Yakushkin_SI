import csv
import re
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
SQL_FILE = BASE_DIR / "db_init.sql"


def sql_string(value):
    if value is None:
        return "NULL"

    value = str(value).replace("'", "''")
    return f"'{value}'"


def read_movies():
    movies = []

    with open(BASE_DIR / "movies.csv", "r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            movie_id = int(row["movieId"])
            raw_title = row["title"]
            genres = row["genres"]

            match = re.match(r"^(.*)\s+\((\d{4})\)$", raw_title)

            if match:
                title = match.group(1)
                year = int(match.group(2))
            else:
                title = raw_title
                year = None

            movies.append(
                (
                    movie_id,
                    title,
                    year,
                    genres,
                )
            )

    return movies


def read_ratings():
    ratings = []

    with open(BASE_DIR / "ratings.csv", "r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            ratings.append(
                (
                    int(row["userId"]),
                    int(row["movieId"]),
                    float(row["rating"]),
                    int(row["timestamp"]),
                )
            )

    return ratings


def read_tags():
    tags = []

    with open(BASE_DIR / "tags.csv", "r", encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)

        for row in reader:
            tags.append(
                (
                    int(row["userId"]),
                    int(row["movieId"]),
                    row["tag"],
                    int(row["timestamp"]),
                )
            )

    return tags


def read_users():
    users = []

    with open(BASE_DIR / "users.txt", "r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
            line = line.rstrip("\n\r")

            if not line:
                continue

            fields = line.split("|")

            if len(fields) != 6:
                raise ValueError(
                    f"Ошибка в users.txt, строка {line_number}: "
                    f"ожидалось 6 полей, получено {len(fields)}"
                )

            user_id, name, email, gender, register_date, occupation = fields

            users.append(
                (
                    int(user_id),
                    name,
                    email,
                    gender,
                    register_date,
                    occupation,
                )
            )

    return users


def generate_sql():
    movies = read_movies()
    ratings = read_ratings()
    tags = read_tags()
    users = read_users()

    with open(SQL_FILE, "w", encoding="utf-8", newline="\n") as file:

        file.write("-- SQL generated automatically by make_db_init.py\n\n")

        file.write("BEGIN TRANSACTION;\n\n")

        file.write("DROP TABLE IF EXISTS movies;\n")
        file.write("DROP TABLE IF EXISTS ratings;\n")
        file.write("DROP TABLE IF EXISTS tags;\n")
        file.write("DROP TABLE IF EXISTS users;\n\n")

        file.write(
            """CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);

"""
        )

        file.write(
            """CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

"""
        )

        file.write(
            """CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

"""
        )

        file.write(
            """CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    gender TEXT NOT NULL,
    register_date TEXT NOT NULL,
    occupation TEXT NOT NULL
);

"""
        )

        for movie_id, title, year, genres in movies:
            file.write(
                "INSERT INTO movies "
                "(id, title, year, genres) VALUES "
                f"({movie_id}, {sql_string(title)}, "
                f"{year if year is not None else 'NULL'}, "
                f"{sql_string(genres)});\n"
            )

        file.write("\n")

        for index, (user_id, movie_id, rating, timestamp) in enumerate(
            ratings, start=1
        ):
            file.write(
                "INSERT INTO ratings "
                "(id, user_id, movie_id, rating, timestamp) VALUES "
                f"({index}, {user_id}, {movie_id}, "
                f"{rating}, {timestamp});\n"
            )

        file.write("\n")

        for index, (user_id, movie_id, tag, timestamp) in enumerate(
            tags, start=1
        ):
            file.write(
                "INSERT INTO tags "
                "(id, user_id, movie_id, tag, timestamp) VALUES "
                f"({index}, {user_id}, {movie_id}, "
                f"{sql_string(tag)}, {timestamp});\n"
            )

        file.write("\n")

        for user_id, name, email, gender, register_date, occupation in users:
            file.write(
                "INSERT INTO users "
                "(id, name, email, gender, register_date, occupation) VALUES "
                f"({user_id}, {sql_string(name)}, "
                f"{sql_string(email)}, {sql_string(gender)}, "
                f"{sql_string(register_date)}, "
                f"{sql_string(occupation)});\n"
            )

        file.write("\n")
        file.write("COMMIT;\n")

    print("SQL-файл успешно создан:")
    print(SQL_FILE)
    print()
    print(f"movies:  {len(movies)}")
    print(f"ratings: {len(ratings)}")
    print(f"tags:    {len(tags)}")
    print(f"users:   {len(users)}")


if __name__ == "__main__":
    generate_sql()