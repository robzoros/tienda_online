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

start = datetime.strptime('1/1/2008 1:30 PM', '%m/%d/%Y %I:%M %p')
end = datetime.strptime('1/1/2017 9:30 PM', '%m/%d/%Y %I:%M %p')
		

