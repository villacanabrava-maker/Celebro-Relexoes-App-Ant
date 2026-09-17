-- ==========================================
-- File: 20260916183543_0001_fundacao.sql
-- ==========================================

-- 0001_fundacao
-- Fundação mínima e reversível do Cérebro Autoral.
-- Não cria tabelas de domínio.

begin;

-- Extensões necessárias para busca e recuperação futura.
create extension if not exists vector with schema extensions;
create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- Schemas canônicos da aplicação.
create schema if not exists sistema;
create schema if not exists taxonomia;
create schema if not exists biblioteca;
create schema if not exists processamento;
create schema if not exists cerebro_autoral;
create schema if not exists reflexoes;
create schema if not exists auditoria;
create schema if not exists aplicacao;

comment on schema sistema is 'Configuração, versões e metadados técnicos do sistema.';
comment on schema taxonomia is 'Vocabulários intelectuais versionados, conceitos, termos e relações.';
comment on schema biblioteca is 'Acervo original, obras e versões preservadas.';
comment on schema processamento is 'Representações processadas, fragmentos, evidências, vetores e relações.';
comment on schema cerebro_autoral is 'Versões, dimensões, características, metodologias, regras e evidências autorais.';
comment on schema reflexoes is 'Fluxo de criação, contexto, planos, versões, revisões e incorporações de reflexões.';
comment on schema auditoria is 'Execuções, eventos, observabilidade, custo e proveniência técnica.';
comment on schema aplicacao is 'Camada controlada de views e RPCs expostas à aplicação quando necessário.';

-- Negação explícita por padrão. Permissões serão concedidas por migration
-- específica, apenas quando existirem tabelas/views e políticas testadas.
revoke all on schema sistema from public, anon, authenticated;
revoke all on schema taxonomia from public, anon, authenticated;
revoke all on schema biblioteca from public, anon, authenticated;
revoke all on schema processamento from public, anon, authenticated;
revoke all on schema cerebro_autoral from public, anon, authenticated;
revoke all on schema reflexoes from public, anon, authenticated;
revoke all on schema auditoria from public, anon, authenticated;
revoke all on schema aplicacao from public, anon, authenticated;

commit;


-- ==========================================
-- File: 20260916184023_0002_sistema.sql
-- ==========================================

-- 0002_sistema
-- Catálogo técnico de modelos, prompts, pipelines e preferências não secretas.
-- Fonte funcional: Dicionário Mestre de Dados e Taxonomia v1.0, seção 9.

begin;

create table if not exists sistema.modelos_ia (
  id uuid primary key default gen_random_uuid(),
  provedor text not null,
  identificador_modelo text not null,
  apelido text,
  finalidade text not null,
  dimensoes_embedding integer,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  constraint modelos_ia_finalidade_check check (
    finalidade in ('extracao', 'analise', 'taxonomia', 'cerebro', 'redacao', 'auditoria', 'embedding')
  ),
  constraint modelos_ia_dimensoes_embedding_check check (
    dimensoes_embedding is null or dimensoes_embedding > 0
  ),
  constraint modelos_ia_identidade_unica unique (provedor, identificador_modelo, finalidade)
);

comment on table sistema.modelos_ia is
  'Catálogo técnico de modelos disponíveis. Não contém chaves de API nem outros segredos.';
comment on column sistema.modelos_ia.finalidade is
  'Função lógica do modelo: extracao, analise, taxonomia, cerebro, redacao, auditoria ou embedding.';
comment on column sistema.modelos_ia.dimensoes_embedding is
  'Dimensionalidade quando a finalidade for embedding. Nula para modelos não vetoriais.';

create table if not exists sistema.prompts (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  nome text not null,
  finalidade text not null,
  ativo boolean not null default true
);

comment on table sistema.prompts is
  'Identidade lógica e estável de cada prompt. O conteúdo vive em versões imutáveis e também é versionado no GitHub.';

create table if not exists sistema.versoes_prompts (
  id uuid primary key default gen_random_uuid(),
  prompt_id uuid not null references sistema.prompts(id) on delete restrict,
  numero_versao integer not null,
  conteudo text not null,
  schema_saida jsonb,
  hash_conteudo text not null,
  criado_em timestamptz not null default now(),
  ativado_em timestamptz,
  constraint versoes_prompts_numero_check check (numero_versao >= 1),
  constraint versoes_prompts_numero_unico unique (prompt_id, numero_versao),
  constraint versoes_prompts_hash_unico unique (prompt_id, hash_conteudo)
);

comment on table sistema.versoes_prompts is
  'Versões operacionais imutáveis de prompts, incluindo schema de saída quando aplicável e hash para rastreabilidade.';
comment on column sistema.versoes_prompts.schema_saida is
  'JSON Schema esperado quando o prompt produz dado estruturado; pode ser nulo quando não se aplica.';

create table if not exists sistema.versoes_pipeline (
  id uuid primary key default gen_random_uuid(),
  numero_versao text not null unique,
  descricao text,
  hash_configuracao text not null unique,
  estado text not null default 'rascunho',
  criado_em timestamptz not null default now(),
  ativado_em timestamptz,
  constraint versoes_pipeline_estado_check check (
    estado in ('rascunho', 'ativa', 'arquivada', 'invalidada')
  )
);

comment on table sistema.versoes_pipeline is
  'Versões rastreáveis da configuração do pipeline documental. numero_versao é texto para permitir versionamento semântico como 1.0 ou 2.1.';
comment on column sistema.versoes_pipeline.estado is
  'Estado técnico definido nesta implementação: rascunho, ativa, arquivada ou invalidada.';

create table if not exists sistema.configuracoes_usuario (
  usuario_id uuid primary key references auth.users(id) on delete cascade,
  idioma_preferencial text not null default 'pt-BR',
  comportamento_recuperacao text not null default 'adaptativo',
  nivel_detalhamento text not null default 'equilibrado',
  exigir_aprovacao_manual boolean not null default true,
  preferencias_visuais jsonb not null default '{}'::jsonb,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint configuracoes_usuario_preferencias_visuais_objeto_check check (
    jsonb_typeof(preferencias_visuais) = 'object'
  )
);

comment on table sistema.configuracoes_usuario is
  'Preferências seguras e não secretas do usuário. Segredos nunca devem ser persistidos nesta tabela.';
comment on column sistema.configuracoes_usuario.preferencias_visuais is
  'Metadados visuais flexíveis e auxiliares. Preferências comportamentais importantes permanecem em colunas próprias.';

alter table sistema.configuracoes_usuario enable row level security;

drop policy if exists configuracoes_usuario_selecionar_proprias on sistema.configuracoes_usuario;
create policy configuracoes_usuario_selecionar_proprias
  on sistema.configuracoes_usuario
  for select
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists configuracoes_usuario_inserir_proprias on sistema.configuracoes_usuario;
create policy configuracoes_usuario_inserir_proprias
  on sistema.configuracoes_usuario
  for insert
  to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists configuracoes_usuario_atualizar_proprias on sistema.configuracoes_usuario;
create policy configuracoes_usuario_atualizar_proprias
  on sistema.configuracoes_usuario
  for update
  to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists configuracoes_usuario_excluir_proprias on sistema.configuracoes_usuario;
create policy configuracoes_usuario_excluir_proprias
  on sistema.configuracoes_usuario
  for delete
  to authenticated
  using ((select auth.uid()) = usuario_id);

-- Os schemas internos continuam fora da superfície direta da Data API.
-- As policies acima são uma segunda barreira e preparam acesso seguro futuro.
revoke all on all tables in schema sistema from public, anon, authenticated;
revoke all on all sequences in schema sistema from public, anon, authenticated;
revoke all on all functions in schema sistema from public, anon, authenticated;

commit;


-- ==========================================
-- File: 20260916185118_0003_taxonomia.sql
-- ==========================================

-- 0003_taxonomia
-- Taxonomia Mestre versionada do Cérebro Autoral.
--
-- Decisões importantes desta migration:
-- 1. Os estados de taxonomia.versoes possuem vocabulário explicitamente definido
--    pelo Dicionário Mestre e, portanto, usam CHECK.
-- 2. O Dicionário exige taxonomia.conceitos.estado, mas ainda não enumera seus
--    valores. A coluna nasce NOT NULL sem CHECK para não inventarmos vocabulário.
-- 3. taxonomia.classificacoes_elementos.elemento_id ainda não recebe FK porque
--    processamento.elementos será criado somente em migration posterior.
-- 4. O schema permanece interno: anon/authenticated não recebem acesso direto.

create table if not exists taxonomia.versoes (
  id uuid primary key default gen_random_uuid(),
  numero_versao text not null unique,
  descricao text not null,
  estado text not null,
  criado_em timestamptz not null default now(),
  ativado_em timestamptz,
  constraint versoes_taxonomia_estado_check
    check (estado in ('rascunho', 'ativa', 'arquivada'))
);

comment on table taxonomia.versoes is
  'Versões formais da Taxonomia Mestre que organiza o conhecimento intelectual do sistema.';
comment on column taxonomia.versoes.numero_versao is
  'Identificador humano/versionado da taxonomia, por exemplo 1.0.';
comment on column taxonomia.versoes.estado is
  'Estado técnico da versão: rascunho, ativa ou arquivada.';

create index if not exists versoes_taxonomia_estado_idx
  on taxonomia.versoes (estado);

create table if not exists taxonomia.conceitos (
  id uuid primary key default gen_random_uuid(),
  versao_taxonomia_id uuid not null
    references taxonomia.versoes(id) on delete restrict,
  codigo text not null,
  termo_preferencial text not null,
  definicao text not null,
  nota_escopo text,
  dominio text not null,
  estado text not null,
  criado_em timestamptz not null default now(),
  constraint conceitos_dominio_check
    check (dominio in (
      'intelectual',
      'axiologico',
      'reflexivo',
      'narrativo',
      'entidades',
      'temporal',
      'retorico',
      'linguistico',
      'estrutural',
      'autoral'
    )),
  constraint conceitos_codigo_por_versao_unique
    unique (versao_taxonomia_id, codigo)
);

comment on table taxonomia.conceitos is
  'Unidades canônicas de conhecimento da Taxonomia Mestre.';
comment on column taxonomia.conceitos.estado is
  'Estado obrigatório do conceito. O vocabulário de estados ainda não foi congelado no Dicionário Mestre v1.0.';
comment on column taxonomia.conceitos.dominio is
  'Domínio intelectual canônico ao qual o conceito pertence.';

create index if not exists conceitos_versao_idx
  on taxonomia.conceitos (versao_taxonomia_id);
create index if not exists conceitos_dominio_idx
  on taxonomia.conceitos (dominio);

create table if not exists taxonomia.termos (
  id uuid primary key default gen_random_uuid(),
  conceito_id uuid not null
    references taxonomia.conceitos(id) on delete cascade,
  termo text not null,
  termo_normalizado text not null,
  tipo text not null,
  idioma text not null,
  constraint termos_tipo_check
    check (tipo in (
      'preferencial',
      'alternativo',
      'sinonimo',
      'historico',
      'oculto_busca'
    )),
  constraint termos_repeticao_exata_unique
    unique (conceito_id, termo_normalizado, tipo, idioma)
);

comment on table taxonomia.termos is
  'Termos preferenciais, alternativos, sinônimos, históricos e termos ocultos de busca associados a conceitos.';
comment on column taxonomia.termos.termo_normalizado is
  'Forma normalizada usada para comparação e recuperação taxonômica.';

create index if not exists termos_normalizado_idx
  on taxonomia.termos (termo_normalizado);
create index if not exists termos_conceito_idx
  on taxonomia.termos (conceito_id);

create table if not exists taxonomia.relacoes (
  id uuid primary key default gen_random_uuid(),
  conceito_origem_id uuid not null
    references taxonomia.conceitos(id) on delete cascade,
  tipo_relacao text not null,
  conceito_destino_id uuid not null
    references taxonomia.conceitos(id) on delete cascade,
  confianca numeric(5,4) not null,
  origem text not null,
  criado_em timestamptz not null default now(),
  constraint relacoes_tipo_check
    check (tipo_relacao in (
      'mais_amplo',
      'mais_especifico',
      'relacionado',
      'contrasta_com',
      'deriva_de',
      'evolui_para',
      'associado_a'
    )),
  constraint relacoes_origem_check
    check (origem in ('curadoria', 'ia', 'importacao')),
  constraint relacoes_confianca_check
    check (confianca >= 0 and confianca <= 1),
  constraint relacoes_sem_auto_relacao_check
    check (conceito_origem_id <> conceito_destino_id),
  constraint relacoes_repeticao_exata_unique
    unique (conceito_origem_id, tipo_relacao, conceito_destino_id, origem)
);

comment on table taxonomia.relacoes is
  'Relações semânticas entre conceitos canônicos, com confiança e origem rastreáveis.';

create index if not exists relacoes_origem_idx
  on taxonomia.relacoes (conceito_origem_id, tipo_relacao);
create index if not exists relacoes_destino_idx
  on taxonomia.relacoes (conceito_destino_id, tipo_relacao);

create table if not exists taxonomia.classificacoes_elementos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  elemento_id uuid not null,
  conceito_id uuid not null
    references taxonomia.conceitos(id) on delete restrict,
  papel text not null,
  confianca numeric(5,4) not null,
  criado_em timestamptz not null default now(),
  constraint classificacoes_elementos_papel_check
    check (papel in ('principal', 'secundario', 'contextual', 'oposicao')),
  constraint classificacoes_elementos_confianca_check
    check (confianca >= 0 and confianca <= 1),
  constraint classificacoes_elementos_repeticao_unique
    unique (usuario_id, elemento_id, conceito_id, papel)
);

comment on table taxonomia.classificacoes_elementos is
  'Classificações de elementos processados em conceitos canônicos. A FK de elemento_id será adicionada quando processamento.elementos existir.';
comment on column taxonomia.classificacoes_elementos.elemento_id is
  'Referência lógica futura a processamento.elementos.id; FK deliberadamente adiada pela ordem canônica das migrations.';

create index if not exists classificacoes_elementos_usuario_idx
  on taxonomia.classificacoes_elementos (usuario_id);
