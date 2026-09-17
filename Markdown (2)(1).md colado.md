# PLANO DE CONSTRUÇÃO — PROJETO NOVO DO CÉREBRO AUTORAL

## REGRA ZERO

Este é um projeto completamente novo.

Serão utilizados:

- novo repositório GitHub;
- nova conta/projeto Supabase;
- nova conta/projeto Vercel;
- nova configuração OpenAI;
- novo banco de dados;
- novas migrations;
- nova arquitetura;
- novo histórico de desenvolvimento.

Nenhum banco ou deploy anterior será migrado automaticamente.

Nenhuma tabela anterior será considerada parte deste sistema.

Nenhuma Edge Function anterior será reaproveitada diretamente.

O aplicativo anterior serve apenas como referência histórica de produto e aprendizado.

---

# 1. OBJETIVO

Construir do zero um aplicativo cujo principal ativo seja o:

# CÉREBRO AUTORAL

O sistema deverá aprender, a partir das obras do usuário:

- metodologia de pensamento;
- metodologia de interpretação;
- metodologia de associação;
- metodologia argumentativa;
- metodologia de escrita;
- arquitetura narrativa;
- arquitetura de parágrafo;
- formas de abertura;
- formas de transição;
- formas de conclusão;
- recursos retóricos;
- identidade linguística;
- relação entre experiências e conceitos;
- metodologia de revisão;
- evolução intelectual.

A finalidade é utilizar esse Cérebro para construir novas reflexões personalizadas.

---

# 2. MACROFLUXO

```text
BIBLIOTECA
        ↓
PROCESSAMENTO INTELIGENTE
        ↓
DOCUMENTOS PROCESSADOS
        ↓
ANÁLISE TRANSVERSAL
        ↓
CÉREBRO AUTORAL
        ↓
RECUPERAÇÃO CONTEXTUAL
        ↓
MOTOR DE REFLEXÕES
        ↓
NOVA REFLEXÃO
        ↓
REVISÃO DO AUTOR
        ↓
APRENDIZADO CONTROLADO

```

---

# 3. PRIMEIRA TAREFA DO AGENTE

Antes de criar código, conectar as três novas plataformas:

## GitHub

Conectar à nova conta GitHub.

Criar ou identificar o novo repositório oficial.

Esse será o único repositório canônico.

---

## Supabase

Conectar à nova conta Supabase.

Criar um projeto Supabase exclusivamente para o novo aplicativo.

Nenhum projeto Supabase antigo deverá ser usado.

---

## Vercel

Conectar à nova conta Vercel.

Criar um projeto Vercel exclusivamente para este aplicativo.

Conectá-lo ao novo repositório GitHub.

---

# 4. RESULTADO DA CONFIGURAÇÃO INICIAL

Ao terminar a Fundação, deve existir exatamente:

```text
1 REPOSITÓRIO GITHUB
        │
        ▼
1 PROJETO VERCEL
        │
        ▼
1 APLICAÇÃO
        │
        ▼
1 PROJETO SUPABASE

```

E não múltiplas versões concorrentes.

---

# 5. STACK RECOMENDADA

## Frontend e servidor

```text
Next.js
React
TypeScript

```

## Banco

```text
Supabase PostgreSQL

```

## Autenticação

```text
Supabase Auth

```

## Arquivos

```text
Supabase Storage

```

## Recuperação vetorial

```text
pgvector

```

## Pesquisa lexical

```text
PostgreSQL Full Text Search

```

## IA

```text
OpenAI API

```

## Hospedagem

```text
Vercel

```

## Código

```text
GitHub

```

---

# 6. O PROJETO ANTIGO

Pode ser estudado apenas para responder:

```text
O que funcionou?

O que deu problema?

Quais bugs já descobrimos?

Quais padrões de segurança deram certo?

Quais decisões de interface foram boas?

Quais problemas de concorrência já ocorreram?

Quais erros de prompt devemos evitar?

```

Mas nunca:

```text
Copiar todo o banco antigo.

Importar migrations antigas.

Transportar automaticamente as Edge Functions.

Reproduzir arquitetura antiga sem revisão.

```

---

# 7. FASE 0 — FUNDAÇÃO

Criar primeiro:

```text
novo GitHub
novo Supabase
novo Vercel

```

Depois:

```text
Next.js
TypeScript
lint
formatação
testes
CI
variáveis de ambiente
Supabase local
estrutura de migrations

```

---

# 8. GITHUB

Criar estrutura inicial:

```text
src/
supabase/
docs/
prompts/
taxonomia/
tests/

```

Branch principal:

```text
main

```

Desenvolvimento:

```text
feature/fundacao
feature/biblioteca
feature/processamento
feature/taxonomia
feature/cerebro
feature/reflexoes

```

Nenhuma mudança estrutural importante diretamente em `main`.

---

# 9. SUPABASE

O banco deverá nascer já com a nova taxonomia.

Schemas desejados:

