# Структура файлов с данными

## genres.txt
Файл содержит идентификаторы жанров и их названия.
Формат строки: genreId^genre.

## movies.csv
Файл содержит информацию о фильмах.
Поля: movieId, title, genres.
Разделитель полей: запятая.

## occupation.txt
Файл содержит идентификаторы профессий и их названия.
Формат строки: occupationId^occupation.

## ratings.csv
Файл содержит оценки пользователей фильмам.
Поля: userId, movieId, rating, timestamp.
Разделитель полей: запятая.

## tags.csv
Файл содержит пользовательские теги для фильмов.
Поля: userId, movieId, tag, timestamp.
Разделитель полей: запятая.

## users.txt
Файл содержит информацию о пользователях.
Формат строки: userId^gender^age^occupationId^zipCode.