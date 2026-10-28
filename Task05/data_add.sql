PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- 1. Пять новых пользователей
INSERT INTO users (first_name, last_name, email, gender_id, register_date, occupation_id)
SELECT 'Никита', 'Саляев', 'nikita.salyaev@example.com', g.id, date('now'), o.id
FROM genders g CROSS JOIN occupations o
WHERE g.name='male' AND o.name='student'
AND NOT EXISTS (SELECT 1 FROM users WHERE email='nikita.salyaev@example.com');

INSERT INTO users (first_name, last_name, email, gender_id, register_date, occupation_id)
SELECT 'Максим', 'Сандин', 'maksim.sandin@example.com', g.id, date('now'), o.id
FROM genders g CROSS JOIN occupations o
WHERE g.name='male' AND o.name='student'
AND NOT EXISTS (SELECT 1 FROM users WHERE email='maksim.sandin@example.com');

INSERT INTO users (first_name, last_name, email, gender_id, register_date, occupation_id)
SELECT 'Раиль', 'Тимербаев', 'rail.timerbaev@example.com', g.id, date('now'), o.id
FROM genders g CROSS JOIN occupations o
WHERE g.name='male' AND o.name='student'
AND NOT EXISTS (SELECT 1 FROM users WHERE email='rail.timerbaev@example.com');

INSERT INTO users (first_name, last_name, email, gender_id, register_date, occupation_id)
SELECT 'Александр', 'Федотов', 'alexander.fedotov@example.com', g.id, date('now'), o.id
FROM genders g CROSS JOIN occupations o
WHERE g.name='male' AND o.name='student'
AND NOT EXISTS (SELECT 1 FROM users WHERE email='alexander.fedotov@example.com');

INSERT INTO users (first_name, last_name, email, gender_id, register_date, occupation_id)
SELECT 'Станислав', 'Якушкин', 'stanislav.yakushkin@example.com', g.id, date('now'), o.id
FROM genders g CROSS JOIN occupations o
WHERE g.name='male' AND o.name='student'
AND NOT EXISTS (SELECT 1 FROM users WHERE email='stanislav.yakushkin@example.com');

-- 2. Три фильма
INSERT INTO movies (title, year)
SELECT 'Dune: Part Two', 2024
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='Dune: Part Two' AND year=2024);

INSERT INTO movies (title, year)
SELECT 'Spider-Man: Across the Spider-Verse', 2023
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='Spider-Man: Across the Spider-Verse' AND year=2023);

INSERT INTO movies (title, year)
SELECT 'The Holdovers', 2023
WHERE NOT EXISTS (SELECT 1 FROM movies WHERE title='The Holdovers' AND year=2023);

-- 3. Жанры фильмов
INSERT OR IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title='Dune: Part Two' AND m.year=2024 AND g.name='Sci-Fi';

INSERT OR IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title='Spider-Man: Across the Spider-Verse' AND m.year=2023 AND g.name='Animation';

INSERT OR IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m CROSS JOIN genres g
WHERE m.title='The Holdovers' AND m.year=2023 AND g.name='Drama';

-- 4. Три оценки от Станислава Якушкина
INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.5
FROM users u CROSS JOIN movies m
WHERE u.email='stanislav.yakushkin@example.com'
AND m.title='Dune: Part Two' AND m.year=2024
AND NOT EXISTS (
    SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id
);

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 5.0
FROM users u CROSS JOIN movies m
WHERE u.email='stanislav.yakushkin@example.com'
AND m.title='Spider-Man: Across the Spider-Verse' AND m.year=2023
AND NOT EXISTS (
    SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id
);

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.0
FROM users u CROSS JOIN movies m
WHERE u.email='stanislav.yakushkin@example.com'
AND m.title='The Holdovers' AND m.year=2023
AND NOT EXISTS (
    SELECT 1 FROM ratings r WHERE r.user_id=u.id AND r.movie_id=m.id
);

COMMIT;