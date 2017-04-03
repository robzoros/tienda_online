-- *************************************************************
-- PÁGINA DE INICIO
-- *************************************************************
-- Query para obtener productos seleccionados por marketing
SELECT * 
FROM tienda_online.productos_por_marketing
WHERE tag_marketing = 'BLACK FRIDAY'
ORDER BY timestamp_marketing DESC
LIMIT 8;

-- Query para obtener productos más vendidos
SELECT * 
FROM   tienda_online.productos_mas_vendidos
WHERE  semilla = 5;

-- Query para obtener últimos productos añadidos al catálogo
SELECT alta_producto, toTimestamp(codigo_referencia) as fecha_alta, nombre_producto, precio_producto, url_imagen
FROM tienda_online.productos_por_fecha 
WHERE alta_producto ='2017'
LIMIT 8;

-- Queries para obtener el detalle de la última compra
SELECT *
FROM tienda_online.compras 
WHERE usuario_id = 11ebdaac-0709-4a47-b5a7-4ec11f1ea6bf
ORDER BY fecha_compra DESC
LIMIT 1;

SELECT *
FROM tienda_online.pedidos 
WHERE factura = 'BEPNFCESZMVN';

-- Query para obtener 8 productos aleatorios. 
-- Confiamos en que el reparto de PARTITION KEY es suficientemente aleatorio
-- para devolvernos datos.
SELECT *
FROM tienda_online.productos 
LIMIT 8;

-- Query para obtener los últimos productos visitados.
SELECT *
FROM tienda_online.productos_visitados 
WHERE usuario_id = 11ebdaac-0709-4a47-b5a7-4ec11f1ea6bf
ORDER BY fecha_ultima_visita DESC;

-- *************************************************************
-- PÁGINA DE CATEGORIAS
-- *************************************************************

-- QUERIES para obtener los productos de una categoría Ordenado por Nombre (español)
SELECT *
FROM tienda_online.categorias_por_nombre_es 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_es ASC;

SELECT *
FROM tienda_online.categorias_por_nombre_es 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_es DESC;

-- QUERIES para obtener los productos de una categoría Ordenado por Nombre (inglés)
SELECT *
FROM tienda_online.categorias_por_nombre_en 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_en ASC;

SELECT *
FROM tienda_online.categorias_por_nombre_en 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_en DESC;

-- QUERIES para obtener los productos de una categoría Ordenado por Nombre (francés)
SELECT *
FROM tienda_online.categorias_por_nombre_fr
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_fr ASC;

SELECT *
FROM tienda_online.categorias_por_nombre_fr
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY nombre_producto_fr DESC;

-- QUERIES para obtener los productos de una categoría Ordenado por Precio
SELECT *
FROM tienda_online.categorias_por_precio 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY precio_producto ASC;

SELECT *
FROM tienda_online.categorias_por_precio 
WHERE categoria = 3c1859bb-1848-11e7-8b14-0eb188311a1a
ORDER BY precio_producto DESC;

-- *************************************************************
-- PÁGINA DE PRODUCTO
-- *************************************************************

-- QUERY para obtener un producto
SELECT *
FROM tienda_online.productos 
WHERE codigo_referencia = b2d71000-0bf5-11e5-aefa-2761c1c51b4b ;

-- QUERY de productos relacionados
SELECT *
FROM tienda_online.productos_vendidos_juntos
WHERE producto = b2d71000-0bf5-11e5-aefa-2761c1c51b4b 
ORDER BY numero_ventas DESC
LIMIT 8;

-- *************************************************************
-- PÁGINA DE CARRITO
-- *************************************************************
SELECT *
FROM tienda_online.carro
WHERE usuario_id = 11ebdaac-0709-4a47-b5a7-4ec11f1ea6bf;

-- *************************************************************
-- PÁGINA DE RESUMEN DE COMPRA
-- *************************************************************
SELECT *
FROM tienda_online.pedidos
WHERE usuario_id = 11ebdaac-0709-4a47-b5a7-4ec11f1ea6bf
ORDER BY fecha_compra DESC
LIMIT 1;

-- *************************************************************
-- LISTADO DE COMPRAS
-- *************************************************************

-- QUERY para Histórico de pedidos
SELECT *
FROM tienda_online.compras 
WHERE usuario_id = 11ebdaac-0709-4a47-b5a7-4ec11f1ea6bf
ORDER BY fecha_compra DESC
LIMIT 8;

-- QUERY con detalle de una compra
SELECT *
FROM tienda_online.pedidos 
WHERE factura = 'TAAZSQZKFIBH';