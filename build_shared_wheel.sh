#!/bin/bash

# Script para build do módulo shared como wheel
# Garante criação da pasta dist e limpeza completa de arquivos temporários

set -e # Sai em caso de erro

# Define cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando build do módulo shared...${NC}"

# Define diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/src"
DIST_DIR="${SRC_DIR}/dist"

# Navega para o diretório src
cd "${SRC_DIR}"

# Função de limpeza que será executada ao final (sucesso ou erro)
cleanup() {
	echo -e "${YELLOW}Limpando arquivos temporários...${NC}"

	# Remove diretórios temporários do build
	rm -rf build/
	rm -rf *.egg-info
	rm -rf shared.egg-info

	# Remove arquivos __pycache__ e .pyc
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true

	# Remove diretórios .pytest_cache se existirem
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

	echo -e "${GREEN}Limpeza concluída!${NC}"
}

# Registra a função de limpeza para ser executada ao sair
trap cleanup EXIT

# Cria o diretório dist se não existir
echo -e "${YELLOW}Criando diretório dist...${NC}"
mkdir -p "${DIST_DIR}"

# Remove wheels antigos do dist
echo -e "${YELLOW}Removendo wheels antigos...${NC}"
rm -f "${DIST_DIR}"/*.whl

# Verifica se o setup.py existe
if [ ! -f "setup.py" ]; then
	echo -e "${RED}Erro: setup.py não encontrado em ${SRC_DIR}${NC}"
	exit 1
fi

# Instala/atualiza wheel se necessário
echo -e "${YELLOW}Verificando dependências de build...${NC}"
pip install --quiet --upgrade pip wheel setuptools

# Build do wheel
echo -e "${YELLOW}Construindo wheel...${NC}"
python setup.py bdist_wheel --dist-dir="${DIST_DIR}"

# Verifica se o wheel foi criado
WHEEL_COUNT=$(ls -1 "${DIST_DIR}"/*.whl 2>/dev/null | wc -l)
if [ "${WHEEL_COUNT}" -eq 0 ]; then
	echo -e "${RED}Erro: Nenhum arquivo wheel foi gerado!${NC}"
	exit 1
fi

echo -e "${GREEN}Build concluído com sucesso!${NC}"
echo -e "${GREEN}Wheel gerado em: ${DIST_DIR}${NC}"
ls -lh "${DIST_DIR}"/*.whl

# A limpeza será executada automaticamente pelo trap EXIT
