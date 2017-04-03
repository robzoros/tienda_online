# Online shop design with Cassandra (and python)

## What is this?
This project has two type of source files:
- `.cql` files with the creation of the tables
- `.py` files with the scripts to fill the tables with pseudo-random data

## Why?
I've created this little project to help me with the design task of a Cassandra's course.

## Instructions
I've installed Cassandra on an AWS EC2 machine.
This are the steps to install Cassandra, Python Cassandra Driver and how to execute the project.

### Install java 8
```
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt-get update
$ sudo apt-get -y install oracle-java8-installer
```
### Install Cassandra 3.1
```
$ echo "deb http://www.apache.org/dist/cassandra/debian 310x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
$ curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
$ sudo apt-get update
$ sudo apt-get install cassandra
```

### Install Driver Python de Cassandra
```
$ sudo apt install python-pip
$ pip install cassandra-driver
```

### Init Cassandra Driver
```
$ sudo service cassandra start
$ nodetool status
```

### Ejecutar python program to get pseudo random data
```
$ git clone https://github.com/robzoros/tienda_online.git
$ cd tienda online
$ ./loadandtest.sh
```
