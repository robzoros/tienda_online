#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from utiles import (random_date, start, end)
import random
from uuid import uuid1
from string import (ascii_lowercase, ascii_uppercase)
from cassandra.query import (BatchStatement, BatchType)
from cassandra.cluster import Cluster
from cassandra.util import uuid_from_time

# Conectamos al Cluster
cluster = Cluster()
session = cluster.connect('tienda_online')

#******************************************************
#          ALTA DE PRODUCTOS
#******************************************************

# Creamos categorías
categorias = []
for cat in ['Media', 'Aparatos', 'Smartphones', 'Libros', 'Ropa', 'Juegos', 'Juguetes', 'Muebles']:
	cat_en = cat[0] + ''.join(random.choice(cat[1::]) for _ in range(random.randint(0, len(cat) - 1)))
	cat_fr = cat[0] + ''.join(random.choice(cat[1::]) for _ in range(random.randint(0, len(cat) - 1)))
	categorias.append((uuid1(), cat, cat_en, cat_fr))


session.execute("TRUNCATE productos")
session.execute("TRUNCATE productos_por_marketing")
session.execute("TRUNCATE productos_por_categoria")
session.execute("TRUNCATE productos_por_categoria_en")
session.execute("TRUNCATE productos_por_categoria_fr")
session.execute("TRUNCATE productos_por_precio")

# Cargamos tabla de productos
for i in range(100):
	# Damos valor a las columnas de las diferentes tablas
	nombre_producto_es = random.choice(ascii_uppercase) + ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(5, 12)))
	nombre_producto_en = random.choice(ascii_uppercase) + ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(5, 12)))
	nombre_producto_fr = random.choice(ascii_uppercase) + ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(5, 12)))
	nombre_producto = {'es': nombre_producto_es, 'en': nombre_producto_en, 'fr': nombre_producto_fr }
	precio_producto = round(random.uniform(9.8, 45.9), 2)
	descripcion = {'es': nombre_producto_es, 'en': nombre_producto_en, 'fr': nombre_producto_fr }
	url_imagen = ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(5, 12))) + ".jpg" 

	categoria_tupla = random.choice(categorias)
	categoria = categoria_tupla[0]
	nombre_categoria_es = categoria_tupla[1]
	nombre_categoria_en = categoria_tupla[2]
	nombre_categoria_fr = categoria_tupla[3]
	nombre_categoria = {'es': nombre_categoria_es, 'en': nombre_categoria_en, 'fr': nombre_categoria_fr }

	timestamp_producto = random_date(start, end)
	alta_producto = timestamp_producto.strftime("%Y")
	codigo_referencia = uuid_from_time(timestamp_producto)

	timestamp_marketing = random_date(start, end)
	tag_marketing = ''.join(random.choice(ascii_uppercase) for _ in range(10))

	ventas_en_miles = random.randint(0, 15)
	numero_ventas = ventas_en_miles * 1000 + random.randint(0, 999)

	batch = BatchStatement(BatchType.LOGGED)
	prepared = session.prepare("INSERT INTO productos (codigo_referencia, nombre_producto, alta_producto, precio_producto, descripcion, url_imagen, categoria)" +
		                         " VALUES (?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?, ?, ?)")
	batch.add(prepared, (codigo_referencia, nombre_producto, alta_producto, descripcion, url_imagen, categoria))
	prepared = session.prepare("INSERT INTO productos_por_marketing " + 
														 "(codigo_referencia, timestamp_marketing, tag_marketing, nombre_producto, " + 
		                         " precio_producto, descripcion, url_imagen) VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?, ?)")
	batch.add(prepared, (codigo_referencia, timestamp_marketing, tag_marketing, nombre_producto, descripcion, url_imagen))
	prepared = session.prepare("INSERT INTO productos_por_ventas " + 
														 "(codigo_referencia, ventas_en_miles, numero_ventas, nombre_producto, " + 
		                         " precio_producto, descripcion, url_imagen) VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?, ?)")
	batch.add(prepared, (codigo_referencia, ventas_en_miles, numero_ventas, nombre_producto, descripcion, url_imagen))

	prepared = session.prepare("INSERT INTO productos_por_categoria (categoria, codigo_referencia, nombre_categoria, nombre_producto, precio_producto, url_imagen)" +
		                         " VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?)")
	batch.add(prepared, (categoria, codigo_referencia, nombre_categoria_es, nombre_producto_es, url_imagen))
	prepared = session.prepare("INSERT INTO productos_por_categoria_en (categoria, codigo_referencia, nombre_categoria, nombre_producto, precio_producto, url_imagen)" +
		                         " VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?)")
	batch.add(prepared, (categoria, codigo_referencia, nombre_categoria_en, nombre_producto_en, url_imagen))
	prepared = session.prepare("INSERT INTO productos_por_categoria_fr (categoria, codigo_referencia, nombre_categoria, nombre_producto, precio_producto, url_imagen)" +
		                         " VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?)")
	batch.add(prepared, (categoria, codigo_referencia, nombre_categoria_fr, nombre_producto_fr, url_imagen))

	prepared = session.prepare("INSERT INTO productos_por_precio (categoria, codigo_referencia, nombre_categoria, nombre_producto, precio_producto, url_imagen)" +
		                         " VALUES (?, ?, ?, ?, " + "{:0.2f}".format(precio_producto) + ", ?)")
	batch.add(prepared, (categoria, codigo_referencia, nombre_categoria, nombre_producto, url_imagen))

	session.execute(batch)

#******************************************************
#          ALTA DE PRODUCTOS
#******************************************************
