# SOPS_LATEST_VERSION=$(curl -s "https://api.github.com/repos/getsops/sops/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
# curl -LO https://github.com/getsops/sops/releases/download/v${SOPS_LATEST_VERSION}/sops-v${SOPS_LATEST_VERSION}.linux.amd64
# mv sops-v${SOPS_LATEST_VERSION}.linux.amd64 /usr/local/bin/sops
# chmod +x /usr/local/bin/sops && sops -v

if command -v sops >/dev/null 2>&1; then
  echo "✅ SOPS уже установлен: $(sops -v)"
else
  SOPS_VERSION="3.10.2"
  # SOPS_LATEST_VERSION=$(curl -s "https://api.github.com/repos/getsops/sops/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')   # breaking changes
  curl -s -LO "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"
  mv "sops-v${SOPS_VERSION}.linux.amd64" /usr/local/bin/sops
  chmod +x /usr/local/bin/sops
  echo "✅ Установили SOPS $(sops -v)"
fi


# Сбор нужных ключей из SOPS_KEYS
mkdir -p sops
KEYS=""
for name in $SOPS_KEYS; do
  VAR_NAME="SOPS_$(echo "$name" | tr '[:lower:]' '[:upper:]')_KEY"
  VALUE="${!VAR_NAME}"
  cp "${VALUE}" "sops/${name}_key.txt"
  
  # CHECK
  echo "📦 VAR_NAME:           ${VAR_NAME}"
  echo "📦 VALUE:              ${VALUE}"
done

> sops/age_keys.txt
for keyfile in sops/*_key.txt; do
  cat "$keyfile" >> sops/age_keys.txt
  echo >> sops/age_keys.txt
done

export SOPS_AGE_KEY_FILE="sops/age_keys.txt"

# CHECK
echo "📦 CONTENT:              $(ls -la sops)"
echo "📦 SOPS_KEYS:            ${SOPS_KEYS}"
echo "📦 SOPS_AGE_KEY_FILE:    ${SOPS_AGE_KEY_FILE}"
echo "📦 AGE_KEYS.TXT:         $(cat sops/age_keys.txt)"

# Расшифровка всех допустимых файлов в secrets/ (in-place).
find secrets/ -type f \
  ! -name "*.gitkeep" \
  ! -name "README.md" \
  -exec sops --decrypt --in-place {} \;
