DROP KEYSPACE tienda_online;
-- CREAMOS KEYSPACE DE LA APLICACION
CREATE KEYSPACE tienda_online
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };


-- *************************************************
-- FUNCIONES
-- *************************************************
-- Funcíón para obtener Término en idioma. Suponemos que el idioma por defecto será el inglés
CREATE OR REPLACE FUNCTION tienda_online.getTranslation (dic map<text, text>, idioma text) 
  RETURNS NULL ON NULL INPUT
  RETURNS text LANGUAGE java 
  AS '
    if(dic.containsKey(idioma)) {
      return (String)dic.get(idioma); 
    } else if (dic.containsKey("en")) {
      return (String)dic.get("en"); 
    }
    else {
      return null;
    }';

-- Function para obtener Multiidioma. Suponemos que el idioma por defecto será el inglés
CREATE OR REPLACE FUNCTION tienda_online.getTranslationEn (dic map<text, text>) 
  RETURNS NULL ON NULL INPUT
  RETURNS text LANGUAGE java 
  AS '
    if(dic.containsKey("en")) {
      return (String)dic.get("en"); 
    } else {
      return null;
    }';

CREATE OR REPLACE FUNCTION tienda_online.getTranslationEs (dic map<text, text>) 
  RETURNS NULL ON NULL INPUT
  RETURNS text LANGUAGE java 
  AS '
    if(dic.containsKey("es")) {
      return (String)dic.get("es"); 
    } else if (dic.containsKey("en")) {
      return (String)dic.get("en"); 
    }
    else {
      return null;
    }';

CREATE OR REPLACE FUNCTION tienda_online.getTranslationFr (dic map<text, text>) 
  RETURNS NULL ON NULL INPUT
  RETURNS text LANGUAGE java 
  AS '
    if(dic.containsKey("fr")) {
      return (String)dic.get("fr"); 
    } else if (dic.containsKey("en")) {
      return (String)dic.get("en"); 
    }
    else {
      return null;
    }';
    

  BODY
    
  END BODY;
-- *************************************************
-- FIN FUNCIONES
-- *************************************************

-- *************************************************
-- USUARIOS Y COMPRAS
-- *************************************************
-- Datos de usuario
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
) WITH CLUSTERING ORDER BY (fecha_ultima_visita DESC);;

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

-- Tabla de productos. Es la tabla que se consultará en la página de productos.
-- Alta producto es un bucket que se ajusta a la periodicidad de alta de nuevos productos
-- Si se añaden muchos productos diariamente el bucket podría ser un Date. En otros casos el Bucket podría ser semanal o mensual
-- Tag marketing es un bucket que agrupa los productos seleccionados por marketing. 
-- Se supone que existe un Tag de Marketing actual y que es conocido por el sistema.
CREATE TABLE tienda_online.productos (
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  alta_producto TEXT,
  timestamp_producto TIMESTAMP,
  timestamp_marketing TIMESTAMP,
  tag_marketing TEXT,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
  categoria UUID,
  nombre_categoria MAP<TEXT, TEXT>,
  PRIMARY KEY(codigo_referencia)
);

-- Para obtener los últimos productos dados de alta y los productos seleccionados por marketing creamos dos vistas materializadas.
-- Tabla de productos (ordenados por fecha de alta).
CREATE MATERIALIZED VIEW tienda_online.productos_por_fecha AS
  SELECT codigo_referencia, timestamp_producto, alta_producto, nombre_producto, precio_producto, descripcion, url_imagen 
  FROM tienda_online.productos
  WHERE alta_producto IS NOT NULL AND timestamp_producto IS NOT NULL
  PRIMARY KEY (alta_producto, timestamp_producto, codigo_referencia)
  WITH CLUSTERING ORDER BY (timestamp_producto DESC);

-- Tabla de productos seleccionados por marketing (ordenados por fecha). 
CREATE MATERIALIZED VIEW tienda_online.productos_por_fecha AS
  SELECT codigo_referencia, timestamp_marketing, tag_marketing, nombre_producto, precio_producto, descripcion, url_imagen 
  FROM tienda_online.productos
  WHERE alta_producto IS NOT NULL AND timestamp_producto IS NOT NULL
  PRIMARY KEY(tag_marketing, timestamp_marketing, codigo_referencia)
  WITH CLUSTERING ORDER BY (timestamp_producto DESC);

