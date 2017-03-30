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
  precio_producto DECIMAL,
  url_imagen TEXT,
  cantidad INT,
  importe DECIMAL static,
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
  precio_producto DECIMAL,
  url_imagen TEXT,
  cantidad INT,
  importe DECIMAL static,
  PRIMARY KEY(factura, codigo_referencia)
);
-- *************************************************
-- FIN USUARIOS Y COMPRAS
-- *************************************************


-- *************************************************
--  PRODUCTOS
-- *************************************************

-- Tabla de productos. Es la tabla que se consulará en la página de productos. 
-- Para mantener el orden de los productos por fecha de alta el código de 
-- referencia del producto es de tipo TIMEUUID
-- Alta producto es un bucket que se ajusta a la periodicidad de alta de nuevos productos
-- Si se añaden muchos productos diariamente el bucket podría ser un Date. En otros casos
-- el Bucket podría ser semanal o mensual
-- Nombre producto y descripción son un de tipo MAP que tendrán el formato KEY, VALUE en el
-- que KEY será el código de idioma según ISO 639-1 y VALUE el producto o la descripción en dicho idioma.
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

-- Para obtener los últimos productos dados de alta creamos una vista materializada.
-- Tabla de productos (ordenados por fecha de alta).
CREATE MATERIALIZED VIEW tienda_online.productos_por_fecha AS
  SELECT codigo_referencia, alta_producto, nombre_producto, precio_producto, url_imagen 
  FROM tienda_online.productos
  WHERE alta_producto IS NOT NULL
  PRIMARY KEY (alta_producto, codigo_referencia)
  WITH CLUSTERING ORDER BY (codigo_referencia DESC);

-- Tag marketing es un bucket que agrupa los productos seleccionados por marketing. 
-- Se supone que existe un Tag de Marketing actual y que es conocido por el sistema.
-- Se usa el tag ya que suponemos que se desea guardar un histórico de los productos
-- seleccionados por marketing.
-- Usamos timestamp_marketing ya que suponemos que el tag estará "vivo" durante un 
-- tiempo pudiendo tener un número indeterminado de productos.
CREATE TABLE tienda_online.productos_por_marketing (
  codigo_referencia TIMEUUID,
  timestamp_marketing TIMESTAMP,
  tag_marketing TEXT,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(tag_marketing, timestamp_marketing, codigo_referencia)
) WITH CLUSTERING ORDER BY (timestamp_marketing DESC);


-- En Cassandra, ordenar por valores que no son columnas de cluster es un anti patrón.
-- Para obtener los productos más vendidos propongo llevar un contador de las ventas 
-- de cada producto.
-- Un proceso batch que correría cada día, semana, cada 4 horas, según periodicidad a
-- cordada con negocio se encargaría de recorrer la tabla con el contador y dejar en 
-- otra tabla los N productos más vendidos.

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_productos_vendidos	 (
  codigo_referencia TIMEUUID,
	numero_ventas counter, 
	PRIMARY KEY(codigo_referencia)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos 
-- siendo N un número determinado por negocio, en nuestro caso 8, pero que sería parametrizable)
CREATE TABLE tienda_online.productos_mas_vendidos	 (
  codigo_referencia TIMEUUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  url_imagen TEXT,
	numero_ventas bigint, 
	PRIMARY KEY(codigo_referencia)
);

