-- INFORMATICA II - GRUPO 6 - GUILD MASTER RPG
-- FASE DDL - SQLite / José Vélez
-- Soporte con script ChatGPT terra/alto 6.1

-- Activa la comprobacion de claves foraneas en esta conexion.
PRAGMA foreign_keys = ON;

-- 1. AVENTURERO ---------------------------------------------------------------
CREATE TABLE Aventurero (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre         VARCHAR(50) NOT NULL,
    clase          VARCHAR(20) NOT NULL
                   CONSTRAINT chk_aventurero_clase
                   CHECK (clase IN ('guerrero', 'mago', 'arquero')),
    nivel          INT NOT NULL DEFAULT 1
                   CONSTRAINT chk_aventurero_nivel CHECK (nivel >= 1),
    salario_diario DECIMAL(10,2) NOT NULL
                   CONSTRAINT chk_aventurero_salario CHECK (salario_diario > 0),
    estado         VARCHAR(20) NOT NULL DEFAULT 'disponible'
                   CONSTRAINT chk_aventurero_estado
                   CHECK (estado IN ('disponible', 'en_mision', 'herido')),
    experiencia    INT NOT NULL DEFAULT 0
                   CONSTRAINT chk_aventurero_experiencia CHECK (experiencia >= 0)
);

-- 2. MISION -------------------------------------------------------------------
CREATE TABLE Mision (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo           VARCHAR(100) NOT NULL,
    nivel_dificultad INT NOT NULL
                     CONSTRAINT chk_mision_dificultad CHECK (nivel_dificultad BETWEEN 1 AND 10),
    recompensa_oro   DECIMAL(10,2) NOT NULL
                     CONSTRAINT chk_mision_recompensa CHECK (recompensa_oro > 0),
    duracion_horas   INT NOT NULL
                     CONSTRAINT chk_mision_duracion CHECK (duracion_horas > 0),
    estado           VARCHAR(20) NOT NULL DEFAULT 'pendiente'
                     CONSTRAINT chk_mision_estado
                     CHECK (estado IN ('pendiente', 'en_progreso', 'completada', 'fallida'))
);

-- 3. EQUIPAMIENTO -------------------------------------------------------------
CREATE TABLE Equipamiento (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        VARCHAR(60) NOT NULL
                  CONSTRAINT uq_equipamiento_nombre UNIQUE,
    tipo          VARCHAR(20) NOT NULL
                  CONSTRAINT chk_equipamiento_tipo
                  CHECK (tipo IN ('arma', 'armadura', 'accesorio')),
    bonus_ataque  INT NOT NULL DEFAULT 0
                  CONSTRAINT chk_equipamiento_bonus_ataque CHECK (bonus_ataque >= 0),
    bonus_defensa INT NOT NULL DEFAULT 0
                  CONSTRAINT chk_equipamiento_bonus_defensa CHECK (bonus_defensa >= 0),
    costo_oro     DECIMAL(10,2) NOT NULL
                  CONSTRAINT chk_equipamiento_costo CHECK (costo_oro >= 0),
    CONSTRAINT chk_equipamiento_bonus_util
        CHECK (bonus_ataque > 0 OR bonus_defensa > 0)
);

