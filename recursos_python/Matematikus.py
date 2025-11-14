# ==========================================================
# 🧠 Biblioteca: Matematikus.py
# Autor: "Siriguela, o travado"
# Descrição: Coleção de funções utilitárias para resolver problemas da sua área de negócio.
# ==========================================================

# Bibliotecas de suporte
import math


# 1. Calculadora de tamanho amostral
#  Material de apoio: https://pt.surveymonkey.com/mp/sample-size-calculator/

def tamanho_amostra_proporcao(p, erro, confianca=0.95, N=None):
    """
    p: proporção esperada (0-1)
    erro: margem de erro (ex.: 0.05)
    confianca: nível de confiança (default 95%)
    N: população (opcional; se None, assume população infinita)
    """
    # Z para confiança
    z_map = {0.90: 1.645, 0.95: 1.96, 0.99: 2.576} # Esse dicionário é uma tabela com os níveis de confiança
    Z = z_map.get(confianca, 1.96) # O valor mais utilizado. 95% de confiança.
    
    # Calculo
    n0 = (Z**2 * p * (1 - p)) / (erro**2)

    # Correção para população finita
    # Essa correção evita absurdos do tipo: “Devo amostrar 300 pessoas de uma população de 250”.
    if N:
        n = (N * n0) / (n0 + N - 1)
        return math.ceil(n) # uso da função .ceil() para arredondar para cima.
    else:
        return math.ceil(n0)

# Exemplo de uso:
n = tamanho_amostra_proporcao(p=0.5, erro=0.05, confianca=0.95, N=100000)
print(n)
