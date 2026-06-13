#!/bin/bash
# Run locally, executes inside the K8s pod, logs locally
# ./bin/cleanup.sh

# Actual deletion
# DRY_RUN=false ./bin/cleanup.sh

# Different pod
# POD=other-pod-name ./bin/cleanup.sh

# Different namespace
# NS=utk-hyku-production ./bin/cleanup.sh

# Different age threshold (e.g., 60 days)
# AGE_DAYS=60 ./bin/cleanup.sh

# Parallel rm -rf workers during actual deletion (default 8, set to 1 to disable)
# PARALLEL=16 ./bin/cleanup.sh

# Combine multiple
# DRY_RUN=false POD=my-pod NS=my-namespace ./bin/cleanup.sh

POD="${POD:-utk-hyku-production-hyrax-worker-7b49b77585-bhcfc}"
NS="${NS:-utk-hyku-production}"
DRY_RUN="${DRY_RUN:-true}"
AGE_DAYS="${AGE_DAYS:-30}"
PARALLEL="${PARALLEL:-8}"
LOG="bin/cleanup_$(date +%Y%m%d_%H%M%S).log"

echo "Running cleanup on pod: $POD"
echo "Namespace: $NS"
echo "DRY_RUN: $DRY_RUN"
echo "AGE_DAYS: $AGE_DAYS"
echo "PARALLEL: $PARALLEL"
echo "Log file: $LOG"
echo ""

kubectl exec -n "$NS" "$POD" -- bash -c "
IMPORTS_DIR=\"/app/samvera/hyrax-webapp/tmp/imports\"
AGE_DAYS=$AGE_DAYS
DRY_RUN=$DRY_RUN
PARALLEL=$PARALLEL
TODAY=\$(date +%s)

echo \"=== Bulkrax Imports Cleanup ===\"
echo \"DRY_RUN: \$DRY_RUN\"
echo \"Started: \$(date)\"
echo \"\"

deleted_count=0
deleted_bytes=0
dirs_to_delete=()

human_size() {
  local bytes=\"\$1\"
  if [ \"\$bytes\" -gt 1099511627776 ]; then
    awk -v b=\"\$bytes\" 'BEGIN {printf \"%.2f TB\", b / 1099511627776}'
  elif [ \"\$bytes\" -gt 1073741824 ]; then
    awk -v b=\"\$bytes\" 'BEGIN {printf \"%.2f GB\", b / 1073741824}'
  elif [ \"\$bytes\" -gt 1048576 ]; then
    awk -v b=\"\$bytes\" 'BEGIN {printf \"%.1f MB\", b / 1048576}'
  else
    awk -v b=\"\$bytes\" 'BEGIN {printf \"%.1f KB\", b / 1024}'
  fi
}

extract_date() {
  local name=\"\$1\"
  if [[ \"\$name\" =~ _([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
    echo \"\${BASH_REMATCH[1]}-\${BASH_REMATCH[2]}-\${BASH_REMATCH[3]}\"
  fi
}

process_dir() {
  local dir=\"\$1\"
  local name=\$(basename \"\$dir\")
  local date=\$(extract_date \"\$name\")
  [ -z \"\$date\" ] && return
  local epoch=\$(date -d \"\$date\" +%s 2>/dev/null || echo 0)
  [ \"\$epoch\" = \"0\" ] && return
  local age=\$(( (TODAY - epoch) / 86400 ))
  if [ \"\$age\" -ge \"\$AGE_DAYS\" ]; then
    local bytes=\$(du -sb \"\$dir\" 2>/dev/null | cut -f1)
    local size=\$(human_size \"\$bytes\")
    echo \"DELETE: \$dir (\$size, \${age}d old)\"
    deleted_count=\$((deleted_count + 1))
    deleted_bytes=\$((deleted_bytes + bytes))
    dirs_to_delete+=(\"\$dir\")
  fi
}

for dir in \"\$IMPORTS_DIR\"/import_*/ \"\$IMPORTS_DIR\"/[0-9]*_[0-9]*/; do
  [ -d \"\$dir\" ] || continue
  process_dir \"\$dir\"
done

for tenant_dir in \"\$IMPORTS_DIR\"/*/; do
  [ -d \"\$tenant_dir\" ] || continue
  tenant=\$(basename \"\$tenant_dir\")
  [[ \"\$tenant\" == import_* ]] && continue
  [[ \"\$tenant\" =~ ^[0-9]+_[0-9]+ ]] && continue
  for dir in \"\$tenant_dir\"import_*/ \"\$tenant_dir\"[0-9]*_[0-9]*/; do
    [ -d \"\$dir\" ] || continue
    process_dir \"\$dir\"
  done
done

echo \"\"
echo \"=== Summary ===\"
echo \"Directories: \$deleted_count\"
echo \"Size: \$(human_size \$deleted_bytes)\"

if [ \"\$DRY_RUN\" = \"false\" ] && [ \${#dirs_to_delete[@]} -gt 0 ]; then
  echo \"\"
  echo \"Deleting \${#dirs_to_delete[@]} directories with \$PARALLEL parallel workers...\"
  printf '%s\0' \"\${dirs_to_delete[@]}\" | xargs -0 -P \"\$PARALLEL\" rm -rf
  echo \"Deletion complete.\"
fi

echo \"Completed: \$(date)\"
" 2>&1 | tee "$LOG"

echo ""
echo "Log saved to: $LOG"
