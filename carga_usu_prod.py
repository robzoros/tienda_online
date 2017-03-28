#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from utiles import (random_date, start, end)
import random
from string import (ascii_lowercase, ascii_uppercase)
from uuid import uuid1
from cassandra.query import (BatchStatement, BatchType)
from cassandra.cluster import Cluster

# Conectamos al Cluster
cluster = Cluster()
session = cluster.connect('tienda_online')

#******************************************************
#          PRODUCTOS POR USUARIO
#******************************************************
# Cargamos la lista de productos en una lista
productos = session.execute('SELECT * FROM productos')
lista_productos = []
for producto in productos:
	tupla = (producto.codigo_referencia, producto.nombre_producto, producto.precio_producto, producto.url_imagen) 
	lista_productos.append(tupla)

session.execute("TRUNCATE productos_visitados")
session.execute("TRUNCATE carro")
session.execute("TRUNCATE compras")
session.execute("TRUNCATE compras_detalle")
session.execute("TRUNCATE contador_productos_vendidos")

usuarios = session.execute('SELECT * FROM usuarios')
for usuario in usuarios:

  # Cargamos tabla de productos visitados por usuario
  for contador in range(random.randint(2,12)):
		producto = random.choice(lista_productos)
		tupla_p_v = (usuario.usuario_id, producto[0], random_date(start, end), producto[1], producto[2], producto[3])
		sent_productos_visitados = session.prepare("INSERT INTO productos_visitados " +
								"(usuario_id, codigo_referencia, fecha_ultima_visita, nombre_producto, precio_producto, url_imagen) " + 
								"VALUES (?, ?, ?, ?, ?, ? )")
		session.execute(sent_productos_visitados, tupla_p_v)
	
  # Cargamos tabla de carro
  importe = 0
  lista_p1 = []
  for contador in range(random.randint(0,6)):
    producto = random.choice(lista_productos)
    if (producto[0] not in lista_p1):
      lista_p1.append(producto[0])
      cantidad = random.randint(1,3)
      importe += round(cantidad * producto[2], 2)
      tupla_carro = (usuario.usuario_id, producto[0], producto[1], cantidad, producto[2], producto[3])
      sent_productos_visitados = session.prepare("INSERT INTO carro " +
  								"(usuario_id, codigo_referencia, nombre_producto, cantidad, precio_producto, importe, url_imagen) " + 
  								"VALUES (?, ?, ?, ?, ?," + "{:0.2f}".format(importe) + ", ? )")
      session.execute(sent_productos_visitados, tupla_carro)

  importe = 0
  lista_p2 = []
  # Cargamos tabla de compras
  for cont_compra in range(0, 8):
    factura = ''.join(random.choice(ascii_uppercase) for _ in range(12))
    fecha = random_date(start, end)
    importe = 0
    batch = BatchStatement(BatchType.LOGGED)
    for contador in range(random.randint(0,6)):
      producto = random.choice(lista_productos)
      if (producto[0] not in lista_p2):
        lista_p2.append(producto[0])
        cantidad = random.randint(1,3)
        importe += round(cantidad * producto[2], 2)
        tupla_cd = (usuario.usuario_id, factura, fecha, producto[0], producto[1], cantidad, producto[2], producto[3])
        prepared = session.prepare("INSERT INTO compras_detalle " +
    								"(usuario_id, factura, fecha_compra, codigo_referencia, nombre_producto, cantidad, precio_producto, importe, url_imagen) " + 
    								"VALUES (?, ?, ?, ?, ?, ?, ?," + "{:0.2f}".format(importe) + ", ? )")
        batch.add(prepared, tupla_cd)
        session.execute(
              "UPDATE contador_productos_vendidos " +
							"SET numero_ventas = numero_ventas + " + cantidad + " " + 
							"WHERE producto = " + str(producto[0]))

    # Compra
    sentencia = session.prepare("INSERT INTO compras " +
  								"(usuario_id, factura, fecha_compra, importe) " + 
  								"VALUES (?, ?, ?, " + "{:0.2f}".format(importe) + " )")
    batch.add(sentencia, (usuario.usuario_id, factura, fecha))
    session.execute(batch)
    
