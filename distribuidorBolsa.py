"""
Copyright 2024 João Teles de Carvalho Neto
MIT License.
"""

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
