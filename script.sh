#!/bin/bash

git pull origin master
rake db:migrate
rake start
