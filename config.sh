#!/bin/bash
# Copy this file to /opt/penzsh/config.sh and update with your personal preferences

##### W O R D L I S T S #######################################################
export PENZSH_WORDLIST_WEBENUM="$(locate --regex /Web-Content/big.txt$ | head -n 1)"
export PENZSH_WORDLIST_PASSWORDS="$(locate -b --regex ^rockyou.txt$ | head -n 1)"