create index if not exists classificacoes_elementos_elemento_idx
  on taxonomia.classificacoes_elementos (elemento_id);
create index if not exists classificacoes_elementos_conceito_idx
  on taxonomia.classificacoes_elementos (conceito_id);

alter table taxonomia.classificacoes_elementos enable row level security;

drop policy if exists classificacoes_elementos_selecionar_proprias on taxonomia.classificacoes_elementos;
create policy classificacoes_elementos_selecionar_proprias
  on taxonomia.classificacoes_elementos
  for select
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists classificacoes_elementos_inserir_proprias on taxonomia.classificacoes_elementos;
create policy classificacoes_elementos_inserir_proprias
  on taxonomia.classificacoes_elementos
  for insert
  to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists classificacoes_elementos_atualizar_proprias on taxonomia.classificacoes_elementos;
create policy classificacoes_elementos_atualizar_proprias
  on taxonomia.classificacoes_elementos
  for update
  to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists classificacoes_elementos_excluir_proprias on taxonomia.classificacoes_elementos;
create policy classificacoes_elementos_excluir_proprias
  on taxonomia.classificacoes_elementos
  for delete
  to authenticated
  using ((select auth.uid()) = usuario_id);

-- O schema taxonomia é interno. Views/RPCs seguras serão expostas futuramente
-- pelo schema aplicacao quando a interface necessitar desses dados.
revoke all on all tables in schema taxonomia from public, anon, authenticated;
revoke all on all sequences in schema taxonomia from public, anon, authenticated;
revoke all on all functions in schema taxonomia from public, anon, authenticated;

-- Validação estrutural da própria migration.
do $$
declare
  tabela_count integer;
  policy_count integer;
  rls_ativo boolean;
begin
  select count(*) into tabela_count
  from information_schema.tables
  where table_schema = 'taxonomia'
    and table_name in (
      'versoes',
      'conceitos',
      'termos',
      'relacoes',
      'classificacoes_elementos'
    );

  if tabela_count <> 5 then
    raise exception 'Esperadas 5 tabelas de taxonomia, encontradas %', tabela_count;
  end if;

  select relrowsecurity into rls_ativo
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'taxonomia'
    and c.relname = 'classificacoes_elementos';

  if rls_ativo is not true then
    raise exception 'RLS nao esta ativo em taxonomia.classificacoes_elementos';
  end if;

  select count(*) into policy_count
  from pg_policies
  where schemaname = 'taxonomia'
    and tablename = 'classificacoes_elementos';

  if policy_count <> 4 then
    raise exception 'Esperadas 4 policies em classificacoes_elementos, encontradas %', policy_count;
  end if;
end $$;


-- ==========================================
-- File: 20260916185526_0004_biblioteca.sql
-- ==========================================

-- 0004_biblioteca
-- Estrutura canônica da Biblioteca: obras lógicas e suas versões físicas.

create table if not exists biblioteca.obras (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  codigo text not null,
  titulo_original text not null,
  titulo_exibicao text not null,
  titulo_normalizado text not null,
  tipo_obra text not null,
  autoria text not null,
  participacao_cerebro text not null,
  autor_original text,
  idioma text not null,
  categoria text,
  descricao text,
  data_producao date,
  periodo_autoral_inicio date,
  periodo_autoral_fim date,
  precisao_data text,
  importancia smallint,
  estado text not null,
  metadados_auxiliares jsonb,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),

  constraint obras_codigo_usuario_unique
    unique (usuario_id, codigo),
  constraint obras_id_usuario_unique
    unique (id, usuario_id),
  constraint obras_tipo_obra_check
    check (tipo_obra in (
      'livro',
      'capitulo',
      'artigo',
      'carta',
      'reflexao',
      'ensaio',
      'relato',
      'mensagem',
      'anotacao',
      'transcricao',
      'documento_profissional',
      'material_metodologico',
      'referencia_externa',
      'outro'
    )),
  constraint obras_autoria_check
    check (autoria in ('autoral', 'externa')),
  constraint obras_participacao_cerebro_check
    check (participacao_cerebro in (
      'autoral_prioritaria',
      'externa_referencia',
      'externa_influencia',
      'excluida_cerebro'
    )),
  constraint obras_estado_check
    check (estado in ('ativa', 'arquivada', 'excluida')),
  constraint obras_precisao_data_check
    check (
      precisao_data is null
      or precisao_data in ('exata', 'aproximada', 'periodo', 'desconhecida')
    ),
  constraint obras_importancia_check
    check (importancia is null or (importancia >= 1 and importancia <= 5)),
  constraint obras_metadados_auxiliares_objeto_check
    check (metadados_auxiliares is null or jsonb_typeof(metadados_auxiliares) = 'object'),
  constraint obras_autoral_prioritaria_check
    check (participacao_cerebro <> 'autoral_prioritaria' or autoria = 'autoral'),
  constraint obras_externa_influencia_autoria_check
    check (participacao_cerebro <> 'externa_influencia' or autoria = 'externa')
);

comment on table biblioteca.obras is
  'Obra intelectual ou documento lógico, independente do arquivo físico e de suas versões.';
comment on column biblioteca.obras.autoria is
  'Origem autoral da obra: autoral ou externa.';
comment on column biblioteca.obras.participacao_cerebro is
  'Papel da obra no Cérebro Autoral, separado da autoria.';
comment on column biblioteca.obras.metadados_auxiliares is
  'Metadados flexíveis não canônicos; dados importantes permanecem em colunas próprias.';

create index if not exists obras_usuario_estado_idx
  on biblioteca.obras (usuario_id, estado);

create index if not exists obras_usuario_autoria_participacao_idx
  on biblioteca.obras (usuario_id, autoria, participacao_cerebro);

create index if not exists obras_busca_textual_idx
  on biblioteca.obras
  using gin (
    to_tsvector(
      'simple'::regconfig,
      coalesce(titulo_normalizado, '') || ' ' || coalesce(descricao, '')
    )
  );

create table if not exists biblioteca.versoes_obras (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  obra_id uuid not null,
  codigo text not null,
  numero_versao integer not null,
  nome_arquivo text not null,
  caminho_arquivo text not null,
  tipo_mime text not null,
  extensao text,
  tamanho_bytes bigint not null,
  hash_sha256 text not null,
  quantidade_paginas integer,
  quantidade_palavras integer,
  estado_processamento text not null,
  criado_em timestamptz not null default now(),

  constraint versoes_obras_obra_usuario_fk
    foreign key (obra_id, usuario_id)
    references biblioteca.obras(id, usuario_id)
    on delete restrict,
  constraint versoes_obras_numero_unique
    unique (obra_id, numero_versao),
  constraint versoes_obras_numero_check
    check (numero_versao >= 1),
  constraint versoes_obras_tamanho_check
    check (tamanho_bytes >= 0),
  constraint versoes_obras_paginas_check
    check (quantidade_paginas is null or quantidade_paginas >= 0),
  constraint versoes_obras_palavras_check
    check (quantidade_palavras is null or quantidade_palavras >= 0),
  constraint versoes_obras_estado_processamento_check
    check (estado_processamento in (
      'recebido',
      'em_processamento',
      'concluido',
      'falhou'
    ))
);

comment on table biblioteca.versoes_obras is
  'Preserva cada versão física de uma obra sem sobrescrever as versões anteriores.';
comment on column biblioteca.versoes_obras.caminho_arquivo is
  'Caminho do arquivo original no Storage privado.';
comment on column biblioteca.versoes_obras.hash_sha256 is
  'Hash SHA-256 utilizado para integridade e deduplicação.';

create index if not exists versoes_obras_usuario_hash_idx
  on biblioteca.versoes_obras (usuario_id, hash_sha256);

create index if not exists versoes_obras_usuario_estado_idx
  on biblioteca.versoes_obras (usuario_id, estado_processamento);

alter table biblioteca.obras enable row level security;
alter table biblioteca.versoes_obras enable row level security;

drop policy if exists obras_selecionar_proprias on biblioteca.obras;
create policy obras_selecionar_proprias
  on biblioteca.obras
  for select
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists obras_inserir_proprias on biblioteca.obras;
create policy obras_inserir_proprias
  on biblioteca.obras
  for insert
  to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists obras_atualizar_proprias on biblioteca.obras;
create policy obras_atualizar_proprias
  on biblioteca.obras
  for update
  to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists obras_excluir_proprias on biblioteca.obras;
create policy obras_excluir_proprias
  on biblioteca.obras
  for delete
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists versoes_obras_selecionar_proprias on biblioteca.versoes_obras;
create policy versoes_obras_selecionar_proprias
  on biblioteca.versoes_obras
  for select
  to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists versoes_obras_inserir_proprias on biblioteca.versoes_obras;
create policy versoes_obras_inserir_proprias
  on biblioteca.versoes_obras
  for insert
  to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists versoes_obras_atualizar_proprias on biblioteca.versoes_obras;
create policy versoes_obras_atualizar_proprias
  on biblioteca.versoes_obras
  for update
  to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists versoes_obras_excluir_proprias on biblioteca.versoes_obras;
create policy versoes_obras_excluir_proprias
  on biblioteca.versoes_obras
  for delete
  to authenticated
  using ((select auth.uid()) = usuario_id);

-- O schema biblioteca permanece interno. A interface utilizará uma camada segura
-- em aplicacao e/ou endpoints do servidor.
revoke all on all tables in schema biblioteca from public, anon, authenticated;
revoke all on all sequences in schema biblioteca from public, anon, authenticated;
revoke all on all functions in schema biblioteca from public, anon, authenticated;

-- A regra de que externa_influencia precisa possuir registro ativo em
-- cerebro_autoral.influencias_externas será adicionada quando essa tabela existir.

-- Validação estrutural da própria migration.
do $$
declare
  tabela_count integer;
  policy_count integer;
  rls_obras boolean;
  rls_versoes boolean;
begin
  select count(*) into tabela_count
  from information_schema.tables
  where table_schema = 'biblioteca'
    and table_name in ('obras', 'versoes_obras');

  if tabela_count <> 2 then
    raise exception 'Esperadas 2 tabelas de biblioteca, encontradas %', tabela_count;
  end if;

  select relrowsecurity into rls_obras
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'biblioteca' and c.relname = 'obras';

  select relrowsecurity into rls_versoes
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'biblioteca' and c.relname = 'versoes_obras';

  if rls_obras is not true or rls_versoes is not true then
    raise exception 'RLS nao esta ativo em todas as tabelas da biblioteca';
  end if;

  select count(*) into policy_count
  from pg_policies
  where schemaname = 'biblioteca'
    and tablename in ('obras', 'versoes_obras');

  if policy_count <> 8 then
    raise exception 'Esperadas 8 policies na biblioteca, encontradas %', policy_count;
  end if;
end $$;


-- ==========================================
-- File: 20260916185621_0005_indice_fk_biblioteca.sql
-- ==========================================

-- 0005_indice_fk_biblioteca
-- Cobre a FK composta (obra_id, usuario_id) de biblioteca.versoes_obras.
-- O advisor de performance do Supabase detectou a ausência deste índice após
-- a aplicação de 0004_biblioteca.

create index if not exists versoes_obras_obra_usuario_idx
  on biblioteca.versoes_obras (obra_id, usuario_id);

comment on index biblioteca.versoes_obras_obra_usuario_idx is
  'Índice de suporte à FK composta que garante integridade multiusuário entre versão e obra.';

do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'biblioteca'
      and tablename = 'versoes_obras'
      and indexname = 'versoes_obras_obra_usuario_idx'
  ) then
    raise exception 'Indice de suporte a FK nao foi criado';
  end if;
end $$;


-- ==========================================
-- File: 20260916190006_0006_storage_biblioteca.sql
-- ==========================================

-- 0006_storage_biblioteca
-- Bucket privado e políticas de acesso dos arquivos originais da Biblioteca.
--
-- O nome do objeto no Storage será gerado no formato:
-- {usuario_id}/{obra_id}/{versao_id}/original.ext
--
-- O Dicionário ainda não congelou todos os tipos/tamanhos de arquivo aceitos,
-- portanto esta migration não impõe allowed_mime_types nem file_size_limit.

insert into storage.buckets (id, name, public)
values ('originais-biblioteca', 'originais-biblioteca', false)
on conflict (id) do update
set name = excluded.name,
    public = false;

-- Usuário autenticado só pode visualizar arquivos cujo primeiro segmento
-- da pasta seja o próprio auth.uid(). Isso também permite que arquivos
-- enviados pelo backend em nome do usuário continuem acessíveis ao usuário.
drop policy if exists originais_biblioteca_selecionar_proprios on storage.objects;
create policy originais_biblioteca_selecionar_proprios
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'originais-biblioteca'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists originais_biblioteca_inserir_proprios on storage.objects;
create policy originais_biblioteca_inserir_proprios
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'originais-biblioteca'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists originais_biblioteca_atualizar_proprios on storage.objects;
create policy originais_biblioteca_atualizar_proprios
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'originais-biblioteca'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'originais-biblioteca'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists originais_biblioteca_excluir_proprios on storage.objects;
create policy originais_biblioteca_excluir_proprios
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'originais-biblioteca'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Validação estrutural da configuração de Storage.
do $$
declare
  bucket_privado boolean;
  policy_count integer;
begin
  select (public = false)
  into bucket_privado
  from storage.buckets
  where id = 'originais-biblioteca';

  if bucket_privado is not true then
    raise exception 'Bucket originais-biblioteca nao existe ou nao esta privado';
  end if;

  select count(*)
  into policy_count
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and policyname in (
      'originais_biblioteca_selecionar_proprios',
      'originais_biblioteca_inserir_proprios',
      'originais_biblioteca_atualizar_proprios',
      'originais_biblioteca_excluir_proprios'
    );

  if policy_count <> 4 then
    raise exception 'Esperadas 4 policies do Storage da Biblioteca, encontradas %', policy_count;
  end if;
end $$;


-- ==========================================
-- File: 20260916190833_0007_api_aplicacao_biblioteca.sql
-- ==========================================

