DROP KEYSPACE tienda_online;
-- CREAMOS KEYSPACE DE LA APLICACION
CREATE KEYSPACE tienda_online
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

-- Datos de usuarios
CREATE TABLE tienda_online.usuarios (
  usuario_id UUID PRIMARY KEY,
  nombre TEXT,
  apellidos TEXT,
  direccion TEXT
);

-- Últimos productos visitados por un usuario
CREATE TABLE tienda_online.productos_visitados (
  usuario_id UUID,
  codigo_referencia UUID,
  fecha_ultima_visita TIMESTAMP,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(usuario_id, fecha_ultima_visita, codigo_referencia)
);

-- carro de un usuario, al pasarlo a compras se deberá borrar
CREATE TABLE tienda_online.carro (
  usuario_id  UUID,
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  cantidad INT,
  precio_producto DECIMAL,
  importe DECIMAL static,
  url_imagen TEXT,
  PRIMARY KEY(usuario_id, codigo_referencia)
);

-- Listado de compras
CREATE TABLE tienda_online.compras (
  usuario_id  UUID,
  factura TEXT,
  fecha_compra TIMESTAMP,
  importe DECIMAL,
  PRIMARY KEY(usuario_id, fecha_compra, factura)
) WITH CLUSTERING ORDER BY (fecha_compra DESC);

-- Listado de compras detalle
CREATE TABLE tienda_online.compras_detalle (
  usuario_id  UUID STATIC,
  factura TEXT,
  fecha_compra TIMESTAMP,
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  cantidad INT,
  precio_producto DECIMAL,
  importe DECIMAL static,
  url_imagen TEXT,
  PRIMARY KEY(factura, codigo_referencia)
);

-- Tabla de productos. Es la tabla que se consulará en la página de productos.
CREATE TABLE tienda_online.productos (
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  categoria UUID,
  PRIMARY KEY(codigo_referencia)
);

-- Tabla de productos (ordenados por fecha de alta). Alta producto es un bucket que se ajusta a la periodicidad de alta de nuevos productos
-- Si se añaden muchos productos diariamente el bucket podría ser un Date. En otros casos el Bucket podría ser semanal o mensual
CREATE TABLE tienda_online.productos_por_fecha (
  codigo_referencia UUID,
  timestamp_producto TIMESTAMP,
  alta_producto TEXT,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  PRIMARY KEY(alta_producto, timestamp_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (timestamp_producto DESC);

-- Tabla de productos seleccionados por marketing (ordenados por fecha). Alta marketing es un bucket que se ajusta a la periodicidad 
-- de alta de nuevos productos seleccionados por Marketing.
-- Si se añaden muchos productos diariamente el bucket podría ser un Date. En otros casos el Bucket podría ser semanal o mensual
CREATE TABLE tienda_online.productos_por_marketing (
  codigo_referencia UUID,
  timestamp_marketing TIMESTAMP,
  alta_marketing TEXT,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  PRIMARY KEY(alta_marketing, timestamp_marketing, codigo_referencia)
) WITH CLUSTERING ORDER BY (timestamp_marketing DESC);


-- Tabla de productos ordenados por número de ventas. Se utiliza un bucket de ventas por miles para distribuir los registros
CREATE TABLE tienda_online.productos_por_ventas (
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  ventas_en_miles INT,
  numero_ventas INT,
  url_imagen TEXT,
  PRIMARY KEY(ventas_en_miles, numero_ventas, codigo_referencia)
) WITH CLUSTERING ORDER BY (numero_ventas DESC);

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.productos_relacionados	 (
  producto UUID,
 	producto_rel UUID,
	numero_compras counter, 
	PRIMARY KEY(producto, producto_rel)
);


-- Tabla con los productos por categoría en el idioma por defecto (español) ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria (
  categoria UUID,
  codigo_referencia UUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría en inglés ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria_en (
  categoria UUID,
  codigo_referencia UUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría en francés ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria_fr (
  categoria UUID,
  codigo_referencia UUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría ordenados por PRECIO
CREATE TABLE tienda_online.productos_por_precio (
  categoria UUID,
  codigo_referencia UUID,
  nombre_categoria MAP<TEXT, TEXT> static,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, precio_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (precio_producto ASC);