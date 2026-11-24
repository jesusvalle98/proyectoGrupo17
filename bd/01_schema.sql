-- =====================================================================
-- Sistema de Gestión de Residuos Reciclables
-- 01_schema.sql : creación de tablas, llaves, restricciones e índices
-- Motor: MySQL 8.0.16+ / MariaDB 10.2+ (los CHECK se aplican desde esas versiones)
-- =====================================================================

DROP DATABASE IF EXISTS reciclaje;
CREATE DATABASE reciclaje CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE reciclaje;

-- ---------------------------------------------------------------------
-- Tablas independientes (no dependen de otras)
-- ---------------------------------------------------------------------

CREATE TABLE punto_acopio (
    id_punto   INT AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(100) NOT NULL,
    direccion  VARCHAR(200) NOT NULL,
    CONSTRAINT uq_punto_nombre UNIQUE (nombre)
);

CREATE TABLE tipo_material (
    id_tipo  INT AUTO_INCREMENT PRIMARY KEY,
    nombre   VARCHAR(50) NOT NULL,
    CONSTRAINT uq_tipo_nombre UNIQUE (nombre)
);

CREATE TABLE usuario (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    email          VARCHAR(120) NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    rol            VARCHAR(20)  NOT NULL DEFAULT 'operador',
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('admin', 'operador'))
);

-- ---------------------------------------------------------------------
-- Tablas dependientes
-- ---------------------------------------------------------------------

CREATE TABLE retiro (
    id_retiro     INT AUTO_INCREMENT PRIMARY KEY,
    fecha_retiro  DATE         NOT NULL,
    destino       VARCHAR(150) NOT NULL,
    id_usuario    INT          NOT NULL,
    CONSTRAINT fk_retiro_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE entrega (
    id_entrega   INT AUTO_INCREMENT PRIMARY KEY,
    fecha        DATE          NOT NULL,
    responsable  VARCHAR(100)  NOT NULL,
    peso_kg      DECIMAL(10,2) NOT NULL,
    estado       VARCHAR(20)   NOT NULL DEFAULT 'almacenado',
    id_punto     INT           NOT NULL,
    id_tipo      INT           NOT NULL,
    id_retiro    INT           NULL,      -- NULL mientras no haya sido retirada
    id_usuario   INT           NOT NULL,  -- usuario que registró la entrega

    CONSTRAINT ck_entrega_peso   CHECK (peso_kg > 0),
    CONSTRAINT ck_entrega_estado CHECK (estado IN ('almacenado', 'retirado')),
    -- Coherencia estado <-> retiro: retirado exige id_retiro; almacenado lo prohíbe
    CONSTRAINT ck_entrega_estado_retiro CHECK (
        (estado = 'almacenado' AND id_retiro IS NULL) OR
        (estado = 'retirado'   AND id_retiro IS NOT NULL)
    ),

    CONSTRAINT fk_entrega_punto
        FOREIGN KEY (id_punto)   REFERENCES punto_acopio (id_punto)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_tipo
        FOREIGN KEY (id_tipo)    REFERENCES tipo_material (id_tipo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- ON UPDATE RESTRICT (y no CASCADE): id_retiro se usa en un CHECK y
    -- MySQL/MariaDB no permiten acciones referenciales CASCADE/SET NULL en ese caso
    CONSTRAINT fk_entrega_retiro
        FOREIGN KEY (id_retiro)  REFERENCES retiro (id_retiro)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_entrega_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- Índices para las consultas de filtro, agrupación y reportes por fecha
-- (las FK ya generan índice en MySQL; estos cubren fecha y estado)
-- ---------------------------------------------------------------------

CREATE INDEX idx_entrega_fecha  ON entrega (fecha);
CREATE INDEX idx_entrega_estado ON entrega (estado);
CREATE INDEX idx_retiro_fecha   ON retiro (fecha_retiro);