-- 0007_api_aplicacao_biblioteca
-- Expõe somente funções controladas no schema aplicacao.
-- As tabelas internas de biblioteca permanecem fora da Data API.

-- A lista de schemas expostos passa a ser controlada por migration.
-- Isso torna a configuração reprodutível, mas significa que alterações futuras
-- na lista também devem ser feitas por migration e não silenciosamente no Dashboard.
alter role authenticator
  set pgrst.db_schemas = 'public, graphql_public, aplicacao';

revoke all on schema aplicacao from public, anon;
grant usage on schema aplicacao to authenticated, service_role;

-- Novas funções não devem nascer executáveis por PUBLIC.
alter default privileges for role postgres in schema aplicacao
  revoke execute on functions from public;

create or replace function aplicacao.listar_obras()
returns table (
  id uuid,
  codigo text,
  titulo text,
  tipo_obra text,
  autoria text,
  participacao_cerebro text,
  idioma text,
  descricao text,
  estado text,
  criado_em timestamptz,
  versao_id uuid,
  numero_versao integer,
  nome_arquivo text,
  estado_processamento text,
  versao_criada_em timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid := auth.uid();
begin
  if v_usuario_id is null then
    raise exception 'Autenticacao obrigatoria'
      using errcode = '42501';
  end if;

  return query
  select
    o.id,
    o.codigo,
    o.titulo_exibicao,
    o.tipo_obra,
    o.autoria,
    o.participacao_cerebro,
    o.idioma,
    o.descricao,
    o.estado,
    o.criado_em,
    v.id,
    v.numero_versao,
    v.nome_arquivo,
    v.estado_processamento,
    v.criado_em
  from biblioteca.obras o
  left join lateral (
    select
      vo.id,
      vo.numero_versao,
      vo.nome_arquivo,
      vo.estado_processamento,
      vo.criado_em
    from biblioteca.versoes_obras vo
    where vo.obra_id = o.id
      and vo.usuario_id = v_usuario_id
    order by vo.numero_versao desc
    limit 1
  ) v on true
  where o.usuario_id = v_usuario_id
    and o.estado <> 'excluida'
  order by o.criado_em desc;
end;
$$;

comment on function aplicacao.listar_obras() is
  'Lista somente as obras do usuário autenticado e a versão física mais recente de cada obra.';

create or replace function aplicacao.registrar_obra_arquivo(
  p_obra_id uuid,
  p_versao_id uuid,
  p_titulo text,
  p_tipo_obra text,
  p_autoria text,
  p_participacao_cerebro text,
  p_idioma text,
  p_nome_arquivo text,
  p_caminho_arquivo text,
  p_tipo_mime text,
  p_tamanho_bytes bigint,
  p_hash_sha256 text,
  p_extensao text default null,
  p_descricao text default null,
  p_data_producao date default null,
  p_autor_original text default null
)
returns table (
  obra_id uuid,
  obra_codigo text,
  versao_id uuid,
  versao_codigo text,
  caminho_arquivo text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_extensao text;
  v_nome_original_storage text;
  v_caminho_esperado text;
  v_obra_codigo text;
  v_versao_codigo text;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacao obrigatoria'
      using errcode = '42501';
  end if;

  if p_obra_id is null or p_versao_id is null then
    raise exception 'Identificadores de obra e versao sao obrigatorios'
      using errcode = '22023';
  end if;

  if nullif(trim(p_titulo), '') is null then
    raise exception 'Titulo obrigatorio'
      using errcode = '22023';
  end if;

  if nullif(trim(p_nome_arquivo), '') is null then
    raise exception 'Nome de arquivo obrigatorio'
      using errcode = '22023';
  end if;

  if nullif(trim(p_tipo_mime), '') is null then
    raise exception 'Tipo MIME obrigatorio'
      using errcode = '22023';
  end if;

  if nullif(trim(p_idioma), '') is null then
    raise exception 'Idioma obrigatorio'
      using errcode = '22023';
  end if;

  if p_tamanho_bytes < 0 then
    raise exception 'Tamanho de arquivo invalido'
      using errcode = '22023';
  end if;

  if p_hash_sha256 !~ '^[0-9A-Fa-f]{64}$' then
    raise exception 'Hash SHA-256 invalido'
      using errcode = '22023';
  end if;

  v_extensao := nullif(
    lower(regexp_replace(coalesce(trim(p_extensao), ''), '^\.+', '')),
    ''
  );

  v_nome_original_storage := 'original' ||
    case when v_extensao is null then '' else '.' || v_extensao end;

  v_caminho_esperado :=
    v_usuario_id::text || '/' ||
    p_obra_id::text || '/' ||
    p_versao_id::text || '/' ||
    v_nome_original_storage;

  if p_caminho_arquivo <> v_caminho_esperado then
    raise exception 'Caminho de arquivo nao corresponde ao usuario/obra/versao autenticados'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from storage.objects so
    where so.bucket_id = 'originais-biblioteca'
      and so.name = v_caminho_esperado
  ) then
    raise exception 'Arquivo original nao encontrado no Storage privado'
      using errcode = '22023';
  end if;

  v_obra_codigo := 'OBR-' || upper(substr(replace(p_obra_id::text, '-', ''), 1, 12));
  v_versao_codigo := 'VOB-' || upper(substr(replace(p_versao_id::text, '-', ''), 1, 12));

  insert into biblioteca.obras (
    id,
    usuario_id,
    codigo,
    titulo_original,
    titulo_exibicao,
    titulo_normalizado,
    tipo_obra,
    autoria,
    participacao_cerebro,
    autor_original,
    idioma,
    descricao,
    data_producao,
    precisao_data,
    estado
  )
  values (
    p_obra_id,
    v_usuario_id,
    v_obra_codigo,
    trim(p_titulo),
    trim(p_titulo),
    lower(extensions.unaccent(trim(p_titulo))),
    p_tipo_obra,
    p_autoria,
    p_participacao_cerebro,
    nullif(trim(p_autor_original), ''),
    trim(p_idioma),
    nullif(trim(p_descricao), ''),
    p_data_producao,
    case when p_data_producao is null then 'desconhecida' else 'exata' end,
    'ativa'
  );

  insert into biblioteca.versoes_obras (
    id,
    usuario_id,
    obra_id,
    codigo,
    numero_versao,
    nome_arquivo,
    caminho_arquivo,
    tipo_mime,
    extensao,
    tamanho_bytes,
    hash_sha256,
    estado_processamento
  )
  values (
    p_versao_id,
    v_usuario_id,
    p_obra_id,
    v_versao_codigo,
    1,
    trim(p_nome_arquivo),
    v_caminho_esperado,
    trim(p_tipo_mime),
    v_extensao,
    p_tamanho_bytes,
    lower(p_hash_sha256),
    'recebido'
  );

  return query
  select
    p_obra_id,
    v_obra_codigo,
    p_versao_id,
    v_versao_codigo,
    v_caminho_esperado;
end;
$$;

comment on function aplicacao.registrar_obra_arquivo(
  uuid, uuid, text, text, text, text, text, text, text, text, bigint, text, text, text, date, text
) is
  'Registra atomicamente a obra e sua primeira versão após confirmar que o original já existe no Storage privado do usuário autenticado.';

-- Fecha execução por padrão e reabre somente as RPCs previstas.
revoke all on all functions in schema aplicacao from public, anon, authenticated;

grant execute on function aplicacao.listar_obras()
  to authenticated;

grant execute on function aplicacao.registrar_obra_arquivo(
  uuid, uuid, text, text, text, text, text, text, text, text, bigint, text, text, text, date, text
) to authenticated;

notify pgrst, 'reload config';
notify pgrst, 'reload schema';

-- Validação estrutural.
do $$
declare
  schemas_expostos text;
  func_count integer;
begin
  select setting
  into schemas_expostos
  from pg_settings
  where name = 'pgrst.db_schemas';

  -- pg_settings pode não refletir parâmetros de role no mesmo contexto em todas
  -- as versões, por isso a verificação definitiva será feita após a migration
  -- consultando pg_roles. Aqui validamos as funções e grants.
  select count(*)
  into func_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'aplicacao'
    and p.proname in ('listar_obras', 'registrar_obra_arquivo');

  if func_count <> 2 then
    raise exception 'Esperadas 2 funcoes da API da Biblioteca, encontradas %', func_count;
  end if;

  if has_function_privilege('anon', 'aplicacao.listar_obras()', 'EXECUTE') then
    raise exception 'anon nao pode executar aplicacao.listar_obras';
  end if;

  if not has_function_privilege('authenticated', 'aplicacao.listar_obras()', 'EXECUTE') then
    raise exception 'authenticated precisa executar aplicacao.listar_obras';
  end if;
end $$;


-- ==========================================
-- File: 20260916192647_0008_processamento_execucoes.sql
-- ==========================================

-- 0008_processamento_execucoes
-- Fundação operacional do Pipeline Documental.
-- Cria execuções completas e etapas idempotentes/reexecutáveis.

-- Permite FKs compostas (entidade + usuário) sem depender apenas do UUID.
alter table biblioteca.versoes_obras
  add constraint versoes_obras_id_usuario_unique unique (id, usuario_id);

create table if not exists processamento.execucoes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  versao_obra_id uuid not null,
  codigo text not null,
  estado text not null default 'recebido',
  etapa_atual text,
  percentual numeric(5,2) not null default 0,
  versao_pipeline_id uuid not null references sistema.versoes_pipeline(id) on delete restrict,
  versao_taxonomia_id uuid not null references taxonomia.versoes(id) on delete restrict,
  iniciado_em timestamptz not null default now(),
  concluido_em timestamptz,
  codigo_erro text,
  mensagem_erro text,
  criado_em timestamptz not null default now(),

  constraint execucoes_versao_obra_usuario_fk
    foreign key (versao_obra_id, usuario_id)
    references biblioteca.versoes_obras(id, usuario_id)
    on delete restrict,
  constraint execucoes_codigo_usuario_unique
    unique (usuario_id, codigo),
  constraint execucoes_id_usuario_unique
    unique (id, usuario_id),
  constraint execucoes_percentual_check
    check (percentual >= 0 and percentual <= 100),
  constraint execucoes_estado_check
    check (estado in (
      'recebido',
      'validando',
      'extraindo',
      'normalizando',
      'estruturando',
      'segmentando',
      'sintetizando',
      'analisando',
      'classificando',
      'vetorizando',
      'relacionando',
      'validando_resultado',
      'finalizando',
      'concluido',
      'falhou',
      'cancelado'
    )),
  constraint execucoes_conclusao_coerente_check
    check (
      (estado in ('concluido', 'falhou', 'cancelado') and concluido_em is not null)
      or
      (estado not in ('concluido', 'falhou', 'cancelado') and concluido_em is null)
    )
);

comment on table processamento.execucoes is
  'Uma execução completa e rastreável do pipeline documental sobre uma versão de obra.';
comment on column processamento.execucoes.etapa_atual is
  'Nome técnico da etapa atualmente executada; não substitui o histórico detalhado de etapas.';
comment on column processamento.execucoes.mensagem_erro is
  'Resumo seguro do erro, sem conteúdo sensível desnecessário.';

create index if not exists execucoes_usuario_estado_idx
  on processamento.execucoes (usuario_id, estado, criado_em desc);

create index if not exists execucoes_versao_obra_usuario_idx
  on processamento.execucoes (versao_obra_id, usuario_id);

create index if not exists execucoes_versao_pipeline_idx
  on processamento.execucoes (versao_pipeline_id);

create index if not exists execucoes_versao_taxonomia_idx
  on processamento.execucoes (versao_taxonomia_id);

create table if not exists processamento.etapas_execucao (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  execucao_id uuid not null,
  nome_etapa text not null,
  ordem integer not null,
  chave_idempotencia text not null,
  estado text not null default 'pendente',
  tentativas integer not null default 0,
  iniciado_em timestamptz,
  concluido_em timestamptz,
  duracao_ms bigint,
  detalhes_auxiliares jsonb,
  criado_em timestamptz not null default now(),

  constraint etapas_execucao_execucao_usuario_fk
    foreign key (execucao_id, usuario_id)
    references processamento.execucoes(id, usuario_id)
    on delete cascade,
  constraint etapas_execucao_idempotencia_unique
    unique (chave_idempotencia),
  constraint etapas_execucao_ordem_unique
    unique (execucao_id, ordem),
  constraint etapas_execucao_ordem_check
    check (ordem >= 1),
  constraint etapas_execucao_tentativas_check
    check (tentativas >= 0),
  constraint etapas_execucao_duracao_check
    check (duracao_ms is null or duracao_ms >= 0),
  constraint etapas_execucao_detalhes_objeto_check
    check (detalhes_auxiliares is null or jsonb_typeof(detalhes_auxiliares) = 'object'),
  constraint etapas_execucao_estado_check
    check (estado in (
      'pendente',
      'executando',
      'concluida',
      'falhou',
      'ignorada',
      'cancelada'
    )),
  constraint etapas_execucao_tempos_check
    check (
      (concluido_em is null or iniciado_em is not null)
      and
      (iniciado_em is null or concluido_em is null or concluido_em >= iniciado_em)
    )
);

comment on table processamento.etapas_execucao is
  'Histórico de etapas idempotentes de uma execução do pipeline; suporta retry, resume e observabilidade.';
comment on column processamento.etapas_execucao.chave_idempotencia is
  'Chave estável que impede duplicação de uma etapa cara quando uma execução é retomada ou repetida.';
comment on column processamento.etapas_execucao.detalhes_auxiliares is
  'Metadados operacionais auxiliares; dados primários do domínio permanecem normalizados.';

-- A constraint unique(execucao_id, ordem) já fornece o índice ordenado exigido
-- pelo Dicionário Mestre; não criamos um índice duplicado.
create index if not exists etapas_execucao_estado_criado_idx
  on processamento.etapas_execucao (estado, criado_em);

create index if not exists etapas_execucao_usuario_estado_idx
  on processamento.etapas_execucao (usuario_id, estado);

alter table processamento.execucoes enable row level security;
alter table processamento.etapas_execucao enable row level security;

