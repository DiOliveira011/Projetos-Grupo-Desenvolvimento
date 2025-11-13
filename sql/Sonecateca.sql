-- ============================================================================
-- SONECATECA - Biblioteca de Funções SQL Reutilizáveis
-- ============================================================================
-- Descrição: Biblioteca de funções úteis para uso em diversos projetos SQL
-- Autor: Grupo de Desenvolvimento
-- Data de Criação: 2025-11-13
-- Versão: 1.0.0
--
-- Como usar: Execute este arquivo para importar todas as funções.
--           Após isso, poderá usar qualquer função definida aqui em suas queries.
-- ============================================================================

-- ============================================================================
-- SEÇÃO 1: FUNÇÕES DE FORMATAÇÃO E CONVERSÃO
-- ============================================================================

-- Função para capitalizar primeira letra de uma string
CREATE OR REPLACE FUNCTION f_capitalizar(p_texto VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    IF p_texto IS NULL OR p_texto = '' THEN
        RETURN p_texto;
    END IF;
    RETURN UPPER(SUBSTRING(p_texto, 1, 1)) || LOWER(SUBSTRING(p_texto, 2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para remover espaços extras
CREATE OR REPLACE FUNCTION f_limpar_espacos(p_texto VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN TRIM(REGEXP_REPLACE(p_texto, '\s+', ' ', 'g'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para converter valores booleanos em PT-BR
CREATE OR REPLACE FUNCTION f_booleano_pt(p_valor BOOLEAN)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE WHEN p_valor THEN 'Sim' ELSE 'Não' END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 2: FUNÇÕES DE VALIDAÇÃO
-- ============================================================================

-- Função para validar email
CREATE OR REPLACE FUNCTION f_validar_email(p_email VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para validar CPF (simples)
CREATE OR REPLACE FUNCTION f_validar_cpf(p_cpf VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- Remove caracteres especiais
    p_cpf := REGEXP_REPLACE(p_cpf, '[^0-9]', '', 'g');
    
    -- Valida comprimento
    IF LENGTH(p_cpf) != 11 THEN
        RETURN FALSE;
    END IF;
    
    -- Valida sequências iguais
    IF p_cpf IN ('00000000000', '11111111111', '22222222222', '33333333333',
                  '44444444444', '55555555555', '66666666666', '77777777777',
                  '88888888888', '99999999999') THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para validar telefone
CREATE OR REPLACE FUNCTION f_validar_telefone(p_telefone VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    p_telefone := REGEXP_REPLACE(p_telefone, '[^0-9]', '', 'g');
    RETURN LENGTH(p_telefone) >= 10 AND LENGTH(p_telefone) <= 11;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 3: FUNÇÕES DE DATA E HORA
-- ============================================================================

-- Função para obter a idade em anos
CREATE OR REPLACE FUNCTION f_calcular_idade(p_data_nascimento DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_data_nascimento));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para obter nome do dia da semana em PT-BR
CREATE OR REPLACE FUNCTION f_dia_semana_pt(p_data DATE)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE EXTRACT(DOW FROM p_data)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para obter nome do mês em PT-BR
CREATE OR REPLACE FUNCTION f_mes_pt(p_mes INTEGER)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE p_mes
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 4: FUNÇÕES MATEMÁTICAS
-- ============================================================================

-- Função para arredondar com precisão
CREATE OR REPLACE FUNCTION f_arredondar(p_valor NUMERIC, p_casas_decimais INTEGER DEFAULT 2)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_valor, p_casas_decimais);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para calcular percentual
CREATE OR REPLACE FUNCTION f_percentual(p_parte NUMERIC, p_total NUMERIC, p_casas_decimais INTEGER DEFAULT 2)
RETURNS NUMERIC AS $$
BEGIN
    IF p_total = 0 THEN
        RETURN 0;
    END IF;
    RETURN ROUND((p_parte / p_total) * 100, p_casas_decimais);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para calcular média
CREATE OR REPLACE FUNCTION f_media(VARIADIC p_valores NUMERIC[])
RETURNS NUMERIC AS $$
DECLARE
    v_soma NUMERIC := 0;
    v_count INTEGER := 0;
BEGIN
    FOREACH p_valores[1:] LOOP
        IF p_valores[1] IS NOT NULL THEN
            v_soma := v_soma + p_valores[1];
            v_count := v_count + 1;
        END IF;
    END LOOP;
    
    IF v_count = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN v_soma / v_count;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 5: FUNÇÕES DE AGREGAÇÃO CUSTOMIZADAS
-- ============================================================================

-- Função para concatenar valores com separador
CREATE OR REPLACE FUNCTION f_concatenar(p_valores TEXT[], p_separador VARCHAR DEFAULT ', ')
RETURNS TEXT AS $$
BEGIN
    RETURN ARRAY_TO_STRING(p_valores, p_separador);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 6: FUNÇÕES DE TEXTO
-- ============================================================================

-- Função para inverter uma string
CREATE OR REPLACE FUNCTION f_inverter(p_texto VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN REVERSE(p_texto);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para contar palavras
CREATE OR REPLACE FUNCTION f_contar_palavras(p_texto VARCHAR)
RETURNS INTEGER AS $$
BEGIN
    RETURN ARRAY_LENGTH(STRING_TO_ARRAY(TRIM(p_texto), ' '), 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para extrair números de uma string
CREATE OR REPLACE FUNCTION f_extrair_numeros(p_texto VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN REGEXP_REPLACE(p_texto, '[^0-9]', '', 'g');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- SEÇÃO 7: FUNÇÕES AUXILIARES
-- ============================================================================

-- Função para gerar UUID
CREATE OR REPLACE FUNCTION f_gerar_uuid()
RETURNS UUID AS $$
BEGIN
    RETURN GEN_RANDOM_UUID();
END;
$$ LANGUAGE plpgsql;

-- Função para obter versão do banco
CREATE OR REPLACE FUNCTION f_versao_banco()
RETURNS VARCHAR AS $$
BEGIN
    RETURN VERSION();
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para obter timestamp atual com timezone
CREATE OR REPLACE FUNCTION f_agora()
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
    RETURN NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEÇÃO 8: ÍNDICES ÚTEIS (DESCOMENTAR CONFORME NECESSÁRIO)
-- ============================================================================
-- CREATE INDEX idx_funcoes_sonecateca ON pg_proc(proname) WHERE prokind = 'f';

-- ============================================================================
-- FIM DA BIBLIOTECA SONECATECA
-- ============================================================================
-- Histórico de Versões:
-- v1.0.0 (2025-11-13): Criação inicial com funções básicas
--
-- Notas:
-- - Todas as funções são IMMUTABLE (exceto as que precisam de timestamp)
-- - Use f_* como prefixo para distinguir funções da biblioteca
-- - Adicione novas funções conforme necessário
-- - Documente sempre o propósito de cada função
-- ============================================================================
