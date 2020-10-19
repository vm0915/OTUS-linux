#!/bin/bash

if grep $KEYWORD $FILE &> /dev/null
then
	logger "$KEYWORD is present in $FILE"
else 
	exit 0
fi
