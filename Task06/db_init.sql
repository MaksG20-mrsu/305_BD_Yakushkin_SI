
PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- 1. Мастера автосервиса
CREATE TABLE masters (
    master_id INTEGER PRIMARY KEY,
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    phone TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    hire_date TEXT NOT NULL DEFAULT (date('now')),
    dismissal_date TEXT,
    salary_percent REAL NOT NULL DEFAULT 30
        CHECK (salary_percent BETWEEN 0 AND 100),
    is_active INTEGER NOT NULL DEFAULT 1
        CHECK (is_active IN (0, 1)),
    CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date),
    CHECK (
        (is_active = 1 AND dismissal_date IS NULL)
        OR (is_active = 0 AND dismissal_date IS NOT NULL)
    )
);

-- 2. График работы мастеров
CREATE TABLE master_schedule (
    schedule_id INTEGER PRIMARY KEY,
    master_id INTEGER NOT NULL,
    weekday INTEGER NOT NULL CHECK (weekday BETWEEN 0 AND 6),
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    FOREIGN KEY (master_id) REFERENCES masters(master_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (time(start_time) IS NOT NULL),
    CHECK (time(end_time) IS NOT NULL),
    CHECK (time(start_time) < time(end_time)),
    UNIQUE (master_id, weekday, start_time)
);

-- 3. Клиенты
CREATE TABLE clients (
    client_id INTEGER PRIMARY KEY,
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 4. Справочник услуг
CREATE TABLE services (
    service_id INTEGER PRIMARY KEY,
    service_name TEXT NOT NULL UNIQUE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    price REAL NOT NULL CHECK (price >= 0),
    description TEXT,
    is_active INTEGER NOT NULL DEFAULT 1
        CHECK (is_active IN (0, 1))
);

-- 5. Предварительная запись
CREATE TABLE appointments (
    appointment_id INTEGER PRIMARY KEY,
    client_id INTEGER NOT NULL,
    master_id INTEGER NOT NULL,
    start_at TEXT NOT NULL,
    end_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN (
            'planned', 'confirmed', 'completed',
            'cancelled', 'no_show'
        )),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (master_id) REFERENCES masters(master_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (datetime(start_at) IS NOT NULL),
    CHECK (datetime(end_at) IS NOT NULL),
    CHECK (datetime(start_at) < datetime(end_at))
);

-- 6. Услуги в предварительной записи
CREATE TABLE appointment_services (
    appointment_service_id INTEGER PRIMARY KEY,
    appointment_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    service_name_snapshot TEXT NOT NULL,
    duration_snapshot INTEGER NOT NULL CHECK (duration_snapshot > 0),
    price_snapshot REAL NOT NULL CHECK (price_snapshot >= 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE (appointment_id, service_id)
);

-- 7. Фактически выполненные работы
CREATE TABLE work_records (
    work_record_id INTEGER PRIMARY KEY,
    appointment_service_id INTEGER NOT NULL UNIQUE,
    master_id INTEGER NOT NULL,
    performed_at TEXT NOT NULL DEFAULT (datetime('now')),
    actual_price REAL NOT NULL CHECK (actual_price >= 0),
    salary_percent_snapshot REAL NOT NULL
        CHECK (salary_percent_snapshot BETWEEN 0 AND 100),
    work_status TEXT NOT NULL DEFAULT 'performed'
        CHECK (work_status IN ('performed', 'cancelled')),
    notes TEXT,
    FOREIGN KEY (appointment_service_id)
        REFERENCES appointment_services(appointment_service_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (master_id) REFERENCES masters(master_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Индексы для поиска и отчетов
CREATE INDEX idx_masters_name
    ON masters(last_name, first_name);

CREATE INDEX idx_schedule_master_weekday
    ON master_schedule(master_id, weekday);

CREATE INDEX idx_appointments_master_time
    ON appointments(master_id, start_at, end_at);

CREATE INDEX idx_appointments_client
    ON appointments(client_id);

CREATE INDEX idx_work_records_master_date
    ON work_records(master_id, performed_at);

-- Запрет пересечения записей одного мастера
CREATE TRIGGER trg_appointments_no_overlap
BEFORE INSERT ON appointments
WHEN NEW.status IN ('planned', 'confirmed')
BEGIN
    SELECT RAISE(ABORT, 'Мастер уже занят в это время')
    WHERE EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.master_id = NEW.master_id
          AND a.status IN ('planned', 'confirmed')
          AND datetime(NEW.start_at) < datetime(a.end_at)
          AND datetime(NEW.end_at) > datetime(a.start_at)
    );
END;

COMMIT;

-- =========================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- =========================================

BEGIN TRANSACTION;

-- Мастера
INSERT INTO masters
(master_id, last_name, first_name, middle_name, phone, email,
 hire_date, dismissal_date, salary_percent, is_active)
VALUES
(1, 'Иванов', 'Алексей', 'Сергеевич', '+79990000001',
 'ivanov@example.com', '2023-01-10', NULL, 35, 1),
(2, 'Петров', 'Дмитрий', 'Андреевич', '+79990000002',
 'petrov@example.com', '2022-05-15', NULL, 40, 1),
(3, 'Сидоров', 'Михаил', 'Игоревич', '+79990000003',
 'sidorov@example.com', '2020-03-01', '2025-12-31', 30, 0);

-- График работы
INSERT INTO master_schedule
(schedule_id, master_id, weekday, start_time, end_time)
VALUES
(1, 1, 1, '09:00', '18:00'),
(2, 1, 2, '09:00', '18:00'),
(3, 1, 3, '09:00', '18:00'),
(4, 2, 1, '10:00', '19:00'),
(5, 2, 2, '10:00', '19:00'),
(6, 2, 4, '10:00', '19:00');

-- Клиенты
INSERT INTO clients
(client_id, last_name, first_name, phone, email)
VALUES
(1, 'Смирнов', 'Иван', '+79991110001', 'smirnov@example.com'),
(2, 'Кузнецов', 'Павел', '+79991110002', 'kuznetsov@example.com'),
(3, 'Попов', 'Андрей', '+79991110003', 'popov@example.com');

-- Услуги
INSERT INTO services
(service_id, service_name, duration_minutes, price, description)
VALUES
(1, 'Замена масла', 40, 2500, 'Замена моторного масла и фильтра'),
(2, 'Диагностика двигателя', 60, 3000, 'Компьютерная диагностика'),
(3, 'Замена тормозных колодок', 90, 4500, 'Замена передних тормозных колодок'),
(4, 'Развал-схождение', 50, 3500, 'Регулировка углов колес'),
(5, 'Замена воздушного фильтра', 20, 800, 'Замена воздушного фильтра');

-- Предварительные записи
INSERT INTO appointments
(appointment_id, client_id, master_id, start_at, end_at, status, notes)
VALUES
(1, 1, 1, '2026-11-24 09:00:00', '2026-11-24 10:40:00',
 'completed', 'Плановое обслуживание'),
(2, 2, 2, '2026-11-24 11:00:00', '2026-11-24 12:30:00',
 'completed', 'Проверка автомобиля'),
(3, 3, 1, '2026-11-26 10:00:00', '2026-11-26 11:30:00',
 'confirmed', 'Предварительная запись');

-- Услуги в записях
INSERT INTO appointment_services
(appointment_service_id, appointment_id, service_id,
 service_name_snapshot, duration_snapshot, price_snapshot)
VALUES
(1, 1, 1, 'Замена масла', 40, 2500),
(2, 1, 5, 'Замена воздушного фильтра', 20, 800),
(3, 2, 2, 'Диагностика двигателя', 60, 3000),
(4, 2, 3, 'Замена тормозных колодок', 90, 4500),
(5, 3, 4, 'Развал-схождение', 50, 3500);

-- Фактически выполненные работы
INSERT INTO work_records
(work_record_id, appointment_service_id, master_id,
 performed_at, actual_price, salary_percent_snapshot, work_status, notes)
VALUES
(1, 1, 1, '2026-11-24 09:40:00', 2500, 35, 'performed', NULL),
(2, 2, 1, '2026-11-24 10:20:00', 800, 35, 'performed', NULL),
(3, 3, 2, '2026-11-24 12:00:00', 3000, 40, 'performed', NULL),
(4, 4, 2, '2026-11-24 12:30:00', 4500, 40, 'performed', NULL);

COMMIT;