-- En el Caso de obtener los productos que más se han vendido junto a un determinado 
-- producto sería un caso similar, por ser igualmente un antipatrón

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_prod_vendidos_juntos	 (
  producto TIMEUUID,
 	producto_rel TIMEUUID,
	numero_ventas counter, 
	PRIMARY KEY(producto, producto_rel)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos
-- junto a cada producto, siendo N un número determinado por negocio, en nuestro 
-- caso 4, pero sería parametrizable)
CREATE TABLE tienda_online.productos_vendidos_juntos	 (
  producto TIMEUUID,
 	producto_rel TIMEUUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
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
-- Para ordenar los productos por nombre o precio hay que crear una vista
-- materializada por cada consulta diferente que se necesite.
-- Las consultas que se quieren hacer son por precio y por nombre producto 
-- por lo que serán necesarias dos vistas.
-- Como además tenemos multiidioma habrá que tener una vista por cada idioma 
-- por el que se quiera ordenar.
-- El nombre de categoría y de precio se desglosarán en una columna por cada 
-- idioma y además existirá una vista materializada para cada idioma.
-- Añadir un idioma supone ALTER TABLE de la tabla categorías y creación de 
-- una nueva vista materializada.
-- En esta solución suponemos además que el nombre del producto estará siempre
-- dado de alta en todos los idiomas.

-- Tabla con los productos por categoría. Las consultas que el caso propone
-- son ordenadas por nombre o por precio por lo que en principio esta
-- tabla sería redundante. Sin embargo considero que es la mejor candidata 
-- para tabla "madre" de las vistas materializadas proporcionando además
-- la posibilidad de una consulta ordenada por fecha de alta del producto 
-- por si fuera necesaria en el futuro.
-- Los campos con el nombre de la categoría podrían ser static. Sin embargo 
-- tenemos la limitación de que no podríamos replicarlos en las vistas materializadas,
CREATE TABLE tienda_online.categorias (
  categoria UUID,
  codigo_referencia TIMEUUID,
  nombre_categoria_es TEXT,
  nombre_categoria_en TEXT,
  nombre_categoria_fr TEXT,
  nombre_producto_es TEXT,
  nombre_producto_en TEXT,
  nombre_producto_fr TEXT,
  precio_producto DECIMAL,
  url_imagen TEXT,
  PRIMARY KEY(categoria, codigo_referencia));

-- Tabla con los productos por categoría en español ordenados por Nombre Producto
-- Notese que ne las vistas materializadas no es necesario poner las columnas
-- que son primary key en la tabla original.
CREATE MATERIALIZED VIEW tienda_online.categorias_por_nombre_es AS
  SELECT nombre_categoria_es, nombre_producto_es, precio_producto, url_imagen 
  FROM tienda_online.categorias
  WHERE nombre_producto_es IS NOT NULL AND codigo_referencia IS NOT NULL
  PRIMARY KEY (categoria, nombre_producto_es, codigo_referencia)
  WITH CLUSTERING ORDER BY (nombre_producto_es ASC);

-- Tabla con los productos por categoría en inglés ordenados por Nombre Producto
CREATE MATERIALIZED VIEW tienda_online.categorias_por_nombre_en AS
  SELECT nombre_categoria_en, nombre_producto_en, precio_producto, url_imagen 
  FROM tienda_online.categorias
  WHERE nombre_producto_en IS NOT NULL AND codigo_referencia IS NOT NULL
  PRIMARY KEY (categoria, nombre_producto_en, codigo_referencia)
  WITH CLUSTERING ORDER BY (nombre_producto_en ASC);

-- Tabla con los productos por categoría en francés ordenados por Nombre Producto
CREATE MATERIALIZED VIEW tienda_online.categorias_por_nombre_fr AS
  SELECT nombre_categoria_fr, nombre_producto_fr, precio_producto, url_imagen 
  FROM tienda_online.categorias
  WHERE nombre_producto_fr IS NOT NULL AND codigo_referencia IS NOT NULL
  PRIMARY KEY (categoria, nombre_producto_fr, codigo_referencia)
  WITH CLUSTERING ORDER BY (nombre_producto_fr ASC);

-- Tabla con los productos por categoría ordenados por prexio
CREATE MATERIALIZED VIEW tienda_online.categorias_por_precio AS
  SELECT nombre_categoria_es, nombre_categoria_en, nombre_categoria_fr, 
         nombre_producto_es, nombre_producto_en, nombre_producto_fr, precio_producto, url_imagen 
  FROM tienda_online.categorias
  WHERE precio_producto IS NOT NULL AND codigo_referencia IS NOT NULL
  PRIMARY KEY (categoria, precio_producto, codigo_referencia)
  WITH CLUSTERING ORDER BY (precio_producto ASC);


-- *************************************************
--  FIN CATEGORIAS
-- *************************************************
