-- ============================================
-- SISTEMA UNIVERSAL DE RESERVAS
-- Base de datos: MySQL 8.0+
-- ============================================

CREATE DATABASE IF NOT EXISTS `railway` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `railway`;

-- ============================================
-- TABLA: users
-- Usuarios del sistema (autenticación)
-- ============================================
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `fullname` VARCHAR(100) NOT NULL COMMENT 'Nombre completo del usuario',
  `email` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Correo electrónico (usado para login)',
  `password` VARCHAR(60) NOT NULL COMMENT 'Contraseña encriptada con bcrypt',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Usuarios del sistema de reservas';

-- ============================================
-- TABLA: personas
-- Datos extendidos de contacto
-- ============================================
CREATE TABLE IF NOT EXISTS `personas` (
  `idpersonas` INT NOT NULL AUTO_INCREMENT,
  `identificacion` VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Documento de identidad',
  `nombres` VARCHAR(256) DEFAULT NULL COMMENT 'Nombres del cliente',
  `apepat` VARCHAR(128) DEFAULT NULL COMMENT 'Apellido paterno',
  `apemat` VARCHAR(128) DEFAULT NULL COMMENT 'Apellido materno',
  `telefono` VARCHAR(15) DEFAULT NULL COMMENT 'Teléfono de contacto',
  `correo` VARCHAR(256) DEFAULT NULL COMMENT 'Correo electrónico de contacto',
  `idusuario` INT DEFAULT NULL COMMENT 'Referencia al usuario del sistema',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idpersonas`),
  INDEX `idx_usuario` (`idusuario`),
  CONSTRAINT `fk_personas_users` FOREIGN KEY (`idusuario`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Datos personales y de contacto de clientes y profesionales';

-- ============================================
-- TABLA: clientes
-- Información adicional de clientes
-- ============================================
CREATE TABLE IF NOT EXISTS `clientes` (
  `idclientes` INT NOT NULL AUTO_INCREMENT,
  `observaciones` TEXT DEFAULT NULL COMMENT 'Notas u observaciones adicionales del cliente',
  `idpersonas` INT NOT NULL COMMENT 'Referencia a datos personales',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idclientes`, `idpersonas`),
  INDEX `idx_personas` (`idpersonas`),
  CONSTRAINT `fk_clientes_personas` FOREIGN KEY (`idpersonas`) REFERENCES `personas` (`idpersonas`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Información adicional de clientes del sistema';

-- Mantener compatibilidad con código existente (alias pacientes -> clientes)
CREATE OR REPLACE VIEW `pacientes` AS SELECT 
  `idclientes` AS `idpacientes`,
  `observaciones` AS `prevision`,
  `idpersonas`,
  `created_at`
FROM `clientes`;

-- ============================================
-- TABLA: servicios
-- Catálogo de servicios disponibles
-- ============================================
CREATE TABLE IF NOT EXISTS `servicios` (
  `idservicios` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(256) NOT NULL COMMENT 'Nombre del servicio',
  `descripcion` TEXT DEFAULT NULL COMMENT 'Descripción detallada del servicio',
  `duracion_minutos` INT DEFAULT 60 COMMENT 'Duración estimada en minutos',
  `activo` TINYINT(1) DEFAULT 1 COMMENT 'Estado del servicio (1=activo, 0=inactivo)',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idservicios`),
  INDEX `idx_activo` (`activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Catálogo de servicios ofrecidos';

-- ============================================
-- TABLA: profesionales (empleados)
-- Personas que ofrecen servicios
-- ============================================
CREATE TABLE IF NOT EXISTS `profesionales` (
  `idprofesionales` INT NOT NULL AUTO_INCREMENT,
  `idpersonas` INT NOT NULL COMMENT 'Referencia a datos personales',
  `idservicios` INT NOT NULL COMMENT 'Servicio principal que ofrece',
  `estado` INT DEFAULT 1 COMMENT 'Estado (1=activo, 0=inactivo)',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idprofesionales`),
  INDEX `idx_personas` (`idpersonas`),
  INDEX `idx_servicios` (`idservicios`),
  CONSTRAINT `fk_profesionales_personas` FOREIGN KEY (`idpersonas`) REFERENCES `personas` (`idpersonas`) ON DELETE CASCADE,
  CONSTRAINT `fk_profesionales_servicios` FOREIGN KEY (`idservicios`) REFERENCES `servicios` (`idservicios`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Profesionales que ofrecen servicios en el sistema';

-- Mantener compatibilidad con código existente (alias empleados -> profesionales)
CREATE OR REPLACE VIEW `empleados` AS SELECT 
  `idprofesionales` AS `idempleados`,
  `idpersonas`,
  `idservicios`,
  `estado` AS `estados`,
  `created_at`
FROM `profesionales`;

-- ============================================
-- TABLA: bloques
-- Bloques de tiempo para agendar
-- ============================================
CREATE TABLE IF NOT EXISTS `bloque` (
  `idbloque` INT NOT NULL AUTO_INCREMENT,
  `comienza` TIME NOT NULL COMMENT 'Hora de inicio del bloque',
  `termina` TIME NOT NULL COMMENT 'Hora de fin del bloque',
  `duracion_minutos` INT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, comienza, termina)) STORED COMMENT 'Duración calculada en minutos',
  PRIMARY KEY (`idbloque`),
  INDEX `idx_horario` (`comienza`, `termina`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bloques de tiempo disponibles para reservas';

-- ============================================
-- TABLA: agenda
-- Disponibilidad de profesionales
-- ============================================
CREATE TABLE IF NOT EXISTS `agenda` (
  `idagenda` INT NOT NULL AUTO_INCREMENT,
  `idprofesionales` INT NOT NULL COMMENT 'Profesional asociado',
  `fecha` DATE NOT NULL COMMENT 'Fecha de disponibilidad',
  `idbloque` INT NOT NULL COMMENT 'Bloque de tiempo',
  `disponible` TINYINT(1) DEFAULT 1 COMMENT 'Disponibilidad (1=disponible, 0=no disponible)',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idagenda`),
  INDEX `idx_fecha` (`fecha`),
  INDEX `idx_profesional_fecha` (`idprofesionales`, `fecha`),
  CONSTRAINT `fk_agenda_profesionales` FOREIGN KEY (`idprofesionales`) REFERENCES `profesionales` (`idprofesionales`) ON DELETE CASCADE,
  CONSTRAINT `fk_agenda_bloque` FOREIGN KEY (`idbloque`) REFERENCES `bloque` (`idbloque`) ON DELETE RESTRICT,
  UNIQUE KEY `uk_profesional_fecha_bloque` (`idprofesionales`, `fecha`, `idbloque`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Disponibilidad de horarios por profesional';

-- Mantener compatibilidad con código existente
ALTER TABLE `agenda` ADD COLUMN IF NOT EXISTS `idempleados` INT GENERATED ALWAYS AS (`idprofesionales`) STORED;

-- ============================================
-- TABLA: reservas
-- Reservas realizadas por clientes
-- ============================================
CREATE TABLE IF NOT EXISTS `reservas` (
  `idreservas` INT NOT NULL AUTO_INCREMENT,
  `idusuario` INT NOT NULL COMMENT 'Usuario que realizó la reserva',
  `idagenda` INT NOT NULL COMMENT 'Slot de agenda reservado',
  `estado` INT DEFAULT 0 COMMENT 'Estado: 0=pendiente, 1=confirmada, 2=completada, 3=cancelada',
  `observaciones` TEXT DEFAULT NULL COMMENT 'Notas u observaciones de la reserva',
  `fechareserva` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora de creación de la reserva',
  `updated_at` TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`idreservas`),
  INDEX `idx_usuario` (`idusuario`),
  INDEX `idx_agenda` (`idagenda`),
  INDEX `idx_estado` (`estado`),
  INDEX `idx_fecha` (`fechareserva`),
  CONSTRAINT `fk_reservas_users` FOREIGN KEY (`idusuario`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reservas_agenda` FOREIGN KEY (`idagenda`) REFERENCES `agenda` (`idagenda`) ON DELETE RESTRICT,
  UNIQUE KEY `uk_agenda` (`idagenda`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reservas realizadas en el sistema';

-- ============================================
-- TABLA: sessions
-- Sesiones de usuario (express-session)
-- ============================================
CREATE TABLE IF NOT EXISTS `sessions` (
  `session_id` VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `expires` INT UNSIGNED NOT NULL,
  `data` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  PRIMARY KEY (`session_id`),
  INDEX `idx_expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sesiones de usuario del sistema';

-- ============================================
-- DATOS INICIALES: Bloques de tiempo estándar
-- ============================================
INSERT IGNORE INTO `bloque` (`idbloque`, `comienza`, `termina`) VALUES
(1, '08:00:00', '09:00:00'),
(2, '09:00:00', '10:00:00'),
(3, '10:00:00', '11:00:00'),
(4, '11:00:00', '12:00:00'),
(5, '12:00:00', '13:00:00'),
(6, '14:00:00', '15:00:00'),
(7, '15:00:00', '16:00:00'),
(8, '16:00:00', '17:00:00'),
(9, '17:00:00', '18:00:00'),
(10, '18:00:00', '19:00:00'),
(11, '19:00:00', '20:00:00'),
(12, '20:00:00', '21:00:00');

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de reservas con información completa
CREATE OR REPLACE VIEW `v_reservas_completas` AS
SELECT 
  r.idreservas,
  r.estado,
  r.observaciones AS observaciones_reserva,
  r.fechareserva,
  DATE_FORMAT(a.fecha, '%d/%m/%Y') AS fecha,
  DATE_FORMAT(b.comienza, '%H:%i') AS hora_inicio,
  DATE_FORMAT(b.termina, '%H:%i') AS hora_fin,
  s.nombre AS servicio,
  s.duracion_minutos,
  CONCAT(pp.nombres, ' ', pp.apepat, ' ', IFNULL(pp.apemat, '')) AS profesional,
  CONCAT(pc.nombres, ' ', pc.apepat, ' ', IFNULL(pc.apemat, '')) AS cliente,
  pc.telefono AS telefono_cliente,
  pc.correo AS correo_cliente
FROM reservas r
JOIN agenda a ON r.idagenda = a.idagenda
JOIN bloque b ON a.idbloque = b.idbloque
JOIN profesionales pr ON a.idprofesionales = pr.idprofesionales
JOIN personas pp ON pr.idpersonas = pp.idpersonas
JOIN servicios s ON pr.idservicios = s.idservicios
JOIN users u ON r.idusuario = u.id
LEFT JOIN personas pc ON pc.idusuario = u.id;

-- Vista de disponibilidad de horarios
CREATE OR REPLACE VIEW `v_disponibilidad` AS
SELECT 
  a.idagenda,
  a.fecha,
  DATE_FORMAT(a.fecha, '%d/%m/%Y') AS fecha_formato,
  DATE_FORMAT(b.comienza, '%H:%i') AS hora_inicio,
  DATE_FORMAT(b.termina, '%H:%i') AS hora_fin,
  s.idservicios,
  s.nombre AS servicio,
  pr.idprofesionales,
  CONCAT(p.nombres, ' ', p.apepat, ' ', IFNULL(p.apemat, '')) AS profesional
FROM agenda a
JOIN bloque b ON a.idbloque = b.idbloque
JOIN profesionales pr ON a.idprofesionales = pr.idprofesionales
JOIN personas p ON pr.idpersonas = p.idpersonas
JOIN servicios s ON pr.idservicios = s.idservicios
LEFT JOIN reservas r ON r.idagenda = a.idagenda
WHERE r.idagenda IS NULL
  AND a.disponible = 1
  AND a.fecha >= CURDATE()
ORDER BY a.fecha, b.comienza;
