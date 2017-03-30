#
# Scritpt to Create Cassandra database tienda_online and load pseudo random data to test
#
echo 'Creating Cassandra Data Base'
cqlsh -f tienda_online.cql

echo 'Loading pseudo random data'
echo 'Loading users'
python carga_usuarios.py
echo 'Loading products'
python carga_productos.py
echo 'Loading users buys'
python carga_usu_prod.py
echo 'Updating auxiliar tables'
python carga_prod_relacionados.py
echo 'Updating counters'
python carga_contadores.py
