#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from datetime import (datetime, timedelta)
from random import randrange

# Para crear fechas al azar
def random_date(start, end):
  delta = end - start
  int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
  random_second = randrange(int_delta)
  return start + timedelta(seconds=random_second)

start = datetime.strptime('1/1/2015 1:30 PM', '%m/%d/%Y %I:%M %p')
end = datetime.strptime('4/1/2017 7:30 PM', '%m/%d/%Y %I:%M %p')
		
# Producto cartesiano de tuplas para salvar productos relacionados
# Función que rellena una lista de productos y luego llama a la función productoCartesiano para obtener la lista definitiva.
def tuplas_producto(session, factura):
  productos = session.execute("SELECT codigo_referencia FROM compras_detalle WHERE factura = '" + factura.factura + "'")
  lista_prod = []
  for producto in productos:
    lista_prod.append(producto.codigo_referencia)
  return productoCartesiano(lista_prod)

# Función que dada una lista devuelve el producto cartesiano de todas las tuplas.
def productoCartesiano(lista):
  def recursive(elemento, lista, result):
    if not lista:
      return result
    else:
      return recursive(elemento, lista[1::], result + [(elemento, lista[0])])
  
  if not lista:
    return []
  else:
    return recursive(lista[0], lista[1::], []) + productoCartesiano(lista[1::])
