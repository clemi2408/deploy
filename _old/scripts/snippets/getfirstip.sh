#!/bin/bash
IP=$(hostname -I | head -n 1 | xargs)
echo $IP