drop policy if exists execucoes_selecionar_proprias on processamento.execucoes;
create policy execucoes_selecionar_proprias
  on processamento.execucoes
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists execucoes_inserir_proprias on processamento.execucoes;
create policy execucoes_inserir_proprias
  on processamento.execucoes
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists execucoes_atualizar_proprias on processamento.execucoes;
create policy execucoes_atualizar_proprias
  on processamento.execucoes
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists execucoes_excluir_proprias on processamento.execucoes;
create policy execucoes_excluir_proprias
  on processamento.execucoes
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists etapas_execucao_selecionar_proprias on processamento.etapas_execucao;
create policy etapas_execucao_selecionar_proprias
  on processamento.etapas_execucao
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

drop policy if exists etapas_execucao_inserir_proprias on processamento.etapas_execucao;
create policy etapas_execucao_inserir_proprias
  on processamento.etapas_execucao
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

drop policy if exists etapas_execucao_atualizar_proprias on processamento.etapas_execucao;
create policy etapas_execucao_atualizar_proprias
  on processamento.etapas_execucao
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

drop policy if exists etapas_execucao_excluir_proprias on processamento.etapas_execucao;
create policy etapas_execucao_excluir_proprias
  on processamento.etapas_execucao
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

-- Processamento é schema interno. O usuário verá estado/progresso por API controlada.
revoke all on all tables in schema processamento from public, anon, authenticated;
revoke all on all sequences in schema processamento from public, anon, authenticated;
revoke all on all functions in schema processamento from public, anon, authenticated;

-- Validação estrutural.
do $$
declare
  tabela_count integer;
  policy_count integer;
  rls_count integer;
begin
  select count(*) into tabela_count
  from information_schema.tables
  where table_schema = 'processamento'
    and table_name in ('execucoes', 'etapas_execucao');

  if tabela_count <> 2 then
    raise exception 'Esperadas 2 tabelas de execucao, encontradas %', tabela_count;
  end if;

  select count(*) into rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'processamento'
    and c.relname in ('execucoes', 'etapas_execucao')
    and c.relrowsecurity is true;

  if rls_count <> 2 then
    raise exception 'RLS nao esta ativo nas duas tabelas de execucao';
  end if;

  select count(*) into policy_count
  from pg_policies
  where schemaname = 'processamento'
    and tablename in ('execucoes', 'etapas_execucao');

  if policy_count <> 8 then
    raise exception 'Esperadas 8 policies nas tabelas de execucao, encontradas %', policy_count;
  end if;
end $$;


-- ==========================================
-- File: 20260916192731_0009_indice_fk_etapas_execucao.sql
-- ==========================================

-- 0009_indice_fk_etapas_execucao
-- Corrige o alerta do advisor de performance após 0008_processamento_execucoes.

create index if not exists etapas_execucao_execucao_usuario_idx
  on processamento.etapas_execucao (execucao_id, usuario_id);

comment on index processamento.etapas_execucao_execucao_usuario_idx is
  'Índice de suporte à FK composta entre etapa e execução, preservando integridade multiusuário.';

do $$
begin
  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'processamento'
      and tablename = 'etapas_execucao'
      and indexname = 'etapas_execucao_execucao_usuario_idx'
  ) then
    raise exception 'Indice de suporte a FK das etapas nao foi criado';
  end if;
end $$;


-- ==========================================
-- File: 20260916194638_0010_seeds_versoes_base.sql
-- ==========================================

-- 0010_seeds_versoes_base
-- Registra as versões técnicas mínimas necessárias para que o Pipeline Documental
-- possa criar execuções com proveniência/versionamento desde o primeiro documento.
-- Não cria conceitos taxonômicos nem escolhe modelos de IA.

insert into taxonomia.versoes (
  numero_versao,
  descricao,
  estado,
  ativado_em
)
values (
  '1.0',
  'Taxonomia Mestre v1.0 — versão base canônica definida pelo Dicionário Mestre de Dados e Taxonomia.',
  'ativa',
  now()
)
on conflict (numero_versao) do nothing;

insert into sistema.versoes_pipeline (
  numero_versao,
  descricao,
  hash_configuracao,
  estado,
  ativado_em
)
values (
  '1.0',
  'Pipeline Documental v1.0 — configuração base canônica para processamento versionado e idempotente.',
  'c1a57497ee66838c9879cbbf98570b70ce10ecb3347232485a29051cf5dcc2b1',
  'ativa',
  now()
)
on conflict (numero_versao) do nothing;


-- ==========================================
-- File: 20260916195547_0011_processamento_documentos_hierarquia.sql
-- ==========================================

-- 0011_processamento_documentos_hierarquia
-- Representação computacional hierárquica: documento, seções, fragmentos e sínteses.

create table if not exists processamento.documentos_processados (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  obra_id uuid not null,
  versao_obra_id uuid not null,
  execucao_id uuid not null,
  codigo text not null,
  titulo text not null,
  resumo_global text,
  sintese_analitica text,
  quantidade_partes integer not null default 0,
  quantidade_capitulos integer not null default 0,
  quantidade_secoes integer not null default 0,
  quantidade_fragmentos integer not null default 0,
  quantidade_elementos integer not null default 0,
  versao_pipeline_id uuid not null references sistema.versoes_pipeline(id) on delete restrict,
  versao_taxonomia_id uuid not null references taxonomia.versoes(id) on delete restrict,
  estado text not null default 'candidato',
  publicado_em timestamptz,
  processado_em timestamptz not null default now(),

  constraint documentos_processados_obra_usuario_fk
    foreign key (obra_id, usuario_id)
    references biblioteca.obras(id, usuario_id) on delete restrict,
  constraint documentos_processados_versao_usuario_fk
    foreign key (versao_obra_id, usuario_id)
    references biblioteca.versoes_obras(id, usuario_id) on delete restrict,
  constraint documentos_processados_execucao_usuario_fk
    foreign key (execucao_id, usuario_id)
    references processamento.execucoes(id, usuario_id) on delete restrict,
  constraint documentos_processados_id_usuario_unique unique (id, usuario_id),
  constraint documentos_processados_codigo_usuario_unique unique (usuario_id, codigo),
  constraint documentos_processados_execucao_unique unique (execucao_id),
  constraint documentos_processados_quantidades_check check (
    quantidade_partes >= 0 and quantidade_capitulos >= 0 and quantidade_secoes >= 0
    and quantidade_fragmentos >= 0 and quantidade_elementos >= 0
  ),
  constraint documentos_processados_estado_check check (
    estado in ('candidato','ativo','substituido','invalidado')
  ),
  constraint documentos_processados_titulo_check check (length(trim(titulo)) > 0)
);

create unique index if not exists documentos_processados_ativo_por_obra_uidx
  on processamento.documentos_processados (usuario_id, obra_id)
  where estado = 'ativo';
create index if not exists documentos_processados_obra_usuario_idx
  on processamento.documentos_processados (obra_id, usuario_id);
create index if not exists documentos_processados_versao_usuario_idx
  on processamento.documentos_processados (versao_obra_id, usuario_id);
create index if not exists documentos_processados_execucao_usuario_idx
  on processamento.documentos_processados (execucao_id, usuario_id);
create index if not exists documentos_processados_pipeline_idx
  on processamento.documentos_processados (versao_pipeline_id);
create index if not exists documentos_processados_taxonomia_idx
  on processamento.documentos_processados (versao_taxonomia_id);
create index if not exists documentos_processados_estado_idx
  on processamento.documentos_processados (usuario_id, estado, processado_em desc);

create table if not exists processamento.secoes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  documento_processado_id uuid not null,
  secao_pai_id uuid,
  codigo text not null,
  tipo text not null,
  titulo text,
  ordem integer not null,
  nivel_hierarquico smallint not null,
  pagina_inicial integer,
  pagina_final integer,
  conteudo text,
  criado_em timestamptz not null default now(),

  constraint secoes_documento_usuario_fk
    foreign key (documento_processado_id, usuario_id)
    references processamento.documentos_processados(id, usuario_id) on delete cascade,
  constraint secoes_id_documento_usuario_unique unique (id, documento_processado_id, usuario_id),
  constraint secoes_pai_mesmo_documento_fk
    foreign key (secao_pai_id, documento_processado_id, usuario_id)
    references processamento.secoes(id, documento_processado_id, usuario_id) on delete restrict,
  constraint secoes_codigo_documento_unique unique (documento_processado_id, codigo),
  constraint secoes_tipo_check check (
    tipo in ('obra','parte','capitulo','secao','subsecao','anexo','prefacio','posfacio','nota')
  ),
  constraint secoes_ordem_check check (ordem >= 1),
  constraint secoes_nivel_check check (nivel_hierarquico >= 0),
  constraint secoes_paginas_check check (
    (pagina_inicial is null or pagina_inicial >= 1)
    and (pagina_final is null or pagina_final >= 1)
    and (pagina_inicial is null or pagina_final is null or pagina_final >= pagina_inicial)
  )
);

create index if not exists secoes_documento_usuario_ordem_idx
  on processamento.secoes (documento_processado_id, usuario_id, ordem);
create index if not exists secoes_pai_documento_usuario_idx
  on processamento.secoes (secao_pai_id, documento_processado_id, usuario_id);

create table if not exists processamento.fragmentos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  documento_processado_id uuid not null,
  secao_id uuid,
  codigo text not null,
  ordem integer not null,
  fragmento_anterior_id uuid,
  fragmento_seguinte_id uuid,
  pagina_inicial integer,
  pagina_final integer,
  conteudo text not null,
  conteudo_contextualizado text not null,
  quantidade_tokens integer not null,
  vetor_textual tsvector generated always as (
    to_tsvector('simple'::regconfig, coalesce(conteudo_contextualizado, ''))
  ) stored,
  criado_em timestamptz not null default now(),

  constraint fragmentos_documento_usuario_fk
    foreign key (documento_processado_id, usuario_id)
    references processamento.documentos_processados(id, usuario_id) on delete cascade,
  constraint fragmentos_secao_mesmo_documento_fk
    foreign key (secao_id, documento_processado_id, usuario_id)
    references processamento.secoes(id, documento_processado_id, usuario_id) on delete restrict,
  constraint fragmentos_id_documento_usuario_unique unique (id, documento_processado_id, usuario_id),
  constraint fragmentos_anterior_mesmo_documento_fk
    foreign key (fragmento_anterior_id, documento_processado_id, usuario_id)
    references processamento.fragmentos(id, documento_processado_id, usuario_id) on delete restrict,
  constraint fragmentos_seguinte_mesmo_documento_fk
    foreign key (fragmento_seguinte_id, documento_processado_id, usuario_id)
    references processamento.fragmentos(id, documento_processado_id, usuario_id) on delete restrict,
  constraint fragmentos_codigo_documento_unique unique (documento_processado_id, codigo),
  constraint fragmentos_ordem_documento_unique unique (documento_processado_id, ordem),
  constraint fragmentos_ordem_check check (ordem >= 1),
  constraint fragmentos_tokens_check check (quantidade_tokens >= 0),
  constraint fragmentos_conteudo_check check (length(trim(conteudo)) > 0),
  constraint fragmentos_contexto_check check (length(trim(conteudo_contextualizado)) > 0),
  constraint fragmentos_paginas_check check (
    (pagina_inicial is null or pagina_inicial >= 1)
    and (pagina_final is null or pagina_final >= 1)
    and (pagina_inicial is null or pagina_final is null or pagina_final >= pagina_inicial)
  ),
  constraint fragmentos_vizinhos_check check (
    id is distinct from fragmento_anterior_id and id is distinct from fragmento_seguinte_id
  )
);

create index if not exists fragmentos_documento_usuario_ordem_idx
  on processamento.fragmentos (documento_processado_id, usuario_id, ordem);
create index if not exists fragmentos_secao_documento_usuario_idx
  on processamento.fragmentos (secao_id, documento_processado_id, usuario_id);
create index if not exists fragmentos_anterior_documento_usuario_idx
  on processamento.fragmentos (fragmento_anterior_id, documento_processado_id, usuario_id);
create index if not exists fragmentos_seguinte_documento_usuario_idx
  on processamento.fragmentos (fragmento_seguinte_id, documento_processado_id, usuario_id);
create index if not exists fragmentos_vetor_textual_gin_idx
  on processamento.fragmentos using gin (vetor_textual);

create table if not exists processamento.sinteses (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  documento_processado_id uuid not null,
  tipo_alvo text not null,
  alvo_id uuid not null,
  nivel smallint not null,
  conteudo text not null,
  modelo_ia_id uuid not null references sistema.modelos_ia(id) on delete restrict,
  versao_prompt_id uuid not null references sistema.versoes_prompts(id) on delete restrict,
  criado_em timestamptz not null default now(),

  constraint sinteses_documento_usuario_fk
    foreign key (documento_processado_id, usuario_id)
    references processamento.documentos_processados(id, usuario_id) on delete cascade,
  constraint sinteses_tipo_alvo_check check (tipo_alvo in ('secao','capitulo','parte','obra')),
  constraint sinteses_nivel_check check (nivel >= 0),
  constraint sinteses_conteudo_check check (length(trim(conteudo)) > 0),
  constraint sinteses_alvo_unique unique (documento_processado_id, tipo_alvo, alvo_id, nivel)
);

create index if not exists sinteses_documento_usuario_idx
  on processamento.sinteses (documento_processado_id, usuario_id);
create index if not exists sinteses_alvo_idx
  on processamento.sinteses (tipo_alvo, alvo_id);
create index if not exists sinteses_modelo_idx on processamento.sinteses (modelo_ia_id);
create index if not exists sinteses_prompt_idx on processamento.sinteses (versao_prompt_id);

alter table processamento.documentos_processados enable row level security;
alter table processamento.secoes enable row level security;
alter table processamento.fragmentos enable row level security;
alter table processamento.sinteses enable row level security;

drop policy if exists documentos_processados_selecionar_proprios on processamento.documentos_processados;
create policy documentos_processados_selecionar_proprios
  on processamento.documentos_processados for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists documentos_processados_inserir_proprios on processamento.documentos_processados;
