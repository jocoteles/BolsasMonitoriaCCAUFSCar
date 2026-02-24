# Distribuição de Bolsas - CCA/UFSCar (WebApp GAS)

WebApp para cadastro de disciplinas por departamento, cálculo de distribuição de bolsas e geração de PDF com resultados. Usa Google Apps Script (GAS) com Google Sheets como banco de dados e controle de acesso por representante.

## Funcionalidades

- Cadastro de disciplinas por departamento com validações (código 6 dígitos, CT/CP e soma).
- Peso por disciplina: `P = 1 + CP/(CT + CP)`.
- Distribuição de bolsas com menor desvio padrão das razões solicitadas.
- Regras de semestre:
  - Semestre ímpar: DRNPA participa e recebe mínimo 2 bolsas (se houver solicitação).
  - Semestre par: DRNPA não participa.
- Geração de PDF com disciplinas por departamento e melhores distribuições.
- Controle de acesso por e-mail: cada representante edita apenas o seu departamento; demais ficam em modo leitura.

## Estrutura de dados (Google Sheets)

O app cria as abas automaticamente se não existirem.

### `Representantes`

Cabeçalho (linha 1):

```
Departamento | Nome | Emails
```

Exemplo:

```
DBPVA | João Silva | joao@ufscar.br,joao@gmail.com
```

### `Disciplinas`

Cabeçalho (linha 1):

```
Departamento | Codigo | Disciplina | Professor | CT | CP | AtualizadoPor
```

Essa aba é preenchida pelo app. Você pode pré-carregar manualmente respeitando as colunas.

## Configuração inicial

1. Atualize o ID da planilha em `placeholders.json`.
2. No Apps Script, crie/associe o projeto GAS.
3. Execute `./syncgas.sh` para enviar o código.
4. Na planilha, preencha a aba `Representantes` com os e-mails válidos.
5. Observação: o `syncgas.sh` gera a pasta `dist/` (staging) e faz o `clasp push` a partir dela, pois o GAS não aceita subpastas.
   Use `./syncgas.sh --no-clean` para manter a pasta `dist/` após a execução.

## Parâmetros na interface

Os seguintes parâmetros são definidos na tela do app (não são salvos na planilha):

- `Semestre`: par ou ímpar.
- `Bolsas disponíveis`: mínimo 1, máximo 30.
- `Nº melhores distribuições`: mínimo 1, máximo 10.

## Arquivos principais

- Frontend: `public/index.html`
- Backend GAS: `server/Code.gs`
- Staging para envio ao GAS: `dist/` (gerado pelo `syncgas.sh`)
