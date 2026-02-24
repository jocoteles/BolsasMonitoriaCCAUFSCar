#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: ./initGAS.sh <NomeDoProjeto>"
  exit 1
fi

PROJECT_NAME="$1"
BASE_DIR="$(pwd)"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

if [ -e "$PROJECT_DIR" ]; then
  echo "Erro: a pasta '$PROJECT_NAME' já existe."
  exit 1
fi

mkdir -p "$PROJECT_DIR/public" "$PROJECT_DIR/server"

cat > "$PROJECT_DIR/.env" <<'ENVEOF'
# Variáveis e chaves sensíveis (NÃO versionar em repositório público)
# Exemplo:
# API_KEY=seu_valor_aqui
ENVEOF

cat > "$PROJECT_DIR/placeholders.json" <<'JSONEOF'
{
  "SPREADSHEET_ID": "SEU_ID_AQUI",
  "WEBAPP_EXEC_URL": "https://script.google.com/macros/s/SEU_DEPLOY_EXEC/exec",
  "WEBAPP_DEV_URL": "https://script.google.com/macros/s/SEU_DEPLOY_DEV/dev"
}
JSONEOF

cat > "$PROJECT_DIR/.claspignore" <<'EOFIGNORE'
# Ignorar arquivos locais que não devem ir para o Apps Script
.env
placeholders.json
syncgas.sh
README.md
EOFIGNORE

cat > "$PROJECT_DIR/public/index.html" <<'HTMLEOF'
<!DOCTYPE html>
<html>
  <head>
    <base target="_top">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>GAS WebApp</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 2rem; }
      h1 { margin-bottom: 0.5rem; }
      .card { border: 1px solid #ddd; padding: 1rem; border-radius: 8px; max-width: 520px; }
      button { padding: 0.5rem 1rem; }
      pre { background: #f7f7f7; padding: 0.75rem; border-radius: 6px; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>GAS WebApp</h1>
      <p>Exemplo mínimo integrado com Apps Script.</p>
      <button onclick="carregarInfo()">Carregar info</button>
      <pre id="output">Clique no botão acima</pre>
    </div>

    <script>
      function carregarInfo() {
        google.script.run.withSuccessHandler(function(data) {
          document.getElementById('output').textContent = JSON.stringify(data, null, 2);
        }).getServerInfo();
      }
    </script>
  </body>
</html>
HTMLEOF

cat > "$PROJECT_DIR/server/Code.gs" <<'GSEOF'
// Code.gs
// Não altere o valor das variáveis abaixo; edite em placeholders.json.
//Placeholders_INI:
const SPREADSHEET_ID = Placeholder_SPREADSHEET_ID;
//Placeholders_FIM

/**
 * Função principal que serve a aplicação web.
 */
function doGet() {
  const template = HtmlService.createTemplateFromFile('index.html');
  return template
    .evaluate()
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/**
 * Exemplo simples de método do servidor.
 */
function getServerInfo() {
  return {
    now: new Date().toISOString(),
    spreadsheetId: SPREADSHEET_ID
  };
}
GSEOF

cat > "$PROJECT_DIR/syncgas.sh" <<'SHEOF'
#!/bin/bash
set -euo pipefail

WATCH=false
for arg in "$@"; do
  case "$arg" in
    --watch)
      WATCH=true
      ;;
    *)
      echo "Erro: Opção inválida '$arg'. Use apenas '--watch' (opcional)."
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

# Clasp push
pushd server > /dev/null
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
SHEOF

chmod +x "$PROJECT_DIR/syncgas.sh"

cat > "$PROJECT_DIR/README.md" <<'READMEOF'
# GASFramework (projeto)

Estrutura mínima para desenvolvimento de WebApp em Google Apps Script usando Google Sheets como banco de dados.

## Estrutura

- `public/`: HTML, CSS, JS do frontend
- `server/`: arquivos `.gs` (backend Apps Script)
- `.env`: variáveis/chaves locais (não versionar)
- `placeholders.json`: IDs e chaves que serão injetados no código
- `syncgas.sh`: substitui placeholders e faz `clasp push`

## Passo a passo

1. Instale e autentique o clasp:
   - `npm install -g @google/clasp`
   - `clasp login`

2. Entre na pasta `server/` e crie/associe o projeto GAS:
   - `clasp create --type webapp --title "Nome do Projeto"`
   - ou `clasp clone <SCRIPT_ID>`

3. Preencha `placeholders.json` (inclui `/exec` e `/dev`).

4. Rode o sync (na raiz do projeto):
   - `./syncgas.sh`
   - opcional: `./syncgas.sh --watch`

## Placeholders

As variáveis de placeholder devem estar entre:

```js
//Placeholders_INI:
const VAR = Placeholder_VAR;
//Placeholders_FIM
```

Não edite os valores ali; edite em `placeholders.json`.

## Implantação no GAS

1. Abra o projeto no Apps Script.
2. Acesse `Implementar -> Gerenciar implantações`.
3. Clique em `Editar` e depois `Nova versão`.
4. Clique em `Implantar`.

A URL `/dev` já funciona sem implantação. A URL `/exec` exige implantação.
READMEOF

echo "Projeto '$PROJECT_NAME' criado em $PROJECT_DIR"
