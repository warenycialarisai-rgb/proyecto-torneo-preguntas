-- ============================================================
-- GUILD MASTER RPG - CONSULTAS SQL CON JOIN
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
