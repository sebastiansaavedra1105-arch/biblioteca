-- Crear tablas para la biblioteca

-- Tabla de usuarios
CREATE TABLE usuarios (
  id BIGSERIAL PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  nombre TEXT NOT NULL,
  rol TEXT NOT NULL DEFAULT 'user'
);

-- Tabla de libros
CREATE TABLE libros (
  id BIGSERIAL PRIMARY KEY,
  codigo_barras TEXT UNIQUE NOT NULL,
  titulo TEXT NOT NULL,
  autor TEXT NOT NULL,
  isbn TEXT NOT NULL,
  anio INTEGER NOT NULL,
  editorial TEXT NOT NULL,
  categoria TEXT NOT NULL,
  copias INTEGER NOT NULL DEFAULT 1,
  copias_disponibles INTEGER NOT NULL DEFAULT 1,
  estado TEXT NOT NULL DEFAULT 'bueno',
  observacion TEXT,
  foto_bytes BYTEA
);

-- Tabla de prestamos
CREATE TABLE prestamos (
  id BIGSERIAL PRIMARY KEY,
  libro_id BIGINT NOT NULL REFERENCES libros(id) ON DELETE CASCADE,
  libro_titulo TEXT NOT NULL,
  codigo_alumno TEXT NOT NULL,
  nombre_alumno TEXT NOT NULL,
  fecha_prestamo TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  fecha_entrega TIMESTAMPTZ NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Usuario admin por defecto (password: 1234)
INSERT INTO usuarios (username, password, nombre, rol)
VALUES ('admin', '1234', 'Administrador Principal', 'admin');

-- Habilitar RLS pero con políticas abiertas (para desarrollo)
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE libros ENABLE ROW LEVEL SECURITY;
ALTER TABLE prestamos ENABLE ROW LEVEL SECURITY;

-- Políticas para desarrollo (permisivas)
CREATE POLICY "Allow all for anon" ON usuarios FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON libros FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON prestamos FOR ALL USING (true);
