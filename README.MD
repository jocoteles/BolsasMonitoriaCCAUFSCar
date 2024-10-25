**Distribuição de Bolsas de Monitoria do CCA-UFSCar**
==============

Este código vem sendo utilizado desde 2022 e tem como objetivo distribuir um número limitado de bolsas de monitoria entre os diferentes departamentos do CCA/UFSCar de forma a minimizar a desigualdade na proporção de bolsas recebidas em relação às bolsas solicitadas. Para isso, o código calcula várias combinações de distribuição e seleciona as melhores com base no desvio padrão dessas proporções.

[Clique aqui para usá-lo diretamente no navegador](https://jocoteles.github.io/BolsasMonitoriaCCAUFSCar/)

Também é possível rodá-lo localmente, baixando e executando o código Python `distribuidorBolsa.py`.

### Ponto-chave
O objetivo do código é encontrar distribuições de bolsas que sejam mais "justas", no sentido de que a proporção de bolsas atribuídas em relação às solicitadas seja mais equilibrada entre os departamentos. Para isso, o desvio padrão é usado como métrica de desigualdade: quanto menor o desvio padrão, mais similar é a proporção de bolsas atribuídas para todos os departamentos.

### Resumo da lógica
1. Todas as combinações possíveis de distribuição de bolsas entre os departamentos são calculadas.
2. Para cada combinação, calcula-se o desvio padrão das proporções de bolsas atribuídas em relação ao número solicitado.
3. As distribuições são ordenadas por desvio padrão, e as `NmelhoresDistribuicoes` são exibidas, mostrando as frações atribuídas e o desvio padrão resultante.

### Código

```python

from statistics import stdev

solicitacoesDepartamentos = [
    ['DBPVA', 4],
    ['DCNME', 10],
    ['DDR', 3],
    ['DTAiSeR', 2],
    ['DRNPA', 2]
]

bolsasDisponiveis = 12

NmelhoresDistribuicoes = 10

#--------------------------------------------------------------------

bolsasSolicitadas = [b[1] for b in solicitacoesDepartamentos]
Ndepts = len(solicitacoesDepartamentos)
bolsasAtribuidas = [0]*Ndepts
bolsasTodasCombinacoes = []

def updateBolsasTodasCombinacoes (bolsas):
    bsR = [bolsa/solicitada for bolsa, solicitada in zip(bolsas, bolsasSolicitadas)]                        
    bolsas.append(stdev(bsR))
    bolsasTodasCombinacoes.append(bolsas)

for i in range(bolsasDisponiveis+1): 
    if (Ndepts == 2):
        updateBolsasTodasCombinacoes([i, bolsasDisponiveis-i])
    else:
        for j in range(bolsasDisponiveis-i+1):
            if (Ndepts == 3):                
                updateBolsasTodasCombinacoes([i, j, bolsasDisponiveis-i-j])
            else:
                for k in range(bolsasDisponiveis-i-j+1):
                    if (Ndepts == 4):
                        updateBolsasTodasCombinacoes([i, j, k, bolsasDisponiveis-i-j-k])
                    else:
                        for l in range(bolsasDisponiveis-i-j-k+1):                            
                            updateBolsasTodasCombinacoes([i, j, k, l, bolsasDisponiveis-i-j-k-l])

bolsasTodasCombinacoes.sort(key = lambda bolsas: bolsas[-1])

header = [dep[0] for dep in solicitacoesDepartamentos]
print('\t\t'.join(header) + '\t\tStd Dev')
for i in range(NmelhoresDistribuicoes):    
    fracs = [f"({bolsa}/{solicitada}){(bolsa/solicitada):.3f}" for bolsa, solicitada in zip(bolsasTodasCombinacoes[i][:-1], bolsasSolicitadas)]    
    print('\t'.join(fracs) + f'\t{bolsasTodasCombinacoes[i][-1]:.3f}')

```

### Explicação do código

1. **Variáveis principais**:
   - `solicitacoesDepartamentos`: uma lista de departamentos e o número de bolsas solicitadas por cada um.
   - `bolsasDisponiveis`: o número total de bolsas que estão disponíveis para distribuição.
   - `NmelhoresDistribuicoes`: número de melhores distribuições que serão mostradas ao final (com menor desvio padrão).

2. **Variáveis derivadas**:
   - `bolsasSolicitadas`: uma lista com o número de bolsas solicitadas por cada departamento.
   - `Ndepts`: o número de departamentos que solicitaram bolsas.
   - `bolsasAtribuidas`: uma lista que mantém a contagem de bolsas atribuídas a cada departamento (inicialmente zerada).
   - `bolsasTodasCombinacoes`: uma lista que armazena todas as combinações possíveis de distribuição de bolsas, juntamente com o desvio padrão das proporções.

3. **Função `updateBolsasTodasCombinacoes`**:
   - Calcula a proporção de bolsas atribuídas em relação ao solicitado para cada departamento.
   - Calcula o desvio padrão (`stdev`) dessas proporções.
   - Armazena a combinação de distribuição de bolsas junto com o desvio padrão.

4. **Laços de repetição**:
   - Os loops for aninhados geram todas as combinações possíveis de distribuição de bolsas para o número de departamentos especificado (`Ndepts`).
   - Por exemplo, se houver 5 departamentos, o código considera todos os valores possíveis de distribuição que somem ao total de `bolsasDisponiveis`.

5. **Ordenação das combinações**:
   - As combinações de distribuição de bolsas são ordenadas pelo desvio padrão das proporções, do menor para o maior.

6. **Impressão dos resultados**:
   - O código imprime os `NmelhoresDistribuicoes` (as combinações com o menor desvio padrão). Cada linha mostra a fração de bolsas atribuídas em relação ao solicitado para cada departamento, além do desvio padrão dessa distribuição.

### Detalhamento dos condicionais if-else dentro do loop for

Os blocos de condicionais (`if` e `else`) dentro do loop for são usados para lidar com o número de departamentos (`Ndepts`). O objetivo é ajustar a profundidade dos loops de acordo com o número de departamentos envolvidos. Como `Ndepts` é variável, o código precisa adaptar o número de laços for aninhados para garantir que a soma das bolsas distribuídas entre todos os departamentos seja sempre igual ao total de bolsas disponíveis (`bolsasDisponiveis`).

- A estrutura `if-else` permite ao código adaptar dinamicamente o número de loops for aninhados com base no valor de `Ndepts`. Cada laço for adicional é necessário para garantir que as combinações sejam geradas corretamente quando o número de departamentos aumenta.
- Em cada nível, uma quantidade de bolsas é atribuída a um departamento, e o restante é atribuído aos departamentos subsequentes por meio dos loops mais internos.
- Essa adaptação dinâmica evita que o código tenha uma quantidade fixa de loops, o que o torna mais flexível e escalável.

Essa lógica é fundamental para garantir que as bolsas sejam distribuídas de maneira completa, sem a necessidade de especificar manualmente todos os loops para diferentes números de departamentos.

De forma mais detalhada, temos:

1. **Caso `Ndepts == 2`**:
   ```python
   if (Ndepts == 2):
       updateBolsasTodasCombinacoes([i, bolsasDisponiveis-i+1])
   ```
   Aqui, o código assume que há apenas dois departamentos. Com isso, ele precisa apenas de um laço (`for i`) para determinar quantas bolsas são atribuídas ao primeiro departamento, e o restante (`bolsasDisponiveis - i + 1`) é automaticamente atribuído ao segundo departamento. O valor `(bolsasDisponiveis - i + 1)` garante que a soma total das bolsas atribuídas seja igual a `bolsasDisponiveis`.

2. **Caso `Ndepts == 3`**:
   ```python
   else:
       for j in range(bolsasDisponiveis-i+1):
           if (Ndepts == 3):                
               updateBolsasTodasCombinacoes([i, j, bolsasDisponiveis-i-j+1])
   ```
   Quando `Ndepts == 3`, além do loop `for i`, há um segundo loop `for j`. Aqui, o código:
   - Primeiro distribui `i` bolsas ao primeiro departamento.
   - Em seguida, distribui `j` bolsas ao segundo departamento.
   - O restante das bolsas, dado por `(bolsasDisponiveis - i - j + 1)`, é automaticamente atribuído ao terceiro departamento.

3. **Caso `Ndepts == 4`**:
   ```python
   else:
       for k in range(bolsasDisponiveis-i-j+1):
           if (Ndepts == 4):
               updateBolsasTodasCombinacoes([i, j, k, bolsasDisponiveis-i-j-k])
   ```
   Quando há quatro departamentos, são necessários três loops aninhados (`for i`, `for j`, `for k`). O código:
   - Distribui `i` bolsas ao primeiro departamento.
   - Distribui `j` bolsas ao segundo departamento.
   - Distribui `k` bolsas ao terceiro departamento.
   - O restante das bolsas, `(bolsasDisponiveis - i - j - k)`, é atribuído automaticamente ao quarto departamento.

4. **Caso `Ndepts == 5`**:
   ```python
   else:
       for l in range(bolsasDisponiveis-i-j-k+1):                            
           updateBolsasTodasCombinacoes([i, j, k, l, bolsasDisponiveis-i-j-k-l])
   ```
   No caso de cinco departamentos, o código utiliza quatro loops aninhados (`for i`, `for j`, `for k`, `for l`). O raciocínio é similar:
   - Distribui `i` bolsas ao primeiro departamento.
   - Distribui `j` bolsas ao segundo departamento.
   - Distribui `k` bolsas ao terceiro departamento.
   - Distribui `l` bolsas ao quarto departamento.
   - O restante das bolsas, `(bolsasDisponiveis - i - j - k - l)`, é atribuído automaticamente ao quinto departamento.