```text
biblioteca
processamento
taxonomia
cerebro_autoral
reflexoes
auditoria
sistema

```

Schemas próprios do Supabase permanecem:

```text
auth
storage

```

---

# 10. PRIMEIRA MIGRATION

A primeira migration deverá criar somente a Fundação.

Não tentar criar todo o aplicativo de uma vez.

Ela deverá incluir:

```text
extensões necessárias

schemas

funções utilitárias

triggers comuns

estruturas fundamentais

RLS básico

comments SQL

```

Depois migrations independentes por domínio.

---

# 11. SEQUÊNCIA DAS MIGRATIONS

```text
0001_fundacao

0002_sistema

0003_taxonomia

0004_biblioteca

0005_processamento

0006_cerebro_autoral

0007_reflexoes

0008_auditoria

0009_indices

0010_policies_rls

```

A divisão exata pode ser refinada pelo agente.

---

# 12. AMBIENTES

Desde o início:

```text
LOCAL

PREVIEW

PRODUCTION

```

Nunca desenvolver diretamente sobre produção.

---

# 13. VERCEL

Configurar:

```text
GitHub → Vercel

```

Com:

```text
main
→ produção

Pull Request
→ Preview

```

Cada feature deverá possuir Preview antes do merge.

---

# 14. SUPABASE PREVIEW

Investigar e, se disponível no plano utilizado, configurar Supabase Branching.

Objetivo:

```text
Pull Request
       │
       ├── Vercel Preview
       │
       └── Supabase Preview

```

Assim migrations podem ser testadas sem tocar produção.

---

# 15. DICIONÁRIO MESTRE

Utilizar como ponto de partida oficial:

# DICIONÁRIO MESTRE DE DADOS E TAXONOMIA v1.0

Ele deverá ser revisado pelo agente antes das migrations.

Não alterar nomes de forma arbitrária.

Qualquer mudança importante deve atualizar primeiro o dicionário.

---

# 16. BIBLIOTECA

Primeiro domínio funcional.

O usuário envia:

```text
livros
textos
cartas
reflexões
documentos

```

O original é preservado.

---

# 17. CLASSIFICAÇÃO DE AUTORIA

Cada documento deve possuir:

```text
autoral

externo

```

E separadamente:

```text
autoral_prioritaria

externa_referencia

externa_influencia

excluida_cerebro

```

---

# 18. REGRA PRINCIPAL DO CÉREBRO

```text
AUTORAL
→ pode alimentar o Núcleo Autoral

EXTERNO
→ não alimenta automaticamente

```

---

# 19. INFLUÊNCIA EXTERNA DELIBERADA

O usuário pode escolher:

# INCORPORAR METODOLOGIA DESTE AUTOR

Nesse caso poderá selecionar:

```text
metodologia de pensamento

argumentação

escrita

arquitetura narrativa

interpretação

recursos retóricos

```

A origem externa permanece registrada permanentemente.

---

# 20. DOCUMENTO PROCESSADO

Um livro somente vira Documento Processado depois de completar:

```text
validação
extração
normalização
estrutura
segmentação
sínteses
análise de IA
taxonomia
relações
embeddings
indexação
validação final

```

Nenhum processamento parcial alimenta o Cérebro.

---

# 21. INTELIGÊNCIA ARTIFICIAL

A IA deverá atuar transversalmente.

Separar motores lógicos:

```text
motor_documental

motor_taxonomico

motor_autoral

motor_recuperacao

motor_planejamento

motor_redacao

motor_auditoria

motor_aprendizado

```

---

# 22. MOTOR DOCUMENTAL

Responsável por compreender individualmente cada obra.

Extrair:

```text
temas
conceitos
ideias
teses
argumentos
valores
perguntas
tensões
histórias
experiências
metáforas
relações
contradições
mudanças
estruturas narrativas
estruturas argumentativas
padrões linguísticos

```

---

# 23. MOTOR TAXONÔMICO

Antes de criar um conceito novo:

```text
procurar conceito existente

procurar sinônimo

procurar termo alternativo

procurar conceito relacionado

só então propor novo conceito

```

---

# 24. MOTOR AUTORAL

Analisa o conjunto dos Documentos Processados autorais.

Pergunta:

```text
O que se repete?

Como o raciocínio começa?

Como progride?

Como associa?

Como argumenta?

Como transforma experiência em conceito?

Como escreve?

Como conclui?

O que mudou ao longo do tempo?

```

---

# 25. CÉREBRO AUTORAL

O Cérebro não é texto livre.

Deverá possuir entidades estruturadas:

```text
dimensões

características

evidências

exceções

metodologias

regras operacionais

anti-regras

transições metodológicas

versões

```

---

# 26. CÉREBRO ATIVO

```text
Núcleo Autoral
+
Influências Externas explicitamente autorizadas
=
Cérebro Ativo

```

---

# 27. REFLEXÕES

Depois do Cérebro funcional:

