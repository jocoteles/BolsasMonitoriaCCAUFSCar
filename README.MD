**Proposta de Regras para Bolsas de Monitoria do CCA-UFSCar**
==============

Proposta de regras para a distribuição de bolsas de monitoria no Centro de Ciências Agrárias da Universidade Federal de São Carlos.

Para acessar a página da proposta [clique aqui](https://jocoteles.github.io/BolsasMonitoriaCCAUFSCar/).

- Assista ao [vídeo explicativo](https://youtu.be/46nYxaz4Ijk) sobre as regras.
- Caso tenha interesse na explicação do código que implementa as regras, assista [este vídeo](https://youtu.be/04L09SIT9yA).

---

**Regras Completas**

**Atenção:** este conjunto de regras é uma proposta que encontra-se em análise e, portanto, não possui ainda qualquer valor legal.

1. A Comissão de Bolsas de Monitoria do CCA/UFSCar (CBM-CCA) deverá definir a distribuição de bolsas de monitoria entre os departamentos do CCA/UFSCar respeitando os critérios estebelecidos neste documento.
2. O prazo máximo para a definição da distribuição de bolsas pela CBM-CCA será de 10 dias após a disponibilização de vagas pela ProGrad/UFSCar.
3. Não há limite de vagas não remuneradas para bolsistas voluntários, sendo os critérios e limites dessa modalidade de vaga definidos por cada departamento. Portanto, este conjunto de regras aplica-se somente às vagas remuneradas.
4. Não há limitação de solicitações de bolsas por docente ou por turma.
5. A distribuição das bolsas por departamento seguirá o processo na ordem a seguir:

   **Item 5.1:** Chamaremos de $B_S$ o número total de bolsas solicitadas e de $B_D$ o número total de bolsas disponíveis para o CCA.

   **Item 5.2:** Caso $B_{S} \leq B_{D}$, todas as solicitações serão atendidas e encerra-se o processo.

   **Item 5.3:** Caso $B_{S} > B_{D}$, verifica-se qual é o número $N_{S_{max}}$ que corresponde ao maior número de bolsas solicitadas para uma mesma turma.

   **Item 5.4:** Caso $N_{S_{max}} > 1$, cada turma que contenha a solicitação de $N_{S_{max}}$ terá a sua solicitação reduzida em 1 (uma) bolsa. Essas reduções produzirão um número total de bolsas solicitadas reduzidas, que chamaremos de $B_{SR}$. Caso $B_{SR} \leq B_{D}$, as solicitações reduzidas serão atendidas e encerra-se o processo. Caso contrário, verifica-se qual é o $N_{SR_{max}}$ das solicitações reduzidas e aplica-se o procedimento do início deste item. Esse procedimento é repetido até que $B_{SR} \leq B_{D}$.

   **Item 5.5:** Caso todas as solicitações reduzidas contemplem pelo menos uma bolsa por turma e $B_{SR} \leq B_{D}$, as solicitações reduzidas serão atendidas e encerra-se o processo.

   **Item 5.6:** Chamaremos de $N_{D_S}$ o número de departamentos que estejam solicitando 1 (uma) ou mais bolsas.

   **Item 5.7:** Caso $B_{SR} > B_{D}$ e $N_{D_S} > B_{D}$, então as bolsas serão distribuídas seguindo os critérios de desempate especificados no item Critérios de desempate.

   **Item 5.8:** Caso $B_{SR} > B_{D}$ e $N_{D_S} \leq B_{D}$ segue-se o processo a seguir:

   **Item 5.8.1:** Calcula-se o peso do $i$-ésimo departamento ($P_i$) utilizando procedimento idêntico (substituindo-se os Centros pelos Departamentos) ao definido no documento [Relatório da Comissão do Programa de Monitoria da UFSCar](https://drive.google.com/drive/folders/1KD-pdkrKwo-ZX3BRwBnqRgv7GwE4GL8G?usp=share_link) utilizado pela Resolução COG No 316, de 10 de fevereiro de 2020 ou em documento mais atualizado. Aquele procedimento define que:

$$
P_{i} = \frac{Q_{I_i} + Q_{R_i} + Q_{T_i} + Q_{P_i} + N_{T_i}}{P_T}
$$

   Em que: $P_{T} = \sum_{i}(Q_{I_i} + Q_{R_i} + Q_{T_i} + Q_{P_i} + N_{T_i})$ é o fator de normalização; $Q_{I_i}$ é a quantidade de inscrições em atividades no $i$-ésimo departamento nos últimos 5 anos; $Q_{R_i}$ é a quantidade de reprovações no $i$-ésimo departamento nos últimos 5 anos; $Q_{T_i}$ é a quantidade de créditos teóricos no $i$-ésimo departamento nos últimos 5 anos; $Q_{P_i}$ é a quantidade de créditos práticos no $i$-ésimo departamento nos últimos 5 anos; $N_{T_i}$ é a quantidade de turmas ofertadas pelo $i$-ésimo departamento nos últimos 5 anos.

   No caso da resolução COG 316-10/02/20, como últimos 5 anos foram considerados os anos de 2014 a 2018. Além disso, naquela resolução, acordou-se que "para avaliar os números acima, não seriam consideradas as ACIEPEs, atividades de estágio, projeto e monografia, atividades na modalidade EAD e atividades normalmente contempladas pelo Programa de Tutoria". Todas essas decisões também serão adotadas para o cálculo de cada $P_{i}$ do CCA.

   **Item 5.8.2:** Define-se $B_{G_i}$ como sendo a quantidade mínima de bolsas garantidas para o $i$-ésimo departamento, calculado por:

   ```math
   B_{G_i} = P_{i}B_{D}
   ```

   **Item 5.8.3:** O $i$-ésimo departamento que apresentar, simultaneamente, $B_{G_i} < 1$ e $B_{SR_i} \geq 1$ terá a sua quantidade mínima de bolsas garantidas corrigida para $B_{G_i} = 1$.

   **Item 5.8.4:** Define-se $B_{D_i}$ como sendo a quantidade de bolsas disponibilizadas ao $i$-ésimo departamento, em que, consequentemente $B_{D}=\sum_{i}B_{D_i}$.

   **Item 5.8.5:** A distribuição das bolsas entre os departamentos deverá minimizar a diferença quadrática $\sigma^2$ entre o número de bolsas disponibilizadas para o $i$-ésimo departamento e $B_{G_i}$:

   ```math
   \sigma^{2}=\underset{B_{D_i}}{\text{min}} \sum_{i}{\left(B_{D_i} - B_{G_i}\right)^{2}}
   ```

   **Item 5.8.6:** Caso haja mais que um conjunto $B_{D_i}$ com mesmo valor de $\sigma^2$ mínimo, deverão ser aplicados os critérios de desempate especificados no item Critérios de desempate.

   **Item 5.9:** Critérios de desempate: privilegiar-se-á a distribuição de bolsas que favoreça o departamento com maior valor de $Q_{I_i}$, seguido do maior $Q_{R_i}$, maior $Q_{P_i}$, maior $Q_{T_i}$ e maior $N_{T_i}$, nessa ordem, até que sobre uma única distribuição de bolsas. Essa ordem somente deverá ser quebrada se for para satisfazer a condição de que todo departamento tenha pelo menos a solicitação de 1 (uma) bolsa atendida a cada 2 (dois) semestres, conforme o disposto na resolução COG 316-10/02/20.

   **Item 5.10:** Casos omissos serão deliberados pela CBM-CCA.
6. A distribuição das bolsas $B_{D_i}$ entre as solicitações do $i$-ésimo departamento deverão ser feitas a cargo do representante da CBM-CCA do correspondente departamento utilizando critérios que satisfaçam o atendimento às disciplinas represadas e as que tenham pré-requisitos que foram ministrados durante os ENPEs, sendo esses critérios aprovados no respectivo departamento.