-- 4. TESORO (MOVIMIENTOS FINANCIEROS) ------------------------------------------
CREATE TABLE Tesoro (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo      VARCHAR(30) NOT NULL
              CONSTRAINT chk_tesoro_tipo
              CHECK (tipo IN ('ingreso_mision', 'egreso_salario', 'egreso_equipo')),
    monto     DECIMAL(12,2) NOT NULL
              CONSTRAINT chk_tesoro_monto CHECK (monto > 0),
    concepto  VARCHAR(150) NOT NULL,
    id_mision INT NULL,
    CONSTRAINT chk_tesoro_ingreso_identificado
        CHECK (tipo <> 'ingreso_mision' OR id_mision IS NOT NULL),
    CONSTRAINT fk_tesoro_mision
        FOREIGN KEY (id_mision) REFERENCES Mision(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5. ASIGNACION_MISION (N:M) --------------------------------------------------
CREATE TABLE Asignacion_Mision (
    id_aventurero    INT NOT NULL,
    id_mision        INT NOT NULL,
    fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resultado        VARCHAR(20) NULL
                     CONSTRAINT chk_asignacion_resultado
                     CHECK (resultado IN ('exitoso', 'fallido', 'herido')),
    xp_ganada        INT NOT NULL DEFAULT 0
                     CONSTRAINT chk_asignacion_xp CHECK (xp_ganada >= 0),
    CONSTRAINT pk_asignacion_mision
        PRIMARY KEY (id_aventurero, id_mision),
    CONSTRAINT chk_asignacion_xp_sin_resultado
        CHECK (resultado IS NOT NULL OR xp_ganada = 0),
    CONSTRAINT fk_asignacion_aventurero
        FOREIGN KEY (id_aventurero) REFERENCES Aventurero(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asignacion_mision
        FOREIGN KEY (id_mision) REFERENCES Mision(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 6. INVENTARIO_AVENTURERO (N:M) ----------------------------------------------
CREATE TABLE Inventario_Aventurero (
    id_aventurero    INT NOT NULL,
    id_equipamiento  INT NOT NULL,
    fecha_adquisicion DATE NOT NULL DEFAULT (CURRENT_DATE),
    equipado         BOOLEAN NOT NULL DEFAULT 0
                     CONSTRAINT chk_inventario_equipado CHECK (equipado IN (0, 1)),
    cantidad         INT NOT NULL DEFAULT 1
                     CONSTRAINT chk_inventario_cantidad CHECK (cantidad > 0),
    CONSTRAINT pk_inventario_aventurero
        PRIMARY KEY (id_aventurero, id_equipamiento),
    CONSTRAINT fk_inventario_aventurero
        FOREIGN KEY (id_aventurero) REFERENCES Aventurero(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_inventario_equipamiento
        FOREIGN KEY (id_equipamiento) REFERENCES Equipamiento(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Fin del modulo DDL. El equipo integrara datos semilla, 10 consultas,
-- transaccion con ROLLBACK y vista en UN SOLO .sql para la entrega final.

-- =============================================================================
-- DATOS SEMILLA (DML) /  Gabriela A. Rodriguez
-- =============================================================================

-- 1. CARGA DE 6 AVENTUREROS ---------------------------------------------------
INSERT INTO Aventurero (nombre, clase, nivel, salario_diario, estado, experiencia) VALUES
('Kaelen', 'guerrero', 5, 120.00, 'disponible', 2500),
('Lyra', 'mago', 7, 180.50, 'en_mision', 4800),
('Thorne', 'arquero', 3, 85.00, 'disponible', 900),
('Valeria', 'guerrero', 9, 250.00, 'herido', 8200),
('Eldrin', 'mago', 4, 110.00, 'disponible', 1600),
('Sylvanas', 'arquero', 6, 155.00, 'en_mision', 3700);

-- 2. CARGA DE 8 MISIONES ------------------------------------------------------
INSERT INTO Mision (titulo, nivel_dificultad, recompensa_oro, duracion_horas, estado) VALUES
('Limpiar cueva de trasgos', 2, 300.00, 6, 'completada'),
('Escolta de caravana a la capital', 5, 850.00, 24, 'en_progreso'),
('Caza del grifo oscuro', 9, 2500.00, 48, 'pendiente'),
('Rescate en las minas abandonadas', 4, 600.00, 12, 'completada'),
('Defensa de la muralla norte', 7, 1400.00, 36, 'en_progreso'),
('Recoleccion de hierbas lunares', 1, 150.00, 4, 'completada'),
('Infiltracion en la fortaleza roja', 8, 1950.00, 30, 'fallida'),
('Purga del pantano maldito', 6, 1100.00, 18, 'pendiente');

-- 3. CARGA DE 10 ITEMS DE EQUIPAMIENTO ----------------------------------------
INSERT INTO Equipamiento (nombre, tipo, bonus_ataque, bonus_defensa, costo_oro) VALUES
('Espada Larga de Acero', 'arma', 15, 2, 150.00),
('Tunica Arcana', 'armadura', 5, 12, 220.00),
('Anillo de Precision', 'accesorio', 8, 0, 110.00),
('Arco Largo Elfico', 'arma', 18, 0, 240.00),
('Escudo Torre de Hierro', 'armadura', 0, 20, 190.00),
('Baculo de Fuego', 'arma', 24, 3, 350.00),
('Cota de Malla Reforzada', 'armadura', 0, 16, 175.00),
('Amuleto de Vitalidad', 'accesorio', 2, 10, 160.00),
('Dagas Gemelas Sombras', 'arma', 14, 4, 180.00),
('Botas de Sigilo', 'accesorio', 4, 6, 130.00);

-- 4. MOVIMIENTOS FINANCIEROS EN TESORO -----------
INSERT INTO Tesoro (tipo, monto, concepto, id_mision) VALUES
('ingreso_mision', 300.00, 'Recompensa por limpiar cueva de trasgos', 1),
('ingreso_mision', 600.00, 'Pago por rescate en minas abandonadas', 4),
('ingreso_mision', 150.00, 'Entrega de hierbas lunares al gremio', 6),
('egreso_equipo', 150.00, 'Compra de Espada Larga de Acero', NULL),
('egreso_equipo', 350.00, 'Adquisicion de Baculo de Fuego', NULL),
('egreso_salario', 120.00, 'Pago de jornada a Kaelen', NULL),
('egreso_salario', 250.00, 'Pago y compensacion medica a Valeria', NULL);

-- 5. ASIGNACION DE MISIONES A AVENTUREROS -------------------------------------
INSERT INTO Asignacion_Mision (id_aventurero, id_mision, resultado, xp_ganada) VALUES
(1, 1, 'exitoso', 350),
(3, 1, 'exitoso', 350),
(2, 2, NULL, 0),
(6, 5, NULL, 0),
(4, 7, 'herido', 200),
(5, 4, 'exitoso', 500),
(3, 6, 'exitoso', 150);

-- 6. INVENTARIO DE LOS AVENTUREROS --------------------------------------------
INSERT INTO Inventario_Aventurero (id_aventurero, id_equipamiento, equipado, cantidad) VALUES
(1, 1, 1, 1),
(1, 5, 1, 1),
(2, 2, 1, 1),
(2, 6, 1, 1),
(3, 4, 1, 1),
(3, 3, 0, 2),
(4, 7, 1, 1),
(4, 8, 1, 1),
(5, 2, 0, 1),
(6, 9, 1, 1),
(6, 10, 1, 1);

-- =============================================================================
-- SUBCONSULTAS /  Cristian Acevedo
-- =============================================================================

-- 1. Subconsulta escalar en WHERE: aventureros que cobran más que el salario promedio.
SELECT nombre, clase, salario_diario
FROM Aventurero
WHERE salario_diario > (SELECT AVG(salario_diario) FROM Aventurero);

-- Devuelve Lyra (180.50), Valeria (250.00) y Sylvanas (155.00).

-- 2. Subconsulta con IN: aventureros que completaron al menos una misión con éxito.
SELECT id, nombre, nivel
FROM Aventurero
WHERE id IN (
   SELECT id_aventurero
   FROM Asignacion_Mision
   WHERE resultado = 'exitoso'
);

-- Devuelve Kaelen, Thorne y Eldrin.

-- 3. Subconsulta con NOT EXISTS: aventureros que nunca tuvieron una misión asignada.
SELECT a.id, a.nombre, a.clase
FROM Aventurero a
WHERE NOT EXISTS (
    SELECT 1
    FROM Asignacion_Mision am
    WHERE am.id_aventurero = a.id
);

-- En tus datos semilla todos tienen al menos una asignación, así que devuelve vacío. 
-- Es correcto, y sirve para probar la consulta después de insertar un aventurero nuevo.

-- 4. Subconsulta correlacionada: equipos cuyo costo supera el promedio de su propio tipo.
SELECT e.nombre, e.tipo, e.costo_oro
FROM Equipamiento e
WHERE e.costo_oro > (
    SELECT AVG(e2.costo_oro)
    FROM Equipamiento e2
    WHERE e2.tipo = e.tipo
);

-- Devuelve Tunica Arcana (armadura, 220), Arco Largo Elfico (arma, 240), Baculo de Fuego (arma, 350) y Amuleto de Vitalidad (accesorio, 160).

-- 5. Subconsulta en FROM (tabla derivada): total de oro invertido en equipo por aventurero.
SELECT a.nombre, inv.total_invertido
FROM Aventurero a
JOIN (
    SELECT ia.id_aventurero,
           SUM(e.costo_oro * ia.cantidad) AS total_invertido
    FROM Inventario_Aventurero ia
    JOIN Equipamiento e ON e.id = ia.id_equipamiento
    GROUP BY ia.id_aventurero
) inv ON inv.id_aventurero = a.id
ORDER BY inv.total_invertido DESC;

-- Devuelve: Lyra 570, Kaelen 340, Thorne 460 (el anillo cuenta ×2), Valeria 335, Sylvanas 310, Eldrin 220.
-- Con el ORDER BY queda: Lyra 570, Thorne 460, Kaelen 340, Valeria 335, Sylvanas 310, Eldrin 220.

-- ============================================================
-- GUILD MASTER RPG - CONSULTAS SQL CON JOIN / Maria Fernanda Almiron R.
-- Proyecto B: Gestión de un gremio de aventureros
-- Motor previsto: MySQL / MariaDB
--
-- IMPORTANTE:
-- Este archivo contiene las 10 consultas solicitadas para el proyecto.
-- Se utiliza el siguiente esquema de nombres y columnas:
--
-- aventurero(id, nombre, clase, nivel, salario_diario, estado)
-- mision(id, titulo, nivel_dificultad, recompensa_oro,
--        duracion_horas, estado)
-- equipamiento(id, nombre, tipo, bonus_ataque, bonus_defensa, costo_oro)
-- tesoro(id, fecha_transaccion, tipo, monto, concepto)
-- asignacion_mision(id_aventurero, id_mision, fecha_asignacion)
-- inventario_aventurero(id_aventurero, id_equipamiento, cantidad)
--
-- Las tablas intermedias relacionan aventureros con misiones y
-- aventureros con equipamientos.
-- Si el modelo del equipo utiliza otros nombres, adaptar los identificadores.
-- ============================================================


-- 1. RENTABILIDAD DEL GREMIO
-- Calcula el total de oro ingresado por misiones y el total gastado
-- en salarios y equipamiento. Agrupa los movimientos por tipo.
SELECT
    tipo,
    SUM(monto) AS total_oro
FROM tesoro
GROUP BY tipo;


-- 2. TASA DE ÉXITO POR CLASE DE AVENTURERO
-- Cuenta las misiones asignadas y las completadas por cada clase.
-- Se utiliza LEFT JOIN para que también aparezcan clases sin misiones.
SELECT
    a.clase,
    COUNT(am.id_mision) AS misiones_asignadas,
    SUM(CASE WHEN m.estado = 'completada' THEN 1 ELSE 0 END)
        AS misiones_completadas,
    ROUND(
        100.0 * SUM(CASE WHEN m.estado = 'completada' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(am.id_mision), 0),
        2
    ) AS porcentaje_exito
FROM aventurero a
LEFT JOIN asignacion_mision am
    ON am.id_aventurero = a.id
LEFT JOIN mision m
    ON m.id = am.id_mision
GROUP BY a.clase;


-- 3. TOP 3 DE AVENTUREROS MÁS VALIOSOS
-- Ordena a los aventureros según la relación entre misiones completadas
-- y salario diario. Un valor mayor indica más misiones completadas
-- en relación con el sueldo diario.
SELECT
    a.id,
    a.nombre,
    a.clase,
    a.salario_diario,
    COUNT(CASE WHEN m.estado = 'completada' THEN 1 END)
        AS misiones_completadas,
    ROUND(
        COUNT(CASE WHEN m.estado = 'completada' THEN 1 END)
        / NULLIF(a.salario_diario, 0),
        4
    ) AS indice_valor
FROM aventurero a
LEFT JOIN asignacion_mision am
    ON am.id_aventurero = a.id
LEFT JOIN mision m
    ON m.id = am.id_mision
GROUP BY a.id, a.nombre, a.clase, a.salario_diario
ORDER BY indice_valor DESC
LIMIT 3;


-- 4. AVENTUREROS QUE PARTICIPAN EN CADA MISIÓN
-- Muestra el título de la misión y los aventureros que fueron asignados.
-- Utiliza tres tablas relacionadas mediante JOIN.
SELECT
    m.titulo AS mision,
    a.nombre AS aventurero,
    a.clase,
    a.nivel,
    m.estado AS estado_mision
FROM mision m
INNER JOIN asignacion_mision am
    ON am.id_mision = m.id
INNER JOIN aventurero a
    ON a.id = am.id_aventurero
ORDER BY m.titulo, a.nombre;


-- 5. AVENTUREROS QUE NUNCA FUERON ASIGNADOS A UNA MISIÓN
-- Anti-join: busca aventureros para los que no existe una asignación.
SELECT
    a.id,
    a.nombre,
    a.clase,
    a.estado
FROM aventurero a
LEFT JOIN asignacion_mision am
    ON am.id_aventurero = a.id
WHERE am.id_aventurero IS NULL;


-- 6. INVENTARIO DE CADA AVENTURERO
-- Muestra qué equipamiento tiene cada aventurero, su cantidad
-- y los bonus que aporta cada objeto.
SELECT
    a.nombre AS aventurero,
    e.nombre AS equipamiento,
    e.tipo,
    ia.cantidad,
    e.bonus_ataque,
    e.bonus_defensa
FROM aventurero a
INNER JOIN inventario_aventurero ia
    ON ia.id_aventurero = a.id
INNER JOIN equipamiento e
    ON e.id = ia.id_equipamiento
ORDER BY a.nombre, e.tipo, e.nombre;


-- 7. MISIONES Y CANTIDAD DE AVENTUREROS ASIGNADOS
-- Incluye también las misiones que todavía no tienen aventureros.
SELECT
    m.id,
    m.titulo,
    m.nivel_dificultad,
    m.estado,
    COUNT(am.id_aventurero) AS cantidad_aventureros
FROM mision m
LEFT JOIN asignacion_mision am
    ON am.id_mision = m.id
GROUP BY
    m.id, m.titulo, m.nivel_dificultad, m.estado
ORDER BY cantidad_aventureros DESC;


-- 8. AVENTUREROS CON NIVEL SUPERIOR AL PROMEDIO
-- Utiliza una subconsulta escalar para calcular el nivel promedio.
-- El JOIN agrega información de las misiones en las que participan.
SELECT DISTINCT
    a.id,
    a.nombre,
    a.clase,
    a.nivel
FROM aventurero a
INNER JOIN asignacion_mision am
    ON am.id_aventurero = a.id
WHERE a.nivel > (
    SELECT AVG(nivel)
    FROM aventurero
)
ORDER BY a.nivel DESC;


-- 9. CLASES CON MÁS DE UNA MISIÓN COMPLETADA
-- Agrupa por clase y utiliza HAVING para filtrar los grupos
-- que superan una misión completada.
SELECT
    a.clase,
    COUNT(*) AS total_misiones_completadas
FROM aventurero a
INNER JOIN asignacion_mision am
    ON am.id_aventurero = a.id
INNER JOIN mision m
    ON m.id = am.id_mision
WHERE m.estado = 'completada'
GROUP BY a.clase
HAVING COUNT(*) > 1
ORDER BY total_misiones_completadas DESC;


-- 10. BONUS TOTAL DE ATAQUE Y DEFENSA POR AVENTURERO
-- Suma los bonus de todos los objetos que tiene cada aventurero.
-- COALESCE permite mostrar 0 cuando no tiene equipamiento.
SELECT
    a.id,
    a.nombre,
    COALESCE(SUM(ia.cantidad * e.bonus_ataque), 0)
        AS bonus_total_ataque,
    COALESCE(SUM(ia.cantidad * e.bonus_defensa), 0)
        AS bonus_total_defensa
FROM aventurero a
LEFT JOIN inventario_aventurero ia
    ON ia.id_aventurero = a.id
LEFT JOIN equipamiento e
    ON e.id = ia.id_equipamiento
GROUP BY a.id, a.nombre
ORDER BY bonus_total_ataque DESC, bonus_total_defensa DESC;


-- ============================================================
-- FIN DE LAS CONSULTAS
-- ============================================================
