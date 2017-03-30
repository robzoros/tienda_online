from utiles import (random_date, start, end, tuplas_producto)
from cassandra.cluster import Cluster

# Conectamos al Cluster
cluster = Cluster()
session = cluster.connect('tienda_online')
session.execute("TRUNCATE contador_prod_vendidos_juntos")

#******************************************************
#          PRODUCTOS RELACIONADOS EN COMPRAS
#******************************************************

# Recorremos todas las compras
facturas = session.execute("SELECT factura FROM compras")

for factura in facturas:
  #obtenemos todos los productos de la compra y creamos una lista de tuplas producto = producto relacionado
  lista_tuplas = tuplas_producto(session, factura)

  # Actualizamos tabla de contadores de productos relacionados.
  for tupla in lista_tuplas:
    session.execute(
              "UPDATE contador_prod_vendidos_juntos " +
							"SET numero_ventas = numero_ventas + 1 " + 
							"WHERE producto = " + str(tupla[0]) +  " AND producto_rel = " + str(tupla[1]))
    session.execute(
              "UPDATE contador_prod_vendidos_juntos " +
							"SET numero_ventas = numero_ventas + 1 " + 
							"WHERE producto = " + str(tupla[1]) +  " AND producto_rel = " + str(tupla[0]))

  