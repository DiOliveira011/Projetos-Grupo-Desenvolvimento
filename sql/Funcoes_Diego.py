# ==========================================================
# 🧠 Biblioteca: funcoes_soneca.py
# Autor: Diego "Soneca" Oliveira Coelho
# Descrição: Coleção de funções utilitárias para automação,
# auditoria de dados, execução SQL e manipulação de planilhas.
# ==========================================================

import os
import sys
import pandas as pd
import threading
import pyodbc
from tqdm import tqdm
from openpyxl import Workbook
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.wait import WebDriverWait


# ==========================================================
# 🔹 1. UTILITÁRIOS GERAIS DE PLANILHA E ARQUIVOS
# ==========================================================
def criar_planilha_auditoria():
    """Cria uma nova planilha de auditoria com cabeçalhos padrão"""
    audit_filename = f"auditoria_PERFIL_{datetime.now().strftime('%d-%m-%Y_%H-%M-%S')}.xlsx"
    audit_workbook = Workbook()
    ws = audit_workbook.active
    cabecalhos = [
        'ID', 'SENSOR A1', 'SENSOR A2', 'SENSOR R1 ENTRADA', 'SENSOR R2 ENTRADA',
        'SENSOR R1 SAIDA', 'SENSOR R2 SAIDA', 'PERFIL', 'MDFE', 'PERFILOMETRIA',
        'STATUS VALIDAÇÃO', 'METODO DE VALIDAÇÃO', 'CATEGORIA A SER VALIDADA',
        'OCR', 'PLACA', 'TAG', 'OSA', 'LOCAL', 'VALOR REJEITADO', 'VALOR VALIDADO'
    ]
    for col, nome in enumerate(cabecalhos, start=1):
        ws.cell(row=1, column=col, value=nome)
    return audit_filename, audit_workbook, ws


def ler_planilha_entrada(file_name):
    """Lê uma planilha Excel e retorna a lista de IDs"""
    try:
        book = pd.read_excel(f"{file_name}.xlsx")
        return book.iloc[:, 0].dropna().astype(str).tolist()
    except Exception as e:
        print(f"❌ Erro ao ler a planilha {file_name}.xlsx: {e}")
        sys.exit(1)


def dividir_planilha(input_path: str, chunk_size: int) -> int:
    """Divide uma planilha Excel em partes menores e salva os pedaços"""
    df = pd.read_excel(input_path)
    num_chunks = (len(df) // chunk_size) + 1
    for i in range(num_chunks):
        start = i * chunk_size
        end = (i + 1) * chunk_size
        df_part = df.iloc[start:end]
        output_name = f"Script_div_{i+1}.xlsx"
        df_part.to_excel(output_name, index=False)
    return num_chunks


# ==========================================================
# 🌐 2. AUTOMATIZAÇÃO COM SELENIUM
# ==========================================================
def abrir_navegador():
    """Abre o navegador Chrome com opções padrão"""
    options = Options()
    options.add_experimental_option("detach", True)
    browser = webdriver.Chrome(options=options)
    browser.maximize_window()
    wait = WebDriverWait(browser, 60)
    return browser, wait


def login_toll(browser, usuario, senha):
    """Realiza login no sistema Toll (exemplo genérico)"""
    browser.get("https://sistema.toll.com.br")
    browser.find_element("id", "username").send_keys(usuario)
    browser.find_element("id", "password").send_keys(senha)
    browser.find_element("id", "btnLogin").click()
    print("✅ Login efetuado com sucesso!")


# ==========================================================
# 🧱 3. EXECUÇÃO DE CONSULTAS SQL EM LOTES
# ==========================================================
def executar_consulta_em_blocos(
    connection_string: str,
    query_template: str,
    lista_valores: list,
    coluna_excel: str,
    lote_tamanho: int = 1000,
    caminho_saida: str = "resultado.xlsx"
):
    """
    Executa uma consulta SQL em blocos (para listas grandes de parâmetros)
    e salva o resultado em um único Excel.
    """
    conn = pyodbc.connect(connection_string)
    resultados = []

    lotes = [lista_valores[i:i+lote_tamanho] for i in range(0, len(lista_valores), lote_tamanho)]
    for i, lote in enumerate(tqdm(lotes, desc="Rodando lotes SQL"), start=1):
        valores_formatados = ",".join(f"'{v}'" for v in lote)
        query = query_template.format(valores=valores_formatados)
        df = pd.read_sql(query, conn)
        resultados.append(df)

    final = pd.concat(resultados, ignore_index=True)
    final.to_excel(caminho_saida, index=False)
    print(f"✅ Consulta finalizada e salva em: {caminho_saida}")
    return final


# ==========================================================
# ⚙️ 4. EXECUÇÃO PARALELA DE SCRIPTS AUTOMÁTICOS
# ==========================================================
def mapear_codigo_script(codigo: str) -> str:
    """Retorna o nome do script automático com base no código informado."""
    codigos = {
        '1': 'Val_base_perfil_auto',
        '2': 'Val_base_perfil_auto_EM',
        '3': 'Val_base_TAG_auto',
        '4': 'LISTA_OCR_AUTO',
        '5': 'Valida_lista_placa_auto',
        '6': 'Evasão_auto',
        '7': 'Auxilio_Planilha_pago_auto',
        '8': 'CONFERE_base_VALIDADOR_auto',
        '9': 'teste_PERFILSENTIDO_OLHASENSOR',
        '10': 'Reenvio_pagos_sem_aceite_auto',
        '11': 'Val_base_perfil_auto_pago',
        '12': 'Val_base_COB_auto_pago',
        '13': 'Validação_SmartFlow_auto',
        '14': 'Clica_FIC_02_auto',
    }
    return codigos.get(codigo, 'codigo_invalido')


def executar_parte(part_number: int, input_file: str, script_path: str, semaphore: threading.Semaphore):
    """Executa um script Python em uma thread."""
    try:
        output_file = f"Script_div_{part_number}.xlsx"
        print(f"➡️ Executando {script_path} para o arquivo {output_file}")
        os.system(f"python {script_path} {output_file} {input_file}")
    except Exception as e:
        print(f"⚠️ Erro na parte {part_number}: {e}")
    finally:
        semaphore.release()


def processar_arquivo_em_partes(
    file_name: str,
    file_code: str,
    thread_count: int,
    chunk_size: int,
    pasta_arquivos="./Arquivos",
    pasta_scripts="./Automaticos"
):
    """
    Divide um arquivo Excel em partes e executa scripts correspondentes em paralelo.
    """
    input_file = f"{pasta_arquivos}/{file_name}.xlsx"
    script_path = f"{pasta_scripts}/{mapear_codigo_script(file_code)}.py"

    print(f"📂 Processando '{file_name}.xlsx' com script '{script_path}'")
    print(f"🧩 Dividindo em blocos de {chunk_size} linhas e até {thread_count} threads simultâneas...\n")

    num_chunks = dividir_planilha(input_file, chunk_size)
    semaphore = threading.Semaphore(thread_count)
    threads = []

    for i in range(1, num_chunks + 1):
        semaphore.acquire()
        t = threading.Thread(target=executar_parte, args=(i, input_file, script_path, semaphore))
        t.start()
        threads.append(t)

    for t in threads:
        t.join()

    print("✅ Processamento concluído com sucesso!")
