#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from cassandra.query import (BatchStatement, BatchType)
from cassandra.cluster import Cluster

# Conectamos al Cluster
cluster = Cluster()
session = cluster.connect('tienda_online')

#******************************************************
#          CONTADORES
#******************************************************
# Cargamos la lista de productos en una lista
session.execute("TRUNCATE productos_mas_vendidos")
session.execute("TRUNCATE productos_vendidos_juntos")

productos_vendidos = session.execute('SELECT * FROM productos_vendidos ORDER BY numero_ventas DESC')
for producto in productos_vendidos:
    prod = session.execute('SELECT * FROM productos WHERE codigo_referencia = ' + str(producto.codigo_referencia))[0]
    prepared = session.prepare("INSERT INTO productos_mas_vendidos (codigo_referencia, nombre_producto, precio_producto, descripcion, url_imagen, numero_ventas)" +
		                         " VALUES (?, ?, " + "{:0.2f}".format(prod.precio_producto) + " ?, ?, ?)")
    session.execute(prepared, (prod.codigo_referencia, prod.nombre_producto, prod.descripcion, prod.url_imagen, producto.numero_ventas))


productos = session.execute('SELECT * FROM productos')

for producto in productos:
    productos_rel = session.execute('SELECT * FROM contador_prod_vendidos_juntos WHERE producto = ' + str(producto.codigo_referencia) + " ORDER BY numero_ventas")
    for prod in productos_rel:
        prod_rel = session.execute('SELECT * FROM productos WHERE codigo_referencia = ' + str(prod.producto_rel))[0]

        prepared = session.prepare("INSERT INTO productos_vendidos_juntos (producto, producto_rel, nombre_producto, precio_producto, descripcion, url_imagen, numero_ventas)" +
    		                         " VALUES (?, ?, ? " + "{:0.2f}".format(producto.precio_producto) + "?, ?, ?)")
    	session.execute(prepared, (producto.codigo_referencia, prod_rel.codigo_referencia, prod_rel.nombre_producto, prod_rel.descripcion, prod_rel.url_imagen, prod.numero_ventas))

    