create policy documentos_processados_inserir_proprios
  on processamento.documentos_processados for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists documentos_processados_atualizar_proprios on processamento.documentos_processados;
create policy documentos_processados_atualizar_proprios
  on processamento.documentos_processados for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists documentos_processados_excluir_proprios on processamento.documentos_processados;
create policy documentos_processados_excluir_proprios
  on processamento.documentos_processados for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists secoes_selecionar_proprias on processamento.secoes;
create policy secoes_selecionar_proprias
  on processamento.secoes for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists secoes_inserir_proprias on processamento.secoes;
create policy secoes_inserir_proprias
  on processamento.secoes for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists secoes_atualizar_proprias on processamento.secoes;
create policy secoes_atualizar_proprias
  on processamento.secoes for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists secoes_excluir_proprias on processamento.secoes;
create policy secoes_excluir_proprias
  on processamento.secoes for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists fragmentos_selecionar_proprios on processamento.fragmentos;
create policy fragmentos_selecionar_proprios
  on processamento.fragmentos for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists fragmentos_inserir_proprios on processamento.fragmentos;
create policy fragmentos_inserir_proprios
  on processamento.fragmentos for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists fragmentos_atualizar_proprios on processamento.fragmentos;
create policy fragmentos_atualizar_proprios
  on processamento.fragmentos for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists fragmentos_excluir_proprios on processamento.fragmentos;
create policy fragmentos_excluir_proprios
  on processamento.fragmentos for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists sinteses_selecionar_proprias on processamento.sinteses;
create policy sinteses_selecionar_proprias
  on processamento.sinteses for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists sinteses_inserir_proprias on processamento.sinteses;
create policy sinteses_inserir_proprias
  on processamento.sinteses for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists sinteses_atualizar_proprias on processamento.sinteses;
create policy sinteses_atualizar_proprias
  on processamento.sinteses for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists sinteses_excluir_proprias on processamento.sinteses;
create policy sinteses_excluir_proprias
  on processamento.sinteses for delete to authenticated using ((select auth.uid()) = usuario_id);

revoke all on all tables in schema processamento from public, anon, authenticated;
revoke all on all sequences in schema processamento from public, anon, authenticated;
revoke all on all functions in schema processamento from public, anon, authenticated;


-- ==========================================
-- File: 20260916195710_0012_indices_fk_processamento_hierarquia.sql
-- ==========================================

-- 0012_indices_fk_processamento_hierarquia
-- Índices dedicados para FKs simples de usuario_id detectadas pelo advisor.

create index if not exists secoes_usuario_idx
  on processamento.secoes (usuario_id);

create index if not exists fragmentos_usuario_idx
  on processamento.fragmentos (usuario_id);

create index if not exists sinteses_usuario_idx
  on processamento.sinteses (usuario_id);


-- ==========================================
-- File: 20260916200317_0013_processamento_elementos_vetores_grafo.sql
-- ==========================================

-- 0013_processamento_elementos_vetores_grafo
-- Fecha a representação intelectual do Documento Processado e a FK adiada da Taxonomia.

alter table processamento.fragmentos
  add constraint fragmentos_id_usuario_unique unique (id, usuario_id);

create table if not exists processamento.vetores (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  tipo_alvo text not null,
  alvo_id uuid not null,
  embedding extensions.vector(1536) not null,
  modelo_ia_id uuid not null references sistema.modelos_ia(id) on delete restrict,
  dimensoes integer not null default 1536,
  versao integer not null default 1,
  criado_em timestamptz not null default now(),
  constraint vetores_dimensoes_check check (dimensoes = 1536),
  constraint vetores_versao_check check (versao >= 1),
  constraint vetores_tipo_alvo_check check (length(trim(tipo_alvo)) > 0),
  constraint vetores_alvo_modelo_versao_unique unique (usuario_id, tipo_alvo, alvo_id, modelo_ia_id, versao)
);

create index if not exists vetores_usuario_idx on processamento.vetores (usuario_id);
create index if not exists vetores_alvo_idx on processamento.vetores (usuario_id, tipo_alvo, alvo_id);
create index if not exists vetores_modelo_idx on processamento.vetores (modelo_ia_id);
create index if not exists vetores_embedding_hnsw_cosine_idx
  on processamento.vetores using hnsw (embedding extensions.vector_cosine_ops);

create table if not exists processamento.elementos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  documento_processado_id uuid not null,
  codigo text not null,
  tipo text not null,
  titulo text not null,
  descricao text not null,
  conteudo_estruturado jsonb,
  importancia numeric(5,4) not null,
  confianca numeric(5,4) not null,
  estado_revisao text not null default 'nao_revisado',
  modelo_ia_id uuid not null references sistema.modelos_ia(id) on delete restrict,
  versao_prompt_id uuid not null references sistema.versoes_prompts(id) on delete restrict,
  criado_em timestamptz not null default now(),
  constraint elementos_documento_usuario_fk foreign key (documento_processado_id, usuario_id)
    references processamento.documentos_processados(id, usuario_id) on delete cascade,
  constraint elementos_id_usuario_unique unique (id, usuario_id),
  constraint elementos_codigo_documento_unique unique (documento_processado_id, codigo),
  constraint elementos_tipo_check check (tipo in (
    'tema','conceito','ideia','tese','argumento','valor','principio','pergunta',
    'tensao','contradicao','conclusao','historia','experiencia','pessoa','personagem',
    'lugar','evento','metafora','analogia','contraste','frase_relevante',
    'padrao_linguistico','recurso_narrativo','estrutura_argumentativa',
    'mudanca_de_pensamento','referencia'
  )),
  constraint elementos_importancia_check check (importancia >= 0 and importancia <= 1),
  constraint elementos_confianca_check check (confianca >= 0 and confianca <= 1),
  constraint elementos_estado_revisao_check check (estado_revisao in ('nao_revisado','confirmado','editado','rejeitado')),
  constraint elementos_titulo_check check (length(trim(titulo)) > 0),
  constraint elementos_descricao_check check (length(trim(descricao)) > 0),
  constraint elementos_conteudo_estruturado_check check (conteudo_estruturado is null or jsonb_typeof(conteudo_estruturado) = 'object')
);

create index if not exists elementos_usuario_idx on processamento.elementos (usuario_id);
create index if not exists elementos_documento_usuario_idx on processamento.elementos (documento_processado_id, usuario_id);
create index if not exists elementos_tipo_estado_idx on processamento.elementos (usuario_id, tipo, estado_revisao);
create index if not exists elementos_modelo_idx on processamento.elementos (modelo_ia_id);
create index if not exists elementos_prompt_idx on processamento.elementos (versao_prompt_id);

create table if not exists processamento.evidencias (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  elemento_id uuid not null,
  fragmento_id uuid not null,
  pagina_inicial integer,
  pagina_final integer,
  trecho_referencia text not null,
  forca_evidencia numeric(5,4) not null,
  justificativa text,
  criado_em timestamptz not null default now(),
  constraint evidencias_elemento_usuario_fk foreign key (elemento_id, usuario_id)
    references processamento.elementos(id, usuario_id) on delete cascade,
  constraint evidencias_fragmento_usuario_fk foreign key (fragmento_id, usuario_id)
    references processamento.fragmentos(id, usuario_id) on delete restrict,
  constraint evidencias_forca_check check (forca_evidencia >= 0 and forca_evidencia <= 1),
  constraint evidencias_trecho_check check (length(trim(trecho_referencia)) > 0),
  constraint evidencias_paginas_check check (
    (pagina_inicial is null or pagina_inicial >= 1)
    and (pagina_final is null or pagina_final >= 1)
    and (pagina_inicial is null or pagina_final is null or pagina_final >= pagina_inicial)
  )
);

create index if not exists evidencias_usuario_idx on processamento.evidencias (usuario_id);
create index if not exists evidencias_elemento_usuario_idx on processamento.evidencias (elemento_id, usuario_id);
create index if not exists evidencias_fragmento_usuario_idx on processamento.evidencias (fragmento_id, usuario_id);

create table if not exists processamento.relacoes_elementos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  elemento_origem_id uuid not null,
  tipo_relacao text not null,
  elemento_destino_id uuid not null,
  confianca numeric(5,4) not null,
  justificativa text,
  criado_em timestamptz not null default now(),
  constraint relacoes_elementos_origem_usuario_fk foreign key (elemento_origem_id, usuario_id)
    references processamento.elementos(id, usuario_id) on delete cascade,
  constraint relacoes_elementos_destino_usuario_fk foreign key (elemento_destino_id, usuario_id)
    references processamento.elementos(id, usuario_id) on delete cascade,
  constraint relacoes_elementos_tipo_check check (tipo_relacao in (
    'sustenta','contradiz','expande','deriva_de','exemplifica','questiona',
    'responde_a','evolui_para','associa_se_a','reformula'
  )),
  constraint relacoes_elementos_confianca_check check (confianca >= 0 and confianca <= 1),
  constraint relacoes_elementos_nao_reflexiva_check check (elemento_origem_id <> elemento_destino_id),
  constraint relacoes_elementos_unique unique (usuario_id, elemento_origem_id, tipo_relacao, elemento_destino_id)
);

create index if not exists relacoes_elementos_usuario_idx on processamento.relacoes_elementos (usuario_id);
create index if not exists relacoes_elementos_origem_usuario_idx on processamento.relacoes_elementos (elemento_origem_id, usuario_id);
create index if not exists relacoes_elementos_destino_usuario_idx on processamento.relacoes_elementos (elemento_destino_id, usuario_id);
create index if not exists relacoes_elementos_tipo_idx on processamento.relacoes_elementos (usuario_id, tipo_relacao);

alter table taxonomia.classificacoes_elementos
  add constraint classificacoes_elementos_elemento_usuario_fk
  foreign key (elemento_id, usuario_id)
  references processamento.elementos(id, usuario_id)
  on delete cascade;

alter table processamento.vetores enable row level security;
alter table processamento.elementos enable row level security;
alter table processamento.evidencias enable row level security;
alter table processamento.relacoes_elementos enable row level security;

drop policy if exists vetores_selecionar_proprios on processamento.vetores;
create policy vetores_selecionar_proprios
  on processamento.vetores for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists vetores_inserir_proprios on processamento.vetores;
create policy vetores_inserir_proprios
  on processamento.vetores for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists vetores_atualizar_proprios on processamento.vetores;
create policy vetores_atualizar_proprios
  on processamento.vetores for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists vetores_excluir_proprios on processamento.vetores;
create policy vetores_excluir_proprios
  on processamento.vetores for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists elementos_selecionar_proprios on processamento.elementos;
create policy elementos_selecionar_proprios
  on processamento.elementos for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists elementos_inserir_proprios on processamento.elementos;
create policy elementos_inserir_proprios
  on processamento.elementos for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists elementos_atualizar_proprios on processamento.elementos;
create policy elementos_atualizar_proprios
  on processamento.elementos for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists elementos_excluir_proprios on processamento.elementos;
create policy elementos_excluir_proprios
  on processamento.elementos for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists evidencias_selecionar_proprias on processamento.evidencias;
create policy evidencias_selecionar_proprias
  on processamento.evidencias for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists evidencias_inserir_proprias on processamento.evidencias;
create policy evidencias_inserir_proprias
  on processamento.evidencias for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists evidencias_atualizar_proprias on processamento.evidencias;
create policy evidencias_atualizar_proprias
  on processamento.evidencias for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists evidencias_excluir_proprias on processamento.evidencias;
create policy evidencias_excluir_proprias
  on processamento.evidencias for delete to authenticated using ((select auth.uid()) = usuario_id);

drop policy if exists relacoes_elementos_selecionar_proprias on processamento.relacoes_elementos;
create policy relacoes_elementos_selecionar_proprias
  on processamento.relacoes_elementos for select to authenticated using ((select auth.uid()) = usuario_id);
drop policy if exists relacoes_elementos_inserir_proprias on processamento.relacoes_elementos;
create policy relacoes_elementos_inserir_proprias
  on processamento.relacoes_elementos for insert to authenticated with check ((select auth.uid()) = usuario_id);
drop policy if exists relacoes_elementos_atualizar_proprias on processamento.relacoes_elementos;
create policy relacoes_elementos_atualizar_proprias
  on processamento.relacoes_elementos for update to authenticated using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
drop policy if exists relacoes_elementos_excluir_proprias on processamento.relacoes_elementos;
create policy relacoes_elementos_excluir_proprias
  on processamento.relacoes_elementos for delete to authenticated using ((select auth.uid()) = usuario_id);

revoke all on all tables in schema processamento from public, anon, authenticated;
revoke all on all sequences in schema processamento from public, anon, authenticated;
revoke all on all functions in schema processamento from public, anon, authenticated;


-- ==========================================
-- File: 20260916200419_0014_indice_fk_taxonomia_elementos.sql
-- ==========================================

-- 0014_indice_fk_taxonomia_elementos
-- Índice dedicado para a FK composta adicionada em 0013.

create index if not exists classificacoes_elementos_elemento_usuario_idx
  on taxonomia.classificacoes_elementos (elemento_id, usuario_id);


-- ==========================================
-- File: 20260916200813_0015_integridade_proveniencia_publicacao.sql
-- ==========================================

-- 0015_integridade_proveniencia_publicacao
-- Evidências só podem apontar para fragmentos do mesmo Documento Processado.
-- Documento Processado ativo exige timestamp de publicação.

alter table processamento.documentos_processados
  add constraint documentos_processados_publicacao_ativa_check
  check (estado <> 'ativo' or publicado_em is not null);

create or replace function processamento.validar_evidencia_mesmo_documento()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  documento_elemento uuid;
  documento_fragmento uuid;
begin
  select e.documento_processado_id
    into documento_elemento
  from processamento.elementos e
  where e.id = new.elemento_id
    and e.usuario_id = new.usuario_id;

  select f.documento_processado_id
    into documento_fragmento
  from processamento.fragmentos f
  where f.id = new.fragmento_id
    and f.usuario_id = new.usuario_id;

  if documento_elemento is null or documento_fragmento is null then
    raise exception using errcode = '23503', message = 'evidencia_referencia_invalida';
  end if;

  if documento_elemento <> documento_fragmento then
    raise exception using errcode = '23514', message = 'evidencia_deve_referenciar_fragmento_do_mesmo_documento';
  end if;

  return new;