```text
reflexão externa
+
comentário atual
+
documentos pertinentes
+
Cérebro pertinente
+
influências autorizadas
=
contexto de trabalho

```

---

# 28. GERAÇÃO

A geração deverá possuir pelo menos:

```text
análise

recuperação

conflitos

plano

redação

auditoria

revisão humana

```

Nunca gerar diretamente o texto final depois de uma única chamada simples.

---

# 29. APRENDIZADO

Comparar:

```text
texto da IA

versus

texto final do autor

```

Detectar alterações.

Mas transformar alterações somente em:

```text
propostas de aprendizado

```

Nunca modificar silenciosamente o Cérebro.

---

# 30. OPENAI

Centralizar modelos.

Exemplo:

```text
MODELO_EXTRACAO

MODELO_ANALISE

MODELO_CEREBRO

MODELO_REDACAO

MODELO_AUDITORIA

MODELO_EMBEDDING

```

Nenhum ID de modelo espalhado pelo código.

---

# 31. OUTPUTS DA IA

Para qualquer informação que vai para o banco:

```text
OpenAI
↓
Structured Output
↓
JSON Schema
↓
Zod
↓
validação
↓
persistência

```

---

# 32. PROMPTS

Versionar no GitHub:

```text
prompts/
├── documental/
├── taxonomia/
├── cerebro/
├── recuperacao/
├── reflexoes/
└── auditoria/

```

---

# 33. WORKFLOWS

Livro grande deve ser processado com sistema durável.

Cada etapa deve suportar:

```text
retry
resume
idempotência
observabilidade

```

---

# 34. IDEMPOTÊNCIA

Toda etapa cara:

```text
obra
+
versão
+
pipeline
+
etapa

```

deve possuir chave única.

Uma tentativa repetida não pode duplicar cobrança nem dados.

---

# 35. SEGURANÇA

Desde a primeira migration:

```text
RLS

Storage privado

segredos somente servidor

usuário isolado

service role nunca no browser

dados externos tratados como dados

proteção contra prompt injection

```

---

# 36. OBSERVABILIDADE

Registrar:

```text
modelo

prompt

taxonomia

pipeline

tokens

latência

custo

tentativas

erro

resultado

```

---

# 37. TESTES

Construir desde o início:

```text
unitários

integração

SQL

RLS

migrations

IA

taxonomia

retrieval

E2E

```

---

# 38. ORDEM DE CONSTRUÇÃO

## Fase 0

Fundação.

## Fase 1

Biblioteca.

## Fase 2

Pipeline documental.

## Fase 3

Documento Processado.

## Fase 4

Taxonomia.

## Fase 5

Busca híbrida.

## Fase 6

Cérebro Autoral.

## Fase 7

Influências Externas.

## Fase 8

Recuperação contextual.

## Fase 9

Motor de Reflexões.

## Fase 10

Aprendizado por revisão.

## Fase 11

Avaliações e otimização.

---

# 39. PRIMEIRA AÇÃO DO AGENTE

Quando receber acesso às novas contas:

### Passo 1

Confirmar conexão GitHub.

### Passo 2

Confirmar conexão Supabase.

### Passo 3

Confirmar conexão Vercel.

### Passo 4

Criar/inventariar o novo repositório.

### Passo 5

Criar/inventariar o novo Supabase.

### Passo 6

Criar/inventariar o novo projeto Vercel.

### Passo 7

Conectar:

```text
GitHub
   ↓
Vercel

Aplicação
   ↓
Supabase

```

### Passo 8

Criar ambiente local.

### Passo 9

Configurar CI.

### Passo 10

Só então começar migrations.

---

# 40. O QUE O AGENTE NÃO PRECISA FAZER

Não precisa:

```text
reconciliar o Supabase antigo

migrar o banco antigo

reconciliar a Vercel antiga

descobrir qual repositório antigo é oficial

manter compatibilidade com banco antigo

preservar APIs antigas

preservar migrations antigas

```

Porque:

# ESTE É UM SISTEMA NOVO.

---

# 41. O QUE ELE DEVE APROVEITAR DO PROJETO ANTIGO

Apenas conhecimento.

Principalmente:

```text
problemas de concorrência

necessidade de idempotência

RLS

proveniência

versionamento

revisão humana

separação entre autoria e referência externa

problemas de prompts conflitantes

necessidade de validação determinística

importância de observabilidade

```

---

# 42. PRINCÍPIO FINAL

O agente deverá pensar assim:

```text
NÃO ESTOU MIGRANDO O APLICATIVO ANTIGO.

ESTOU CONSTRUINDO A NOVA VERSÃO CORRETA DO PRODUTO.

```

A nova infraestrutura nasce limpa.

O projeto antigo é apenas uma fonte de aprendizado.

A nova construção terá:

```text
1 GitHub
1 Supabase
1 Vercel
1 arquitetura
1 taxonomia
1 Cérebro Autoral

```

Todo o restante será construído progressivamente sobre essa Fundação.