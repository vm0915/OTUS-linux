#!/bin/bash

if getent group admin | grep -q "\b${PAM_USER}\b"; then
  exit 0
elif [[ $(date +%a) =~ ^Sat|Sun$ ]]; then
  exit 0
else
  exit 1
fi