end;
$$;

revoke all on function processamento.validar_evidencia_mesmo_documento()
  from public, anon, authenticated;

drop trigger if exists evidencias_mesmo_documento_trigger on processamento.evidencias;
create trigger evidencias_mesmo_documento_trigger
before insert or update of usuario_id, elemento_id, fragmento_id
on processamento.evidencias
for each row
execute function processamento.validar_evidencia_mesmo_documento();


-- ==========================================
-- File: 20260916200935_0016_deduplicacao_hash_biblioteca.sql
-- ==========================================

-- 0016_deduplicacao_hash_biblioteca
-- Deduplicação por usuario+SHA-256 com lock transacional, sem transformar o índice
-- recomendado pelo Dicionário em uma restrição UNIQUE estrutural.

create or replace function aplicacao.registrar_obra_arquivo(
  p_obra_id uuid,
  p_versao_id uuid,
  p_titulo text,
  p_tipo_obra text,
  p_autoria text,
  p_participacao_cerebro text,
  p_idioma text,
  p_nome_arquivo text,
  p_caminho_arquivo text,
  p_tipo_mime text,
  p_tamanho_bytes bigint,
  p_hash_sha256 text,
  p_extensao text default null,
  p_descricao text default null,
  p_data_producao date default null,
  p_autor_original text default null
)
returns table (
  obra_id uuid,
  obra_codigo text,
  versao_id uuid,
  versao_codigo text,
  caminho_arquivo text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid := auth.uid();
  v_extensao text;
  v_nome_original_storage text;
  v_caminho_esperado text;
  v_obra_codigo text;
  v_versao_codigo text;
  v_hash_normalizado text;
begin
  if v_usuario_id is null then
    raise exception 'Autenticacao obrigatoria' using errcode = '42501';
  end if;
  if p_obra_id is null or p_versao_id is null then
    raise exception 'Identificadores de obra e versao sao obrigatorios' using errcode = '22023';
  end if;
  if nullif(trim(p_titulo), '') is null then
    raise exception 'Titulo obrigatorio' using errcode = '22023';
  end if;
  if nullif(trim(p_nome_arquivo), '') is null then
    raise exception 'Nome de arquivo obrigatorio' using errcode = '22023';
  end if;
  if nullif(trim(p_tipo_mime), '') is null then
    raise exception 'Tipo MIME obrigatorio' using errcode = '22023';
  end if;
  if nullif(trim(p_idioma), '') is null then
    raise exception 'Idioma obrigatorio' using errcode = '22023';
  end if;
  if p_tamanho_bytes < 0 then
    raise exception 'Tamanho de arquivo invalido' using errcode = '22023';
  end if;
  if p_hash_sha256 !~ '^[0-9A-Fa-f]{64}$' then
    raise exception 'Hash SHA-256 invalido' using errcode = '22023';
  end if;

  v_hash_normalizado := lower(p_hash_sha256);

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_usuario_id::text || ':' || v_hash_normalizado, 0)
  );

  if exists (
    select 1 from biblioteca.versoes_obras vo
    where vo.usuario_id = v_usuario_id
      and vo.hash_sha256 = v_hash_normalizado
  ) then
    raise exception using errcode = '23505', message = 'arquivo_duplicado_por_hash';
  end if;

  v_extensao := nullif(lower(regexp_replace(coalesce(trim(p_extensao), ''), '^\.+', '')), '');
  v_nome_original_storage := 'original' || case when v_extensao is null then '' else '.' || v_extensao end;
  v_caminho_esperado := v_usuario_id::text || '/' || p_obra_id::text || '/' || p_versao_id::text || '/' || v_nome_original_storage;

  if p_caminho_arquivo <> v_caminho_esperado then
    raise exception 'Caminho de arquivo nao corresponde ao usuario/obra/versao autenticados' using errcode = '22023';
  end if;

  if not exists (
    select 1 from storage.objects so
    where so.bucket_id = 'originais-biblioteca'
      and so.name = v_caminho_esperado
  ) then
    raise exception 'Arquivo original nao encontrado no Storage privado' using errcode = '22023';
  end if;

  v_obra_codigo := 'OBR-' || upper(substr(replace(p_obra_id::text, '-', ''), 1, 12));
  v_versao_codigo := 'VOB-' || upper(substr(replace(p_versao_id::text, '-', ''), 1, 12));

  insert into biblioteca.obras (
    id, usuario_id, codigo, titulo_original, titulo_exibicao, titulo_normalizado,
    tipo_obra, autoria, participacao_cerebro, autor_original, idioma, descricao,
    data_producao, precisao_data, estado
  ) values (
    p_obra_id, v_usuario_id, v_obra_codigo, trim(p_titulo), trim(p_titulo),
    lower(extensions.unaccent(trim(p_titulo))), p_tipo_obra, p_autoria,
    p_participacao_cerebro, nullif(trim(p_autor_original), ''), trim(p_idioma),
    nullif(trim(p_descricao), ''), p_data_producao,
    case when p_data_producao is null then 'desconhecida' else 'exata' end,
    'ativa'
  );

  insert into biblioteca.versoes_obras (
    id, usuario_id, obra_id, codigo, numero_versao, nome_arquivo, caminho_arquivo,
    tipo_mime, extensao, tamanho_bytes, hash_sha256, estado_processamento
  ) values (
    p_versao_id, v_usuario_id, p_obra_id, v_versao_codigo, 1, trim(p_nome_arquivo),
    v_caminho_esperado, trim(p_tipo_mime), v_extensao, p_tamanho_bytes,
    v_hash_normalizado, 'recebido'
  );

  return query
  select p_obra_id, v_obra_codigo, p_versao_id, v_versao_codigo, v_caminho_esperado;
end;
$$;

revoke all on function aplicacao.registrar_obra_arquivo(
  uuid, uuid, text, text, text, text, text, text, text, text, bigint, text, text, text, date, text
) from public, anon, authenticated;

grant execute on function aplicacao.registrar_obra_arquivo(
  uuid, uuid, text, text, text, text, text, text, text, text, bigint, text, text, text, date, text
) to authenticated;


-- ==========================================
-- File: 20260916202853_0017_api_backend_workflow_processamento.sql
-- ==========================================

-- 0017_api_backend_workflow_processamento
-- Operações server-only do workflow. Nenhuma função abaixo é executável pelo navegador.

create or replace function aplicacao.backend_iniciar_processamento(
  p_usuario_id uuid,
  p_versao_obra_id uuid
)
returns table (
  execucao_id uuid,
  execucao_codigo text,
  estado text,
  criada boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pipeline_id uuid;
  v_taxonomia_id uuid;
  v_execucao_id uuid;
  v_execucao_codigo text;
  v_estado text;
begin
  if p_usuario_id is null or p_versao_obra_id is null then
    raise exception 'usuario_e_versao_obrigatorios' using errcode = '22023';
  end if;

  if not exists (
    select 1 from biblioteca.versoes_obras vo
    where vo.id = p_versao_obra_id and vo.usuario_id = p_usuario_id
  ) then
    raise exception 'versao_obra_nao_encontrada' using errcode = 'P0002';
  end if;

  select vp.id into v_pipeline_id
  from sistema.versoes_pipeline vp
  where vp.estado = 'ativa'
  order by vp.ativado_em desc nulls last, vp.criado_em desc
  limit 1;

  select vt.id into v_taxonomia_id
  from taxonomia.versoes vt
  where vt.estado = 'ativa'
  order by vt.ativado_em desc nulls last, vt.criado_em desc
  limit 1;

  if v_pipeline_id is null then
    raise exception 'pipeline_ativo_nao_encontrado' using errcode = 'P0002';
  end if;
  if v_taxonomia_id is null then
    raise exception 'taxonomia_ativa_nao_encontrada' using errcode = 'P0002';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_usuario_id::text || ':' || p_versao_obra_id::text || ':' || v_pipeline_id::text || ':' || v_taxonomia_id::text,
      0
    )
  );

  select e.id, e.codigo, e.estado
    into v_execucao_id, v_execucao_codigo, v_estado
  from processamento.execucoes e
  where e.usuario_id = p_usuario_id
    and e.versao_obra_id = p_versao_obra_id
    and e.versao_pipeline_id = v_pipeline_id
    and e.versao_taxonomia_id = v_taxonomia_id
  order by e.criado_em desc
  limit 1;

  if v_execucao_id is not null then
    return query select v_execucao_id, v_execucao_codigo, v_estado, false;
    return;
  end if;

  v_execucao_id := gen_random_uuid();
  v_execucao_codigo := 'EXE-' || upper(substr(replace(v_execucao_id::text, '-', ''), 1, 12));

  insert into processamento.execucoes (
    id, usuario_id, versao_obra_id, codigo, estado, etapa_atual, percentual,
    versao_pipeline_id, versao_taxonomia_id, iniciado_em, criado_em
  ) values (
    v_execucao_id, p_usuario_id, p_versao_obra_id, v_execucao_codigo,
    'recebido', 'validar_arquivo', 0, v_pipeline_id, v_taxonomia_id, now(), now()
  );

  insert into processamento.etapas_execucao (
    usuario_id, execucao_id, nome_etapa, ordem, chave_idempotencia,
    estado, tentativas, criado_em
  )
  select
    p_usuario_id,
    v_execucao_id,
    etapas.nome_etapa,
    etapas.ordem::integer,
    p_usuario_id::text || ':' || p_versao_obra_id::text || ':' ||
      v_pipeline_id::text || ':' || v_taxonomia_id::text || ':' || etapas.nome_etapa,
    'pendente',
    0,
    now()
  from unnest(array[
    'validar_arquivo','identificar_formato','extrair_conteudo','normalizar_conteudo',
    'identificar_estrutura','criar_hierarquia','criar_fragmentos','criar_sinteses',
    'extrair_elementos','classificar_taxonomia','criar_embeddings','criar_relacoes',
    'validar_resultado','publicar_documento'
  ]::text[]) with ordinality as etapas(nome_etapa, ordem)
  on conflict (chave_idempotencia) do nothing;

  update biblioteca.versoes_obras
  set estado_processamento = 'em_processamento'
  where id = p_versao_obra_id and usuario_id = p_usuario_id;

  return query select v_execucao_id, v_execucao_codigo, 'recebido'::text, true;
end;
$$;

create or replace function aplicacao.backend_obter_execucao(p_execucao_id uuid)
returns table (
  execucao_id uuid,
  usuario_id uuid,
  versao_obra_id uuid,
  obra_id uuid,
  estado text,
  etapa_atual text,
  versao_pipeline_id uuid,
  versao_taxonomia_id uuid,
  caminho_arquivo text,
  hash_sha256 text,
  tamanho_bytes bigint,
  tipo_mime text,
  nome_arquivo text
)
language sql
security definer
set search_path = ''
as $$
  select e.id, e.usuario_id, e.versao_obra_id, vo.obra_id, e.estado, e.etapa_atual,
         e.versao_pipeline_id, e.versao_taxonomia_id, vo.caminho_arquivo,
         vo.hash_sha256, vo.tamanho_bytes, vo.tipo_mime, vo.nome_arquivo
  from processamento.execucoes e
  join biblioteca.versoes_obras vo
    on vo.id = e.versao_obra_id and vo.usuario_id = e.usuario_id
  where e.id = p_execucao_id
  limit 1
$$;

create or replace function aplicacao.backend_iniciar_etapa(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_estado_execucao text,
  p_percentual numeric
)
returns table (deve_executar boolean, tentativas integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado_etapa text;
  v_tentativas integer;
begin
  select ee.estado, ee.tentativas into v_estado_etapa, v_tentativas
  from processamento.etapas_execucao ee
  where ee.execucao_id = p_execucao_id and ee.nome_etapa = p_nome_etapa;

  if v_estado_etapa is null then
    raise exception 'etapa_nao_encontrada' using errcode = 'P0002';
  end if;

  if v_estado_etapa in ('concluida', 'ignorada', 'cancelada') then
    return query select false, v_tentativas;
    return;
  end if;

  update processamento.etapas_execucao
  set estado = 'executando',
      tentativas = tentativas + 1,
      iniciado_em = now(),
      concluido_em = null,
      duracao_ms = null
  where execucao_id = p_execucao_id and nome_etapa = p_nome_etapa
  returning processamento.etapas_execucao.tentativas into v_tentativas;

  update processamento.execucoes
  set estado = p_estado_execucao,
      etapa_atual = p_nome_etapa,
      percentual = p_percentual,
      concluido_em = null,
      codigo_erro = null,
      mensagem_erro = null
  where id = p_execucao_id;

  return query select true, v_tentativas;
end;
$$;

create or replace function aplicacao.backend_concluir_etapa(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_percentual numeric,
  p_proximo_estado text,
  p_proxima_etapa text,
  p_detalhes jsonb default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_atualizados integer;
begin
  if p_detalhes is not null and jsonb_typeof(p_detalhes) <> 'object' then
    raise exception 'detalhes_devem_ser_objeto' using errcode = '22023';
  end if;

  update processamento.etapas_execucao
  set estado = 'concluida',
      concluido_em = coalesce(concluido_em, now()),
      duracao_ms = case
        when iniciado_em is null then duracao_ms
        else greatest(0, (extract(epoch from (coalesce(concluido_em, now()) - iniciado_em)) * 1000)::bigint)
      end,
      detalhes_auxiliares = coalesce(p_detalhes, detalhes_auxiliares)
  where execucao_id = p_execucao_id
    and nome_etapa = p_nome_etapa
    and estado <> 'concluida';

  get diagnostics v_atualizados = row_count;

  update processamento.execucoes
  set estado = p_proximo_estado,
      etapa_atual = p_proxima_etapa,
      percentual = p_percentual
  where id = p_execucao_id and estado <> 'falhou';

  return v_atualizados > 0;
end;
$$;

create or replace function aplicacao.backend_falhar_execucao(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_codigo_erro text,
  p_mensagem_erro text,
  p_detalhes jsonb default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid;
  v_versao_obra_id uuid;
begin
  if p_detalhes is not null and jsonb_typeof(p_detalhes) <> 'object' then
    raise exception 'detalhes_devem_ser_objeto' using errcode = '22023';
  end if;

  select e.usuario_id, e.versao_obra_id into v_usuario_id, v_versao_obra_id
  from processamento.execucoes e where e.id = p_execucao_id;

  if v_usuario_id is null then return false; end if;

  update processamento.etapas_execucao
  set estado = 'falhou',
      concluido_em = now(),
      duracao_ms = case
        when iniciado_em is null then duracao_ms
        else greatest(0, (extract(epoch from (now() - iniciado_em)) * 1000)::bigint)
      end,
      detalhes_auxiliares = coalesce(p_detalhes, detalhes_auxiliares)
  where execucao_id = p_execucao_id
    and nome_etapa = p_nome_etapa
    and estado <> 'concluida';

  update processamento.execucoes
  set estado = 'falhou',
      etapa_atual = p_nome_etapa,
      concluido_em = now(),
      codigo_erro = left(coalesce(p_codigo_erro, 'PROCESSAMENTO_FALHOU'), 120),
      mensagem_erro = left(coalesce(p_mensagem_erro, 'Falha no processamento'), 500)
  where id = p_execucao_id;

  update biblioteca.versoes_obras
  set estado_processamento = 'falhou'
  where id = v_versao_obra_id and usuario_id = v_usuario_id;

  return true;
end;
$$;

revoke all on function aplicacao.backend_iniciar_processamento(uuid, uuid) from public, anon, authenticated;
revoke all on function aplicacao.backend_obter_execucao(uuid) from public, anon, authenticated;
revoke all on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) from public, anon, authenticated;
revoke all on function aplicacao.backend_concluir_etapa(uuid, text, numeric, text, text, jsonb) from public, anon, authenticated;
revoke all on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) from public, anon, authenticated;

grant execute on function aplicacao.backend_iniciar_processamento(uuid, uuid) to service_role;
grant execute on function aplicacao.backend_obter_execucao(uuid) to service_role;
grant execute on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) to service_role;
grant execute on function aplicacao.backend_concluir_etapa(uuid, text, numeric, text, text, jsonb) to service_role;
grant execute on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) to service_role;


