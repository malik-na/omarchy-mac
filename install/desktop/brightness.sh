#!/bin/bash

# Add user to video and input groups for brightness control
sudo usermod -aG video,input $(logname)