-- En Cassandra, ordenar por valores que no son parte de la clave es un anti patrón.
-- Para obtener los productos más vendidos propongo llevar un contador de las ventas de cada producto.
-- Un proceso batch que correría cada día, semana, cada 4 horas etc se encargaría de recorrer la tabla con el contador y dejar en otra tabla 
-- los ocho productos más vendidos.

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_productos_vendidos	 (
  codigo_referencia UUID,
	numero_ventas counter, 
	PRIMARY KEY(codigo_referencia)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos siendo N un número determinado por negocio
-- , en nuestro caso 8, pero sería parametrizable)
CREATE TABLE tienda_online.productos_mas_vendidos	 (
  codigo_referencia UUID,
  nombre_producto MAP<TEXT, TEXT>,
  precio_producto DECIMAL,
  descripcion MAP<TEXT, TEXT>,
  url_imagen TEXT,
	numero_ventas bigint, 
	PRIMARY KEY(codigo_referencia)
);

-- En el Caso de los productos más vendidos en conjunto con otro sería similar, por ser igualmente un antipatrón

-- Tabla con los productos que se compran juntos
CREATE TABLE tienda_online.contador_prod_vendidos_juntos	 (
  producto UUID,
 	producto_rel UUID,
	numero_ventas counter, 
	PRIMARY KEY(producto, producto_rel)
);

-- Tabla con los productos más vendidos (sólo tendría los N productos más vendidos de cada producto, 
-- siendo N un número determinado por negocio, en nuestro caso 4, pero sería parametrizable)
CREATE TABLE tienda_online.productos_vendidos_juntos	 (
  producto UUID,
 	producto_rel UUID,
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
-- Para la consulta de productos, igualmente utilizaremos vistas materializadas

-- Vista con los productos por categoría en el idioma por defecto (inglés) ordenados por Nombre Producto
CREATE MATERIALIZED VIEW tienda_online.productos_por_categoria AS
  SELECT categoria, codigo_referencia, getTranslationEn(nombre_categoria) nombre_categoria, 
         getTranslationEn(nombre_producto) as nombre_producto, precio_producto, url_imagen 
  FROM tienda_online.productos
  WHERE nombre_categoria IS NOT NULL AND categoria IS NOT NULL AND nombre_producto IS NOT NULL
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);
  
-- Vista con los productos por categoría en inglés ordenados por Nombre Producto
CREATE MATERIALIZED VIEW tienda_online.productos_por_categoria_es AS
  SELECT categoria, codigo_referencia, getTranslationEs(nombre_categoria) nombre_categoria, 
         getTranslationEs(nombre_producto) as nombre_producto, precio_producto, url_imagen 
  FROM tienda_online.productos
  WHERE nombre_categoria IS NOT NULL AND categoria IS NOT NULL AND nombre_producto IS NOT NULL
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Vista con los productos por categoría en francés ordenados por Nombre Producto
CREATE MATERIALIZED VIEW tienda_online.productos_por_categoria_fr AS
  SELECT categoria, codigo_referencia, getTranslationFr(nombre_categoria) nombre_categoria, 
         getTranslationFr(nombre_producto) as nombre_producto, precio_producto, url_imagen 
  FROM tienda_online.productos
  WHERE nombre_categoria IS NOT NULL AND categoria IS NOT NULL AND nombre_producto IS NOT NULL
  PRIMARY KEY(categoria, nombre_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (nombre_producto ASC);

-- Vista con los productos por categoría ordenados por PRECIO
CREATE MATERIALIZED VIEW tienda_online.productos_por_precio AS
  SELECT categoria, codigo_referencia, nombre_categoria, nombre_producto, precio_producto, url_imagen 
  FROM tienda_online.productos
  WHERE nombre_categoria IS NOT NULL AND categoria IS NOT NULL AND nombre_producto IS NOT NULL
  PRIMARY KEY(categoria, precio_producto, codigo_referencia)
) WITH CLUSTERING ORDER BY (precio_producto ASC);

-- *************************************************
--  FIN CATEGORIAS
-- *************************************************