-- ==========================================
-- File: 20260916212133_0018_recuperacao_orquestracao_workflow.sql
-- ==========================================

-- 0018_recuperacao_orquestracao_workflow
-- Reserva de disparo, recuperação de execuções e estado coerente do workflow durável.

alter table processamento.execucoes
  add column if not exists workflow_reservado_em timestamptz,
  add column if not exists workflow_iniciado_em timestamptz,
  add column if not exists workflow_tentativas integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'execucoes_workflow_tentativas_check'
      and conrelid = 'processamento.execucoes'::regclass
  ) then
    alter table processamento.execucoes
      add constraint execucoes_workflow_tentativas_check
      check (workflow_tentativas >= 0);
  end if;
end $$;

comment on column processamento.execucoes.workflow_reservado_em is
  'Reserva curta para impedir disparos concorrentes do mesmo workflow; pode ser retomada quando expirada.';
comment on column processamento.execucoes.workflow_iniciado_em is
  'Momento em que o backend confirmou o início do workflow durável.';
comment on column processamento.execucoes.workflow_tentativas is
  'Quantidade de tentativas de disparo/reinício do workflow durável.';

drop function if exists aplicacao.backend_iniciar_processamento(uuid, uuid);

create or replace function aplicacao.backend_iniciar_processamento(
  p_usuario_id uuid,
  p_versao_obra_id uuid
)
returns table (
  execucao_id uuid,
  execucao_codigo text,
  estado text,
  criada boolean,
  deve_iniciar_workflow boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pipeline_id uuid;
  v_taxonomia_id uuid;
  v_execucao_id uuid;
  v_execucao_codigo text;
  v_estado text;
  v_workflow_reservado_em timestamptz;
  v_workflow_iniciado_em timestamptz;
  v_etapa_estado text;
  v_etapa_tentativas integer;
begin
  if p_usuario_id is null or p_versao_obra_id is null then
    raise exception 'usuario_e_versao_obrigatorios' using errcode = '22023';
  end if;

  if not exists (
    select 1 from biblioteca.versoes_obras vo
    where vo.id = p_versao_obra_id and vo.usuario_id = p_usuario_id
  ) then
    raise exception 'versao_obra_nao_encontrada' using errcode = 'P0002';
  end if;

  select vp.id into v_pipeline_id
  from sistema.versoes_pipeline vp
  where vp.estado = 'ativa'
  order by vp.ativado_em desc nulls last, vp.criado_em desc
  limit 1;

  select vt.id into v_taxonomia_id
  from taxonomia.versoes vt
  where vt.estado = 'ativa'
  order by vt.ativado_em desc nulls last, vt.criado_em desc
  limit 1;

  if v_pipeline_id is null then
    raise exception 'pipeline_ativo_nao_encontrado' using errcode = 'P0002';
  end if;
  if v_taxonomia_id is null then
    raise exception 'taxonomia_ativa_nao_encontrada' using errcode = 'P0002';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_usuario_id::text || ':' || p_versao_obra_id::text || ':' || v_pipeline_id::text || ':' || v_taxonomia_id::text,
      0
    )
  );

  select e.id, e.codigo, e.estado, e.workflow_reservado_em, e.workflow_iniciado_em
    into v_execucao_id, v_execucao_codigo, v_estado, v_workflow_reservado_em, v_workflow_iniciado_em
  from processamento.execucoes e
  where e.usuario_id = p_usuario_id
    and e.versao_obra_id = p_versao_obra_id
    and e.versao_pipeline_id = v_pipeline_id
    and e.versao_taxonomia_id = v_taxonomia_id
  order by e.criado_em desc
  limit 1;

  if v_execucao_id is not null then
    select ee.estado, ee.tentativas
      into v_etapa_estado, v_etapa_tentativas
    from processamento.etapas_execucao ee
    where ee.execucao_id = v_execucao_id
      and ee.nome_etapa = 'validar_arquivo';

    if v_estado = 'concluido' then
      return query select v_execucao_id, v_execucao_codigo, v_estado, false, false;
      return;
    end if;

    if v_estado not in ('falhou', 'cancelado') then
      if v_workflow_iniciado_em is not null or coalesce(v_etapa_tentativas, 0) > 0 then
        return query select v_execucao_id, v_execucao_codigo, v_estado, false, false;
        return;
      end if;

      if v_workflow_reservado_em is not null
         and v_workflow_reservado_em > now() - interval '5 minutes' then
        return query select v_execucao_id, v_execucao_codigo, v_estado, false, false;
        return;
      end if;
    end if;

    update processamento.execucoes
    set estado = 'recebido',
        concluido_em = null,
        codigo_erro = null,
        mensagem_erro = null,
        workflow_reservado_em = now(),
        workflow_iniciado_em = null,
        workflow_tentativas = workflow_tentativas + 1
    where id = v_execucao_id;

    if v_estado = 'cancelado' then
      update processamento.etapas_execucao
      set estado = 'pendente',
          iniciado_em = null,
          concluido_em = null,
          duracao_ms = null
      where execucao_id = v_execucao_id
        and estado = 'cancelada';
    end if;

    update biblioteca.versoes_obras
    set estado_processamento = 'em_processamento'
    where id = p_versao_obra_id and usuario_id = p_usuario_id;

    return query select v_execucao_id, v_execucao_codigo, 'recebido'::text, false, true;
    return;
  end if;

  v_execucao_id := gen_random_uuid();
  v_execucao_codigo := 'EXE-' || upper(substr(replace(v_execucao_id::text, '-', ''), 1, 12));

  insert into processamento.execucoes (
    id, usuario_id, versao_obra_id, codigo, estado, etapa_atual, percentual,
    versao_pipeline_id, versao_taxonomia_id, iniciado_em, criado_em,
    workflow_reservado_em, workflow_tentativas
  ) values (
    v_execucao_id, p_usuario_id, p_versao_obra_id, v_execucao_codigo,
    'recebido', 'validar_arquivo', 0, v_pipeline_id, v_taxonomia_id, now(), now(),
    now(), 1
  );

  insert into processamento.etapas_execucao (
    usuario_id, execucao_id, nome_etapa, ordem, chave_idempotencia,
    estado, tentativas, criado_em
  )
  select
    p_usuario_id,
    v_execucao_id,
    etapas.nome_etapa,
    etapas.ordem::integer,
    p_usuario_id::text || ':' || p_versao_obra_id::text || ':' ||
      v_pipeline_id::text || ':' || v_taxonomia_id::text || ':' || etapas.nome_etapa,
    'pendente',
    0,
    now()
  from unnest(array[
    'validar_arquivo','identificar_formato','extrair_conteudo','normalizar_conteudo',
    'identificar_estrutura','criar_hierarquia','criar_fragmentos','criar_sinteses',
    'extrair_elementos','classificar_taxonomia','criar_embeddings','criar_relacoes',
    'validar_resultado','publicar_documento'
  ]::text[]) with ordinality as etapas(nome_etapa, ordem)
  on conflict (chave_idempotencia) do nothing;

  update biblioteca.versoes_obras
  set estado_processamento = 'em_processamento'
  where id = p_versao_obra_id and usuario_id = p_usuario_id;

  return query select v_execucao_id, v_execucao_codigo, 'recebido'::text, true, true;
end;
$$;

create or replace function aplicacao.backend_registrar_workflow_iniciado(
  p_execucao_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_atualizados integer;
begin
  update processamento.execucoes
  set workflow_iniciado_em = coalesce(workflow_iniciado_em, now()),
      workflow_reservado_em = null
  where id = p_execucao_id
    and estado not in ('concluido', 'cancelado');

  get diagnostics v_atualizados = row_count;
  return v_atualizados > 0;
end;
$$;

create or replace function aplicacao.backend_iniciar_etapa(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_estado_execucao text,
  p_percentual numeric
)
returns table (deve_executar boolean, tentativas integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado_etapa text;
  v_tentativas integer;
  v_usuario_id uuid;
  v_versao_obra_id uuid;
begin
  select ee.estado, ee.tentativas into v_estado_etapa, v_tentativas
  from processamento.etapas_execucao ee
  where ee.execucao_id = p_execucao_id and ee.nome_etapa = p_nome_etapa;

  if v_estado_etapa is null then
    raise exception 'etapa_nao_encontrada' using errcode = 'P0002';
  end if;

  if v_estado_etapa in ('concluida', 'ignorada', 'cancelada') then
    return query select false, v_tentativas;
    return;
  end if;

  update processamento.etapas_execucao
  set estado = 'executando',
      tentativas = tentativas + 1,
      iniciado_em = now(),
      concluido_em = null,
      duracao_ms = null
  where execucao_id = p_execucao_id and nome_etapa = p_nome_etapa
  returning processamento.etapas_execucao.tentativas into v_tentativas;

  update processamento.execucoes
  set estado = p_estado_execucao,
      etapa_atual = p_nome_etapa,
      percentual = p_percentual,
      concluido_em = null,
      codigo_erro = null,
      mensagem_erro = null,
      workflow_iniciado_em = coalesce(workflow_iniciado_em, now()),
      workflow_reservado_em = null
  where id = p_execucao_id
  returning usuario_id, versao_obra_id into v_usuario_id, v_versao_obra_id;

  update biblioteca.versoes_obras
  set estado_processamento = 'em_processamento'
  where id = v_versao_obra_id and usuario_id = v_usuario_id;

  return query select true, v_tentativas;
end;
$$;

create or replace function aplicacao.backend_falhar_execucao(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_codigo_erro text,
  p_mensagem_erro text,
  p_detalhes jsonb default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid;
  v_versao_obra_id uuid;
begin
  if p_detalhes is not null and jsonb_typeof(p_detalhes) <> 'object' then
    raise exception 'detalhes_devem_ser_objeto' using errcode = '22023';
  end if;

  select e.usuario_id, e.versao_obra_id into v_usuario_id, v_versao_obra_id
  from processamento.execucoes e where e.id = p_execucao_id;

  if v_usuario_id is null then return false; end if;

  update processamento.etapas_execucao
  set estado = 'falhou',
      concluido_em = now(),
      duracao_ms = case
        when iniciado_em is null then duracao_ms
        else greatest(0, (extract(epoch from (now() - iniciado_em)) * 1000)::bigint)
      end,
      detalhes_auxiliares = coalesce(p_detalhes, detalhes_auxiliares)
  where execucao_id = p_execucao_id
    and nome_etapa = p_nome_etapa
    and estado <> 'concluida';

  update processamento.execucoes
  set estado = 'falhou',
      etapa_atual = p_nome_etapa,
      concluido_em = now(),
      codigo_erro = left(coalesce(p_codigo_erro, 'PROCESSAMENTO_FALHOU'), 120),
      mensagem_erro = left(coalesce(p_mensagem_erro, 'Falha no processamento'), 500),
      workflow_reservado_em = null
  where id = p_execucao_id;

  update biblioteca.versoes_obras
  set estado_processamento = 'falhou'
  where id = v_versao_obra_id and usuario_id = v_usuario_id;

  return true;
end;
$$;

revoke all on function aplicacao.backend_iniciar_processamento(uuid, uuid) from public, anon, authenticated;
revoke all on function aplicacao.backend_registrar_workflow_iniciado(uuid) from public, anon, authenticated;
revoke all on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) from public, anon, authenticated;
revoke all on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) from public, anon, authenticated;

grant execute on function aplicacao.backend_iniciar_processamento(uuid, uuid) to service_role;
grant execute on function aplicacao.backend_registrar_workflow_iniciado(uuid) to service_role;
grant execute on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) to service_role;
grant execute on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) to service_role;


-- ==========================================
-- File: 20260916221057_0019_idempotencia_transicoes_workflow.sql
-- ==========================================

-- 0019_idempotencia_transicoes_workflow
-- Endurece as transições do workflow contra chamadas atrasadas, replays e regressão de estado.

