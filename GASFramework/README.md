# GASFramework

Framework mínimo para WebApp em Google Apps Script (GAS) com Google Sheets como banco de dados. Sem build, sem Node local (exceto o `clasp`).

## O que ele cria

- `public/` para frontend
- `server/` para arquivos `.gs`
- `.env` para segredos locais
- `placeholders.json` para IDs/variáveis e URLs `/exec` e `/dev`
- `syncgas.sh` para substituir placeholders e fazer `clasp push`

## Uso rápido

```bash
cd GASFramework
./initGAS.sh MeuProjeto
cd MeuProjeto
./syncgas.sh
```

Para acompanhar alterações locais em tempo real:

```bash
./syncgas.sh --watch
```

## Observações

- `syncgas.sh` faz backup simples em `../.backup`.
- Placeholders devem estar entre `//Placeholders_INI:` e `//Placeholders_FIM`.
- Substituição de `{{KEY}}` é feita em `public/` e `server/`.

## Implantação no GAS

Para efetivar a versão `/exec` sem alterar a URL:
1. Acesse `Implementar -> Gerenciar implantações`.
2. Clique em `Editar` -> `Nova versão` -> `Implantar`.

A versão `/dev` é atualizada automaticamente pelo GAS.
