#!/usr/bin/env bash

source azure-config.env

az batch account delete $BATCH_ACCOUNT

