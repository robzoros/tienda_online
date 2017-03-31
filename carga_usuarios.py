#!/usr/bin/env python
# -*- coding: utf-8 -*- 
from utiles import (random_date, start, end)
import random
from string import (ascii_lowercase, ascii_uppercase)
from cassandra.cluster import Cluster

# Conectamos al Cluster
cluster = Cluster()
session = cluster.connect('tienda_online')
session.execute("TRUNCATE usuarios")
# Alta en tabla usuarios
random.seed(12)
for nombre in ['Angel', 'Emilio', 'Carla', 'Alonso']:
	for apellidos in ['Martínez', 'Campos', 'Pino']:
		numero = random.randint(3, 120)
		tipo_calle = random.choice(['Calle', 'Avenida', 'Plaza'])
		calle = random.choice(ascii_uppercase) + ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(5, 12)))
		direccion = tipo_calle + " de " + calle + ", " + str(numero)
		email = nombre.lower() + "@" + ''.join(random.choice(ascii_lowercase) for _ in range(random.randint(8, 12))) + ".com"
		sentencia = session.prepare("INSERT INTO usuarios (usuario_id, nombre, apellidos, direccion, email ) VALUES (uuid(), ?, ?, ?, ? )")
		session.execute(sentencia, (nombre, apellidos, direccion, email))
