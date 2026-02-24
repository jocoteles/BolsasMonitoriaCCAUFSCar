"""
Copyright 2024 João Teles de Carvalho Neto
MIT License.
"""

from statistics import stdev

solicitacoesDepartamentos = [
    ['DBPVA', 5],
    ['DCNME', 9],
    ['DDR', 3],
    ['DTAiSeR', 2],
    ['DRNPA', 0]   # pediu 0 -> sempre receberá 0 e fica fora do cálculo das razões
]

bolsasDisponiveis = 12
NmelhoresDistribuicoes = 10

# --------------------------------------------------------------------

nomes = [d[0] for d in solicitacoesDepartamentos]
bolsasSolicitadas = [d[1] for d in solicitacoesDepartamentos]
Ndepts = len(solicitacoesDepartamentos)

# Índices de quem participa do rateio (pediu > 0) e de quem fica fixo em 0 (pediu 0)
active_idx = [i for i, s in enumerate(bolsasSolicitadas) if s > 0]
inactive_idx = [i for i, s in enumerate(bolsasSolicitadas) if s == 0]

def compositions(total: int, parts: int):
    """ Gera todas as k-tuplas de inteiros não-negativos que somam 'total'. """
    if parts == 0:
        if total == 0:
            yield []
        return
    if parts == 1:
        yield [total]
    else:
        for x in range(total + 1):
            for rest in compositions(total - x, parts - 1):
                yield [x] + rest

bolsasTodasCombinacoes = []

def avalia_e_registra(alloc_active):
    """Monta vetor completo (com zeros nos inativos), calcula stdev das razões dos ativos e registra."""
    full = [0] * Ndepts
    for idx, val in zip(active_idx, alloc_active):
        full[idx] = val
    # Razões só entre quem pediu > 0 (evita divisão por zero)
    ratios = [full[i] / bolsasSolicitadas[i] for i in active_idx]
    desvio = stdev(ratios) if len(ratios) >= 2 else 0.0
    bolsasTodasCombinacoes.append(full + [desvio])

# Gera combinações apenas para os departamentos ativos; inativos já ficam com 0
for alloc in compositions(bolsasDisponiveis, len(active_idx)):
    avalia_e_registra(alloc)

# Ordena pelo desvio padrão (menor é melhor)
bolsasTodasCombinacoes.sort(key=lambda v: v[-1])

# -------------------------
# Saída tradicional (opcional)
print('\t\t'.join(nomes) + '\t\tStd Dev')
limite = min(NmelhoresDistribuicoes, len(bolsasTodasCombinacoes))
for i in range(limite):
    linha = []
    full = bolsasTodasCombinacoes[i]
    for bolsa, solicitada in zip(full[:-1], bolsasSolicitadas):
        if solicitada > 0:
            linha.append(f"({bolsa}/{solicitada}){(bolsa/solicitada):.3f}")
        else:
            linha.append(f"({bolsa}/0)N/A")
    print('\t'.join(linha) + f'\t{full[-1]:.3f}')

# -------------------------
# Saída da MELHOR combinação em ordem alfabética (detalhada)
print("\nMelhor distribuição (detalhada):\n")

best = bolsasTodasCombinacoes[0]
alocacoes = best[:-1]
desvio = best[-1]

departamentos = list(zip(nomes, alocacoes, bolsasSolicitadas))
departamentos.sort(key=lambda x: x[0])  # ordena alfabeticamente pelo nome

for dep, aloc, solicitada in departamentos:
    if solicitada > 0:
        print(f"{dep}: Vagas ({aloc}/{solicitada}) std={desvio:.3f}")
    else:
        print(f"{dep}: Vagas ({aloc}/0) std={desvio:.3f}")

# -------------------------
# Saída simplificada (apenas vagas recebidas)
print("\nMelhor distribuição (simplificada):\n")
for dep, aloc, solicitada in departamentos:
    print(f"{dep}: {aloc}")
