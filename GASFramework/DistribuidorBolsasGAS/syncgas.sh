#!/bin/bash
set -euo pipefail

WATCH=false
NO_CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --watch)
      WATCH=true
      ;;
    --no-clean)
      NO_CLEAN=true
      ;;
    *)
      echo "Erro: Opção inválida '$arg'. Use apenas '--watch' e/ou '--no-clean' (opcionais)."
      exit 1
      ;;
  esac
done

if [ ! -f "placeholders.json" ]; then
  echo "Erro: placeholders.json não encontrado."
  exit 1
fi

SED_CMDS=$(mktemp)
MAP_FILE=$(mktemp)

# Placeholders gerais
grep -o '"[^"]*": "[^"]*"' placeholders.json | sed 's/"//g' | while IFS=": " read -r key value; do
  echo "s|{{$key}}|$value|g" >> "$SED_CMDS"
  printf "%s\t%s\n" "$key" "$value" >> "$MAP_FILE"
done

# URLs (exec/dev)
WEBAPP_EXEC_URL=$(grep -o "\"WEBAPP_EXEC_URL\": \"[^\"]*\"" placeholders.json | cut -d'"' -f4)
WEBAPP_DEV_URL=$(grep -o "\"WEBAPP_DEV_URL\": \"[^\"]*\"" placeholders.json | cut -d'"' -f4)

if [ -n "$WEBAPP_EXEC_URL" ]; then
  echo "s|{{WEBAPP_URL}}|$WEBAPP_EXEC_URL|g" >> "$SED_CMDS"
else
  echo "Aviso: WEBAPP_EXEC_URL não encontrada em placeholders.json."
fi

# Avisos iniciais no modo watch
if [ "$WATCH" = true ]; then
  echo "--------------------------------------------------"
  echo "SINCRONIZAÇÃO CONCLUÍDA: Modo --watch"
  if [ -n "$WEBAPP_DEV_URL" ]; then
    echo "URL do Web App (dev): $WEBAPP_DEV_URL"
    echo "Aviso: Alterações locais são refletidas automaticamente nessa URL."
  else
    echo "Aviso: WEBAPP_DEV_URL não encontrada em placeholders.json."
  fi
  echo "Atenção: Se houver links para o app, eles sempre apontam para a versão de produção /exec. Se ela não estiver implantada, pode haver incompatibilidade interna no app."
  echo "Aviso: Se você alterar variáveis de placeholder, execute o sync novamente para atualizar os valores no código."
  echo "--------------------------------------------------"
fi

# Backup simples fora da pasta do projeto
BACKUP_DIR="../.backup"
mkdir -p "$BACKUP_DIR"
rm -rf "$BACKUP_DIR/backup_$(basename "$(pwd)")"
cp -r . "$BACKUP_DIR/backup_$(basename "$(pwd)")"

# Substituição de placeholders (bloco) em server/*.gs e server/*.js
find server -type f \( -name "*.gs" -o -name "*.js" \) -print0 | while IFS= read -r -d '' file; do
  awk -v mapfile="$MAP_FILE" '
    BEGIN {
      while ((getline line < mapfile) > 0) {
        split(line, a, "\t")
        map[a[1]] = a[2]
      }
    }
    {
      if ($0 ~ /^[[:space:]]*\/\/Placeholders_INI:/) { in_block = 1; print; next }
      if ($0 ~ /^[[:space:]]*\/\/Placeholders_FIM/) { in_block = 0; print; next }
      if (in_block) {
        line = $0
        if (line ~ /^[[:space:]]*(const|let|var)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=/) {
          tmp = line
          sub(/^[[:space:]]*(const|let|var)[[:space:]]+/, "", tmp)
          sub(/[[:space:]]*=.*/, "", tmp)
          key = tmp
          if (key in map) {
            match($0, /^[[:space:]]*/)
            indent = substr($0, RSTART, RLENGTH)
            print indent "const " key " = \"" map[key] "\";"
            next
          }
        }
      }
      print
    }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

# Substituição geral {{KEY}} em public/ e server/
find public server -type f \( -name "*.gs" -o -name "*.html" -o -name "*.json" -o -name "*.js" \) -print0 | \
  xargs -0 -I {} sed -i -f "$SED_CMDS" {}

rm "$SED_CMDS"
rm "$MAP_FILE"

# Staging para manter o Apps Script sem subpastas
DIST_DIR="dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp appsscript.json "$DIST_DIR/"
find server -type f \( -name "*.gs" -o -name "*.js" \) -print0 | \
  xargs -0 -I {} cp {} "$DIST_DIR/"
find public -type f \( -name "*.html" -o -name "*.js" -o -name "*.json" \) -print0 | \
  xargs -0 -I {} cp {} "$DIST_DIR/"

# Clasp push
pushd "$DIST_DIR" > /dev/null
if [ "$WATCH" = true ]; then
  echo "Executando 'clasp push --watch' em $(pwd)..."
  clasp push --watch
else
  echo "Executando 'clasp push' em $(pwd)..."
  clasp push
fi
popd > /dev/null

if [ "$WATCH" = true ]; then
  exit 0
fi

if [ "$NO_CLEAN" = false ]; then
  rm -rf "$DIST_DIR"
fi

echo "--------------------------------------------------"
echo "SINCRONIZAÇÃO CONCLUÍDA"
if [ -n "$WEBAPP_EXEC_URL" ]; then
  echo "URL do Web App (exec): $WEBAPP_EXEC_URL"
else
  echo "Aviso: WEBAPP_EXEC_URL não encontrada em placeholders.json."
fi
if [ -n "$WEBAPP_DEV_URL" ]; then
  echo "URL do Web App (dev): $WEBAPP_DEV_URL"
else
  echo "Aviso: WEBAPP_DEV_URL não encontrada em placeholders.json."
fi
echo "Para efetivar a versão /exec, acesse: GAS -> Implementar -> Gerenciar implantações -> Editar -> Nova versão -> Implantar."
echo "A versão /dev já deve estar pronta e não precisa de implantação."
echo "Atenção: Se houver links para o app, eles sempre apontam para a versão de produção /exec. Se ela não estiver implantada, pode haver incompatibilidade interna no app."
echo "Aviso: Se você alterar variáveis de placeholder, execute o sync novamente para atualizar os valores no código."
echo "--------------------------------------------------"
