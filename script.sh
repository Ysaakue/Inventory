#!/bin/bash

git pull origin develop
rake db:migrate
rake start
