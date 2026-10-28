#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Пары пользователей, оценивших один и тот же фильм"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT
    u1.name AS 'Пользователь 1',
    u2.name AS 'Пользователь 2',
    m.title AS 'Фильм'
FROM ratings r1
JOIN ratings r2
    ON r1.movie_id = r2.movie_id
   AND r1.user_id < r2.user_id
JOIN users u1 ON u1.id = r1.user_id
JOIN users u2 ON u2.id = r2.user_id
JOIN movies m ON m.id = r1.movie_id
ORDER BY u1.name, u2.name, m.title
LIMIT 100;
"
echo " "

echo "2. Десять последних оценок от разных пользователей"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH latest AS (
    SELECT
        r.user_id,
        r.movie_id,
        r.rating,
        r.timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.user_id
            ORDER BY r.timestamp DESC
        ) AS rn
    FROM ratings r
)
SELECT
    m.title AS 'Фильм',
    u.name AS 'Пользователь',
    l.rating AS 'Оценка',
    date(l.timestamp, 'unixepoch') AS 'Дата'
FROM latest l
JOIN movies m ON m.id = l.movie_id
JOIN users u ON u.id = l.user_id
WHERE l.rn = 1
ORDER BY l.timestamp DESC
LIMIT 10;
"
echo " "

echo "3. Фильмы с максимальным и минимальным средним рейтингом"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH averages AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
limits AS (
    SELECT MAX(avg_rating) AS max_avg, MIN(avg_rating) AS min_avg
    FROM averages
)
SELECT
    a.title AS 'Фильм',
    a.year AS 'Год',
    ROUND(a.avg_rating, 2) AS 'Средний рейтинг',
    CASE
        WHEN a.avg_rating = l.max_avg THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM averages a
CROSS JOIN limits l
WHERE a.avg_rating = l.max_avg OR a.avg_rating = l.min_avg
ORDER BY a.year, a.title;
"
echo " "

echo "4. Количество и средний рейтинг оценок женщин за 2010-2012 годы"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT
    COUNT(*) AS 'Количество оценок',
    ROUND(AVG(r.rating), 2) AS 'Средний рейтинг'
FROM ratings r
JOIN users u ON u.id = r.user_id
WHERE LOWER(u.gender) = 'female'
  AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2010' AND '2012';
"
echo " "

echo "5. Средний рейтинг и ранг фильмов"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH averages AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
ranked AS (
    SELECT
        title,
        year,
        avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS movie_rank
    FROM averages
)
SELECT
    title AS 'Фильм',
    year AS 'Год',
    ROUND(avg_rating, 2) AS 'Средний рейтинг',
    movie_rank AS 'Ранг'
FROM ranked
ORDER BY year, title
LIMIT 20;
"
echo " "

echo "6. Десять недавно зарегистрированных пользователей"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT
    substr(name, instr(name, ' ') + 1)
    || ' ' ||
    substr(name, 1, instr(name, ' ') - 1)
    || '|' ||
    register_date AS 'Фамилия Имя|Дата регистрации'
FROM users
ORDER BY register_date DESC
LIMIT 10;
"
echo " "

echo "7. Таблица умножения от 1 до 10"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE
numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
),
multiplication(a, b) AS (
    SELECT 1, 1
    UNION ALL
    SELECT
        CASE WHEN b = 10 THEN a + 1 ELSE a END,
        CASE WHEN b = 10 THEN 1 ELSE b + 1 END
    FROM multiplication
    WHERE NOT (a = 10 AND b = 10)
)
SELECT printf('%dx%d=%d', a, b, a * b) AS 'Таблица умножения'
FROM multiplication
ORDER BY a, b;
"
echo " "

echo "8. Список всех жанров"
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL AND genres <> ''

    UNION ALL

    SELECT
        movie_id,
        substr(rest, instr(rest, '|') + 1),
        substr(rest, 1, instr(rest, '|') - 1)
    FROM split
    WHERE rest <> ''
)
SELECT DISTINCT genre AS 'Жанр'
FROM split
WHERE genre <> ''
ORDER BY genre;
"
echo " "