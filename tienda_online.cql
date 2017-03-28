DROP KEYSPACE tienda_online;
-- CREAMOS KEYSPACE DE LA APLICACION
CREATE KEYSPACE tienda_online
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

-- *************************************************
-- USUARIOS Y COMPRAS
-- *************************************************
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
-- *************************************************
-- FIN USUARIOS Y COMPRAS
-- *************************************************


-- *************************************************
--  PRODUCTOS
-- *************************************************

-- Tabla de productos. Es la tabla que se consulará en la página de productos. 
-- Para poder crear una vista materializada y mantener el orden de los productos el código de referencia es de tipo TIMEUUID
-- Alta producto es un bucket que se ajusta a la periodicidad de alta de nuevos productos
-- Si se añaden muchos productos diariamente el bucket podría ser un Date. En otros casos el Bucket podría ser semanal o mensual
-- Nombre producto y descripción son un de tipo MAP que tendrán el formato KEY, VALUE en el que KEY será el código de idioma según ISO 639-1
-- y VALUE el producto o la descripción en dicho idioma.
CREATE TABLE tienda_online.productos (
  codigo_referencia TIMEUUID,
  alta_producto TEXT,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  categoria UUID,
  PRIMARY KEY(codigo_referencia)
);

-- Para obtener los últimos productos dados de alta y los productos seleccionados por marketing creamos dos vistas materializadas.
-- Tabla de productos (ordenados por fecha de alta).
CREATE MATERIALIZED VIEW tienda_online.productos_por_fecha AS
  SELECT codigo_referencia, alta_producto, nombre_producto, precio_producto, descripcion, url_imagen 
  FROM tienda_online.productos
  WHERE alta_producto IS NOT NULL AND timestamp_producto IS NOT NULL
  PRIMARY KEY (alta_producto, codigo_referencia)
  WITH CLUSTERING ORDER BY (codigo_referencia DESC);

-- Tag marketing es un bucket que agrupa los productos seleccionados por marketing. 
-- Se supone que existe un Tag de Marketing actual y que es conocido por el sistema.
-- Se usa el tag ya que suponemos que se desea guardar un histórico de los productos seleccionados por marketing
-- Usamos timestamp_marketing ya que suponemos que el tag estará "vivo" durante un tiempo pudiendo
-- tener un número indeterminado de productos.
CREATE TABLE tienda_online.productos_por_marketing (
  codigo_referencia TIMEUUID,
  timestamp_marketing TIMESTAMP,
  tag_marketing TEXT,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  PRIMARY KEY(tag_marketing, timestamp_marketing, codigo_referencia)
) WITH CLUSTERING ORDER BY (timestamp_marketing DESC);


-- En Cassandra, ordenar por valores que no son columnas de cluster es un anti patrón.
-- Para obtener los productos más vendidos propongo llevar un contador de las ventas de cada producto.
-- Un proceso batch que correría cada día, semana, cada 4 horas, según periodicidad acordada con negocio
-- se encargaría de recorrer la tabla con el contador y dejar en otra tabla los N productos más vendidos.

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_productos_vendidos	 (
  codigo_referencia TIMEUUID,
	numero_ventas counter, 
	PRIMARY KEY(codigo_referencia)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos siendo N un número determinado 
-- por negocio, en nuestro caso 8, pero que sería parametrizable)
CREATE TABLE tienda_online.productos_mas_vendidos	 (
  codigo_referencia TIMEUUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
	numero_ventas bigint, 
	PRIMARY KEY(codigo_referencia)
);


-- En el Caso de obtener los productos que más se han vendido junto a un determinado producto sería un caso similar, por ser igualmente un antipatrón
-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_prod_vendidos_juntos	 (
  producto TIMEUUID,
 	producto_rel TIMEUUID,
	numero_ventas counter, 
	PRIMARY KEY(producto, producto_rel)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos junto a cada producto, 
-- siendo N un número determinado por negocio, en nuestro caso 4, pero sería parametrizable)
CREATE TABLE tienda_online.productos_vendidos_juntos	 (
  producto TIMEUUID,
 	producto_rel TIMEUUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
	numero_ventas bigint, 
	PRIMARY KEY(producto, numero_ventas, producto_rel)
) WITH CLUSTERING ORDER BY (numero_ventas DESC);

-- *************************************************
--  FIN PRODUCTOS
-- *************************************************

-- *************************************************
--  CATEGORIAS
-- *************************************************
-- Para ordenar los productos por nombre o precio hay que crear una tabla por cada orden diferente que se quiere.
-- En el caso de tener multiidioma habrá que tener una tabla por cada idioma por el que se quiera ordenar.

-- Tabla con los productos por categoría en el idioma por defecto (español) ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria (
  categoria UUID,
  codigo_referencia TIMEUUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría en inglés ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria_en (
  categoria UUID,
  codigo_referencia TIMEUUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría en francés ordenados por Nombre Producto
CREATE TABLE tienda_online.productos_por_categoria_fr (
  categoria UUID,
  codigo_referencia TIMEUUID,
  nombre_categoria TEXT static,
  nombre_producto TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Tabla con los productos por categoría ordenados por PRECIO
CREATE TABLE tienda_online.productos_por_precio (
  categoria UUID,
  codigo_referencia TIMEUUID,
  nombre_categoria MAP<TEXT, TEXT> static,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, precio_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (precio_producto ASC);

-- *************************************************
--  FIN CATEGORIAS
-- *************************************************
