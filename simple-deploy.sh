#!/bin/bash
# simple-deploy.sh - Fixed version with proper module path

if [ $# -lt 4 ]; then
    echo "Usage: $0 <project> <log_type> <destination> <environment> [action]"
    echo ""
    echo "Examples:"
    echo "  $0 webapp application s3 dev"
    echo "  $0 webapp application s3 dev apply"
    echo "  $0 security audit cribl prod apply"
    echo ""
    exit 1
fi

# Call the main deployment script
./deploy-firehose.sh -p "$1" -l "$2" -d "$3" -e "$4" -a "${5:-plan}"
