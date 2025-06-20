-- Crear rol y base de datos para Keycloak
CREATE ROLE keycloak LOGIN PASSWORD 'kcsecret';
CREATE DATABASE keycloak OWNER keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;







DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS procedure CASCADE;

DROP SEQUENCE IF EXISTS employee_seq;
DROP SEQUENCE IF EXISTS person_seq;
DROP SEQUENCE IF EXISTS procedure_seq;

-- Crear secuencias
CREATE SEQUENCE public.person_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE CACHE 1;

CREATE SEQUENCE public.employee_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE CACHE 1;

CREATE SEQUENCE public.procedure_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE CACHE 1;

-- Tabla de personas (empleados y terceros)
CREATE TABLE person
(
    id                BIGINT DEFAULT nextval('public.person_seq'::regclass),
    id_type           VARCHAR(10) NOT NULL,
    id_number         VARCHAR(20) NOT NULL UNIQUE,
    first_name        VARCHAR(50) NOT NULL,
    last_name         VARCHAR(50) NOT NULL,
    phone             VARCHAR(20),
    address           VARCHAR(100),
    email             VARCHAR(100),
    created_at        TIMESTAMP DEFAULT now(),
    updated_at        TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
);

COMMENT ON COLUMN person.id IS 'Primary key of the person table';
COMMENT ON COLUMN person.id_type IS 'Identification type (e.g., CC, TI, CE)';
COMMENT ON COLUMN person.id_number IS 'Identification number';
COMMENT ON COLUMN person.first_name IS 'First name';
COMMENT ON COLUMN person.last_name IS 'Last name';
COMMENT ON COLUMN person.email IS 'Email address';

-- Tabla de empleados
CREATE TABLE employee
(
    id                BIGINT DEFAULT nextval('public.employee_seq'::regclass),
    person_id         BIGINT NOT NULL,
    department        VARCHAR(100) NOT NULL,
    hire_date         DATE NOT NULL,
    created_at        TIMESTAMP DEFAULT now(),
    updated_at        TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (person_id) REFERENCES person (id)
);

COMMENT ON COLUMN employee.id IS 'Primary key of the employee table';
COMMENT ON COLUMN employee.person_id IS 'Foreign key to person';
COMMENT ON COLUMN employee.department IS 'Department where the employee works';
COMMENT ON COLUMN employee.hire_date IS 'Date of hire';

-- Tabla de trámites
CREATE TABLE procedure
(
    id                  BIGINT DEFAULT nextval('public.procedure_seq'::regclass),
    registration_number VARCHAR(20) NOT NULL,
    registration_year   INT NOT NULL,
    name                VARCHAR(100) NOT NULL,
    description         TEXT,
    submitted_by_id     BIGINT NOT NULL,
    received_by_id      BIGINT NOT NULL,
    created_at          TIMESTAMP DEFAULT now(),
    updated_at          TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (submitted_by_id) REFERENCES person (id),
    FOREIGN KEY (received_by_id) REFERENCES employee (id)
);

COMMENT ON COLUMN procedure.id IS 'Primary key of the procedure table';
COMMENT ON COLUMN procedure.registration_number IS 'Unique registration number';
COMMENT ON COLUMN procedure.registration_year IS 'Year of registration';
COMMENT ON COLUMN procedure.name IS 'Name of the procedure';
COMMENT ON COLUMN procedure.description IS 'Description of the procedure';
COMMENT ON COLUMN procedure.submitted_by_id IS 'Person who submitted the procedure';
COMMENT ON COLUMN procedure.received_by_id IS 'Employee who received the procedure';




DROP TABLE IF EXISTS document_type CASCADE;
DROP SEQUENCE IF EXISTS document_type_seq;


CREATE SEQUENCE public.document_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE CACHE 1;


CREATE TABLE document_type
(
    id          BIGINT DEFAULT nextval('public.document_type_seq'::regclass),
    code        VARCHAR(5) NOT NULL UNIQUE,
    description VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);


INSERT INTO document_type (code, description) VALUES ('CC', 'Cédula de ciudadanía');
INSERT INTO document_type (code, description) VALUES ('TI', 'Tarjeta de identidad');
INSERT INTO document_type (code, description) VALUES ('CE', 'Cédula de extranjería');
INSERT INTO document_type (code, description) VALUES ('PA', 'Pasaporte');
INSERT INTO document_type (code, description) VALUES ('NIT', 'Número de Identificación Tributaria');


ALTER TABLE person DROP COLUMN id_type;

ALTER TABLE person ADD COLUMN document_type_id BIGINT NOT NULL;

ALTER TABLE person ADD CONSTRAINT fk_person_document_type
    FOREIGN KEY (document_type_id) REFERENCES document_type (id);


COMMENT ON COLUMN person.document_type_id IS 'Foreign key to the document_type table';