create or replace function aplicacao.backend_registrar_workflow_iniciado(
  p_execucao_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_atualizados integer;
begin
  update processamento.execucoes
  set workflow_iniciado_em = coalesce(workflow_iniciado_em, now()),
      workflow_reservado_em = null
  where id = p_execucao_id
    and estado not in ('concluido', 'cancelado', 'falhou');

  get diagnostics v_atualizados = row_count;
  return v_atualizados > 0;
end;
$$;

create or replace function aplicacao.backend_iniciar_etapa(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_estado_execucao text,
  p_percentual numeric
)
returns table (deve_executar boolean, tentativas integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado_execucao text;
  v_etapa_atual text;
  v_estado_etapa text;
  v_tentativas integer;
  v_usuario_id uuid;
  v_versao_obra_id uuid;
begin
  select e.estado, e.etapa_atual, e.usuario_id, e.versao_obra_id
    into v_estado_execucao, v_etapa_atual, v_usuario_id, v_versao_obra_id
  from processamento.execucoes e
  where e.id = p_execucao_id
  for update;

  if v_usuario_id is null then
    raise exception 'execucao_nao_encontrada' using errcode = 'P0002';
  end if;

  select ee.estado, ee.tentativas
    into v_estado_etapa, v_tentativas
  from processamento.etapas_execucao ee
  where ee.execucao_id = p_execucao_id and ee.nome_etapa = p_nome_etapa
  for update;

  if v_estado_etapa is null then
    raise exception 'etapa_nao_encontrada' using errcode = 'P0002';
  end if;

  if v_estado_execucao in ('concluido', 'cancelado', 'falhou')
     or v_estado_etapa in ('concluida', 'ignorada', 'cancelada')
     or v_etapa_atual is distinct from p_nome_etapa then
    return query select false, v_tentativas;
    return;
  end if;

  update processamento.etapas_execucao
  set estado = 'executando',
      tentativas = tentativas + 1,
      iniciado_em = coalesce(iniciado_em, now()),
      concluido_em = null,
      duracao_ms = null
  where execucao_id = p_execucao_id and nome_etapa = p_nome_etapa
  returning processamento.etapas_execucao.tentativas into v_tentativas;

  update processamento.execucoes
  set estado = p_estado_execucao,
      etapa_atual = p_nome_etapa,
      percentual = greatest(percentual, p_percentual),
      concluido_em = null,
      codigo_erro = null,
      mensagem_erro = null,
      workflow_iniciado_em = coalesce(workflow_iniciado_em, now()),
      workflow_reservado_em = null
  where id = p_execucao_id;

  update biblioteca.versoes_obras
  set estado_processamento = 'em_processamento'
  where id = v_versao_obra_id and usuario_id = v_usuario_id;

  return query select true, v_tentativas;
end;
$$;

create or replace function aplicacao.backend_concluir_etapa(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_percentual numeric,
  p_proximo_estado text,
  p_proxima_etapa text,
  p_detalhes jsonb default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado_execucao text;
  v_etapa_atual text;
  v_estado_etapa text;
  v_atualizados integer;
begin
  if p_detalhes is not null and jsonb_typeof(p_detalhes) <> 'object' then
    raise exception 'detalhes_devem_ser_objeto' using errcode = '22023';
  end if;

  select e.estado, e.etapa_atual
    into v_estado_execucao, v_etapa_atual
  from processamento.execucoes e
  where e.id = p_execucao_id
  for update;

  if v_estado_execucao is null then
    return false;
  end if;

  if v_estado_execucao in ('concluido', 'cancelado', 'falhou')
     or v_etapa_atual is distinct from p_nome_etapa then
    return false;
  end if;

  select ee.estado into v_estado_etapa
  from processamento.etapas_execucao ee
  where ee.execucao_id = p_execucao_id and ee.nome_etapa = p_nome_etapa
  for update;

  if v_estado_etapa is distinct from 'executando' then
    return false;
  end if;

  update processamento.etapas_execucao
  set estado = 'concluida',
      concluido_em = now(),
      duracao_ms = case
        when iniciado_em is null then duracao_ms
        else greatest(0, (extract(epoch from (now() - iniciado_em)) * 1000)::bigint)
      end,
      detalhes_auxiliares = coalesce(p_detalhes, detalhes_auxiliares)
  where execucao_id = p_execucao_id
    and nome_etapa = p_nome_etapa
    and estado = 'executando';

  get diagnostics v_atualizados = row_count;
  if v_atualizados = 0 then
    return false;
  end if;

  update processamento.execucoes
  set estado = p_proximo_estado,
      etapa_atual = p_proxima_etapa,
      percentual = greatest(percentual, p_percentual),
      concluido_em = case
        when p_proximo_estado in ('concluido', 'falhou', 'cancelado') then now()
        else null
      end
  where id = p_execucao_id;

  return true;
end;
$$;

create or replace function aplicacao.backend_falhar_execucao(
  p_execucao_id uuid,
  p_nome_etapa text,
  p_codigo_erro text,
  p_mensagem_erro text,
  p_detalhes jsonb default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid;
  v_versao_obra_id uuid;
  v_estado_execucao text;
  v_etapa_atual text;
begin
  if p_detalhes is not null and jsonb_typeof(p_detalhes) <> 'object' then
    raise exception 'detalhes_devem_ser_objeto' using errcode = '22023';
  end if;

  select e.usuario_id, e.versao_obra_id, e.estado, e.etapa_atual
    into v_usuario_id, v_versao_obra_id, v_estado_execucao, v_etapa_atual
  from processamento.execucoes e
  where e.id = p_execucao_id
  for update;

  if v_usuario_id is null then return false; end if;

  if v_estado_execucao in ('concluido', 'cancelado', 'falhou')
     or v_etapa_atual is distinct from p_nome_etapa then
    return false;
  end if;

  update processamento.etapas_execucao
  set estado = 'falhou',
      concluido_em = now(),
      duracao_ms = case
        when iniciado_em is null then duracao_ms
        else greatest(0, (extract(epoch from (now() - iniciado_em)) * 1000)::bigint)
      end,
      detalhes_auxiliares = coalesce(p_detalhes, detalhes_auxiliares)
  where execucao_id = p_execucao_id
    and nome_etapa = p_nome_etapa
    and estado not in ('concluida', 'cancelada');

  update processamento.execucoes
  set estado = 'falhou',
      etapa_atual = p_nome_etapa,
      concluido_em = now(),
      codigo_erro = left(coalesce(p_codigo_erro, 'PROCESSAMENTO_FALHOU'), 120),
      mensagem_erro = left(coalesce(p_mensagem_erro, 'Falha no processamento'), 500),
      workflow_reservado_em = null
  where id = p_execucao_id;

  update biblioteca.versoes_obras
  set estado_processamento = 'falhou'
  where id = v_versao_obra_id and usuario_id = v_usuario_id;

  return true;
end;
$$;

revoke all on function aplicacao.backend_registrar_workflow_iniciado(uuid) from public, anon, authenticated;
revoke all on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) from public, anon, authenticated;
revoke all on function aplicacao.backend_concluir_etapa(uuid, text, numeric, text, text, jsonb) from public, anon, authenticated;
revoke all on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) from public, anon, authenticated;

grant execute on function aplicacao.backend_registrar_workflow_iniciado(uuid) to service_role;
grant execute on function aplicacao.backend_iniciar_etapa(uuid, text, text, numeric) to service_role;
grant execute on function aplicacao.backend_concluir_etapa(uuid, text, numeric, text, text, jsonb) to service_role;
grant execute on function aplicacao.backend_falhar_execucao(uuid, text, text, text, jsonb) to service_role;


-- ==========================================
-- File: 20260916223016_0020_artefatos_intermediarios_processamento.sql
-- ==========================================

-- 0020_artefatos_intermediarios_processamento
-- Persiste metadados/proveniência de artefatos intermediários sem confundi-los
-- com um Documento Processado publicado. O conteúdo grande permanece em Storage privado.

insert into storage.buckets (id, name, public)
values ('artefatos-processamento', 'artefatos-processamento', false)
on conflict (id) do update set public = false;

create table if not exists processamento.artefatos_execucao (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  execucao_id uuid not null,
  tipo text not null,
  caminho_arquivo text not null,
  tipo_mime text not null,
  tamanho_bytes bigint not null,
  hash_sha256 text not null,
  metadados jsonb not null default '{}'::jsonb,
  criado_em timestamptz not null default now(),
  constraint artefatos_execucao_execucao_usuario_fk
    foreign key (execucao_id, usuario_id)
    references processamento.execucoes(id, usuario_id)
    on delete cascade,
  constraint artefatos_execucao_tipo_check
    check (tipo in ('conteudo_extraido', 'conteudo_normalizado')),
  constraint artefatos_execucao_tamanho_check check (tamanho_bytes >= 0),
  constraint artefatos_execucao_hash_check check (hash_sha256 ~ '^[0-9a-f]{64}$'),
  constraint artefatos_execucao_metadados_objeto_check check (jsonb_typeof(metadados) = 'object'),
  constraint artefatos_execucao_tipo_unico unique (execucao_id, tipo),
  constraint artefatos_execucao_caminho_unico unique (caminho_arquivo)
);

create index if not exists artefatos_execucao_execucao_usuario_idx
  on processamento.artefatos_execucao (execucao_id, usuario_id);
create index if not exists artefatos_execucao_usuario_criado_idx
  on processamento.artefatos_execucao (usuario_id, criado_em desc);

alter table processamento.artefatos_execucao enable row level security;
revoke all on processamento.artefatos_execucao from public, anon, authenticated, service_role;

create or replace function aplicacao.backend_obter_artefato_execucao(
  p_execucao_id uuid,
  p_tipo text
)
returns table (
  artefato_id uuid,
  usuario_id uuid,
  execucao_id uuid,
  tipo text,
  caminho_arquivo text,
  tipo_mime text,
  tamanho_bytes bigint,
  hash_sha256 text,
  metadados jsonb,
  criado_em timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select a.id, a.usuario_id, a.execucao_id, a.tipo, a.caminho_arquivo,
         a.tipo_mime, a.tamanho_bytes, a.hash_sha256, a.metadados, a.criado_em
  from processamento.artefatos_execucao a
  where a.execucao_id = p_execucao_id and a.tipo = p_tipo
  limit 1
$$;

create or replace function aplicacao.backend_registrar_artefato_execucao(
  p_execucao_id uuid,
  p_tipo text,
  p_caminho_arquivo text,
  p_tipo_mime text,
  p_tamanho_bytes bigint,
  p_hash_sha256 text,
  p_metadados jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario_id uuid;
  v_artefato_id uuid;
  v_hash_existente text;
  v_caminho_existente text;
  v_caminho_esperado text;
begin
  if p_tipo not in ('conteudo_extraido', 'conteudo_normalizado') then
    raise exception 'tipo_artefato_invalido' using errcode = '22023';
  end if;
  if p_tamanho_bytes is null or p_tamanho_bytes < 0 then
    raise exception 'tamanho_artefato_invalido' using errcode = '22023';
  end if;
  if p_hash_sha256 is null or lower(p_hash_sha256) !~ '^[0-9a-f]{64}$' then
    raise exception 'hash_artefato_invalido' using errcode = '22023';
  end if;
  if p_metadados is null or jsonb_typeof(p_metadados) <> 'object' then
    raise exception 'metadados_artefato_devem_ser_objeto' using errcode = '22023';
  end if;

  select e.usuario_id into v_usuario_id
  from processamento.execucoes e
  where e.id = p_execucao_id;

  if v_usuario_id is null then
    raise exception 'execucao_nao_encontrada' using errcode = 'P0002';
  end if;

  v_caminho_esperado := v_usuario_id::text || '/' || p_execucao_id::text || '/' || p_tipo || '.json';
  if p_caminho_arquivo is distinct from v_caminho_esperado then
    raise exception 'caminho_artefato_invalido' using errcode = '22023';
  end if;

  if not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'artefatos-processamento'
      and o.name = p_caminho_arquivo
  ) then
    raise exception 'artefato_storage_nao_encontrado' using errcode = 'P0002';
  end if;

  select a.id, a.hash_sha256, a.caminho_arquivo
    into v_artefato_id, v_hash_existente, v_caminho_existente
  from processamento.artefatos_execucao a
  where a.execucao_id = p_execucao_id and a.tipo = p_tipo
  for update;

  if v_artefato_id is not null then
    if v_hash_existente = lower(p_hash_sha256)
       and v_caminho_existente = p_caminho_arquivo then
      return v_artefato_id;
    end if;
    raise exception 'artefato_execucao_divergente' using errcode = '23505';
  end if;

  insert into processamento.artefatos_execucao (
    usuario_id, execucao_id, tipo, caminho_arquivo, tipo_mime,
    tamanho_bytes, hash_sha256, metadados
  ) values (
    v_usuario_id, p_execucao_id, p_tipo, p_caminho_arquivo, p_tipo_mime,
    p_tamanho_bytes, lower(p_hash_sha256), p_metadados
  )
  returning id into v_artefato_id;

  return v_artefato_id;
end;
$$;

revoke all on function aplicacao.backend_obter_artefato_execucao(uuid, text) from public, anon, authenticated;
revoke all on function aplicacao.backend_registrar_artefato_execucao(uuid, text, text, text, bigint, text, jsonb) from public, anon, authenticated;

grant execute on function aplicacao.backend_obter_artefato_execucao(uuid, text) to service_role;
grant execute on function aplicacao.backend_registrar_artefato_execucao(uuid, text, text, text, bigint, text, jsonb) to service_role;


-- ==========================================
-- File: 20260916225622_0021_politica_negacao_artefatos_processamento.sql
-- ==========================================

-- 0021_politica_negacao_artefatos_processamento
-- Torna explícito que artefatos intermediários são backend-only.
-- A policy não concede privilégios; grants de tabela/schema continuam revogados.

drop policy if exists artefatos_execucao_sem_acesso_cliente on processamento.artefatos_execucao;
create policy artefatos_execucao_sem_acesso_cliente
  on processamento.artefatos_execucao
for all
to anon, authenticated
using (false)
with check (false);


