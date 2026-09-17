import test from 'node:test'
import assert from 'node:assert/strict'
import { Buffer } from 'node:buffer'
import { identificarFormatoDocumento } from '../../src/dominios/processamento/identificar-formato.ts'
import {
  extrairTextoPdf,
  extrairTextoUtf8,
} from '../../src/dominios/processamento/extrair-conteudo.ts'
import {
  normalizarArtefatoExtraido,
  validarArtefatoNormalizado,
} from '../../src/dominios/processamento/normalizar-conteudo.ts'
import { identificarEstruturaConteudo } from '../../src/dominios/processamento/identificar-estrutura.ts'


const encoder = new TextEncoder()

function bytes(texto) {
  return encoder.encode(texto)
}

function criarPdfTexto(texto = 'Teste PDF') {
  const objetos = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ]

  const escapado = texto.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)')
  const stream = `BT\n/F1 18 Tf\n72 720 Td\n(${escapado}) Tj\nET\n`
  objetos.push(`<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}endstream`)

  let pdf = '%PDF-1.4\n'
  const offsets = [0]

  for (let i = 0; i < objetos.length; i += 1) {
    offsets.push(Buffer.byteLength(pdf))
    pdf += `${i + 1} 0 obj\n${objetos[i]}\nendobj\n`
  }

  const xref = Buffer.byteLength(pdf)
  pdf += `xref\n0 ${objetos.length + 1}\n`
  pdf += '0000000000 65535 f \n'

  for (let i = 1; i < offsets.length; i += 1) {
    pdf += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`
  }

  pdf += `trailer\n<< /Size ${objetos.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`
  return bytes(pdf)
}

function artefatoTexto(conteudo, formato = 'texto') {
  return {
    schema_version: 1,
    formato,
    encoding: 'utf-8',
    metodo: 'utf8_deterministico',
    fonte: {
      nome_arquivo: formato === 'markdown' ? 'ensaio.md' : 'ensaio.txt',
      tipo_mime_registrado: formato === 'markdown' ? 'text/markdown' : 'text/plain',
      hash_sha256_original: 'e'.repeat(64),
    },
    total_paginas: null,
    conteudo,
  }
}

test('identifica PDF apenas quando extensão, MIME e assinatura são coerentes', () => {
  const resultado = identificarFormatoDocumento({
    nomeArquivo: 'obra.pdf',
    mimeRegistrado: 'application/pdf',
    amostra: bytes('%PDF-1.7\n'),
  })

  assert.equal(resultado.suportado, true)
  if (resultado.suportado) assert.equal(resultado.formato, 'pdf')

  const falso = identificarFormatoDocumento({
    nomeArquivo: 'obra.pdf',
    mimeRegistrado: 'application/pdf',
    amostra: bytes('isto não é um PDF'),
  })

  assert.equal(falso.suportado, false)
  if (!falso.suportado) assert.equal(falso.motivo, 'assinatura_incompativel')
})

test('identifica TXT e Markdown UTF-8 e rejeita binário disfarçado', () => {
  const txt = identificarFormatoDocumento({
    nomeArquivo: 'notas.txt',
    mimeRegistrado: 'text/plain; charset=utf-8',
    amostra: bytes('Texto em português: ação e reflexão.'),
  })
  assert.equal(txt.suportado, true)
  if (txt.suportado) assert.equal(txt.formato, 'texto')

  const md = identificarFormatoDocumento({
    nomeArquivo: 'ensaio.md',
    mimeRegistrado: 'text/markdown',
    amostra: bytes('# Título\n\nConteúdo'),
  })
  assert.equal(md.suportado, true)
  if (md.suportado) assert.equal(md.formato, 'markdown')

  const binario = identificarFormatoDocumento({
    nomeArquivo: 'falso.txt',
    mimeRegistrado: 'text/plain',
    amostra: new Uint8Array([0x41, 0x00, 0x42]),
  })
  assert.equal(binario.suportado, false)
  if (!binario.suportado) assert.equal(binario.motivo, 'conteudo_binario_em_texto')
})

test('DOCX permanece explicitamente fora do escopo desta versão', () => {
  const resultado = identificarFormatoDocumento({
    nomeArquivo: 'livro.docx',
    mimeRegistrado: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    amostra: new Uint8Array([0x50, 0x4b, 0x03, 0x04]),
  })

  assert.equal(resultado.suportado, false)
  if (!resultado.suportado) assert.equal(resultado.motivo, 'docx_ainda_nao_suportado')
})

test('extrai TXT UTF-8, remove BOM e rejeita conteúdo vazio ou inválido', () => {
  const valido = extrairTextoUtf8({
    dados: bytes('\uFEFFPrimeiro parágrafo.\n\nSegundo parágrafo.'),
    formato: 'texto',
    nomeArquivo: 'texto.txt',
    tipoMimeRegistrado: 'text/plain',
    hashSha256Original: 'a'.repeat(64),
  })

  assert.equal(valido.ok, true)
  if (valido.ok) {
    assert.equal(valido.artefato.conteudo?.startsWith('Primeiro'), true)
    assert.equal(valido.quantidadePaginas, null)
  }

  const vazio = extrairTextoUtf8({
    dados: bytes('   \n\n  '),
    formato: 'texto',
    nomeArquivo: 'vazio.txt',
    tipoMimeRegistrado: 'text/plain',
    hashSha256Original: 'b'.repeat(64),
  })
  assert.equal(vazio.ok, false)
  if (!vazio.ok) assert.equal(vazio.codigo, 'CONTEUDO_VAZIO')

  const invalido = extrairTextoUtf8({
    dados: new Uint8Array([0xc3, 0x28]),
    formato: 'texto',
    nomeArquivo: 'invalido.txt',
    tipoMimeRegistrado: 'text/plain',
    hashSha256Original: 'c'.repeat(64),
  })
  assert.equal(invalido.ok, false)
  if (!invalido.ok) assert.equal(invalido.codigo, 'CONTEUDO_TEXTO_INVALIDO')
})

test('extrai texto de PDF preservando a referência da página', async () => {
  const resultado = await extrairTextoPdf({
    dados: criarPdfTexto('Teste PDF'),
    nomeArquivo: 'teste.pdf',
    tipoMimeRegistrado: 'application/pdf',
    hashSha256Original: 'd'.repeat(64),
  })

  assert.equal(resultado.ok, true)
  if (!resultado.ok) return

  assert.equal(resultado.quantidadePaginas, 1)
  assert.equal(resultado.paginasComTexto, 1)
  assert.equal(resultado.artefato.paginas?.[0]?.numero, 1)
  assert.match(resultado.artefato.paginas?.[0]?.conteudo ?? '', /Teste PDF/)
})

test('normaliza Unicode em NFC e quebras de linha sem apagar escolhas autorais', () => {
  const entrada = artefatoTexto('Cafe\u0301\r\nLinha 2\rLinha 3  \nLigatura: ﬀ — “aspas”')
  const resultado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: 'f'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(resultado.ok, true)
  if (!resultado.ok) return

  assert.equal(
    resultado.artefato.conteudo,
    'Café\nLinha 2\nLinha 3  \nLigatura: ﬀ — “aspas”'
  )
  assert.equal(resultado.artefato.normalizacao.unicode, 'NFC')
  assert.equal(resultado.artefato.normalizacao.alteracoes.quebras_crlf_convertidas, 1)
  assert.equal(resultado.artefato.normalizacao.alteracoes.quebras_cr_isoladas_convertidas, 1)
  assert.equal(resultado.artefato.normalizacao.alteracoes.segmentos_alterados_nfc, 1)
})

test('NFC preserva distinções de compatibilidade que NFKC apagaria', () => {
  const entrada = artefatoTexto('ﬀ ① Ａ')
  const resultado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '1'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(resultado.ok, true)
  if (resultado.ok) assert.equal(resultado.artefato.conteudo, 'ﬀ ① Ａ')
})

test('normalização preserva espaços significativos de Markdown', () => {
  const entrada = artefatoTexto('Linha com quebra Markdown  \r\ncontinuação', 'markdown')
  const resultado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '2'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(resultado.ok, true)
  if (resultado.ok) assert.equal(resultado.artefato.conteudo, 'Linha com quebra Markdown  \ncontinuação')
})

test('normalização preserva ordem e números das páginas de PDF', () => {
  const entrada = {
    schema_version: 1,
    formato: 'pdf',
    encoding: 'utf-8',
    metodo: 'unpdf_pdfjs_texto',
    fonte: {
      nome_arquivo: 'livro.pdf',
      tipo_mime_registrado: 'application/pdf',
      hash_sha256_original: 'e'.repeat(64),
    },
    total_paginas: 2,
    paginas: [
      { numero: 1, conteudo: 'Pa\u0301gina 1\r\ntexto' },
      { numero: 2, conteudo: 'Página 2' },
    ],
  }

  const resultado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '3'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(resultado.ok, true)
  if (!resultado.ok) return
  assert.deepEqual(resultado.artefato.paginas, [
    { numero: 1, conteudo: 'Página 1\ntexto' },
    { numero: 2, conteudo: 'Página 2' },
  ])
})

test('normalização rejeita artefato ligado a outro original', () => {
  const entrada = artefatoTexto('Conteúdo')
  const resultado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '4'.repeat(64),
    hashOriginalEsperado: '9'.repeat(64),
  })

  assert.equal(resultado.ok, false)
  if (!resultado.ok) assert.equal(resultado.codigo, 'ARTEFATO_EXTRAIDO_ORIGINAL_DIVERGENTE')
})

test('artefato normalizado válido mantém cadeia de proveniência do original e da extração', () => {
  const entrada = artefatoTexto('Cafe\u0301\r\nTexto autoral')
  const normalizado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '5'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(normalizado.ok, true)
  if (!normalizado.ok) return

  const validacao = validarArtefatoNormalizado({
    bytes: bytes(JSON.stringify(normalizado.artefato)),
    hashOriginalEsperado: 'e'.repeat(64),
    hashArtefatoExtraidoEsperado: '5'.repeat(64),
  })

  assert.equal(validacao.ok, true)
  if (validacao.ok) assert.equal(validacao.artefato.conteudo, 'Café\nTexto autoral')
})

test('artefato normalizado é rejeitado se apontar para outra extração', () => {
  const entrada = artefatoTexto('Conteúdo')
  const normalizado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '6'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(normalizado.ok, true)
  if (!normalizado.ok) return

  const validacao = validarArtefatoNormalizado({
    bytes: bytes(JSON.stringify(normalizado.artefato)),
    hashOriginalEsperado: 'e'.repeat(64),
    hashArtefatoExtraidoEsperado: '7'.repeat(64),
  })

  assert.equal(validacao.ok, false)
  if (!validacao.ok) assert.equal(validacao.codigo, 'ARTEFATO_NORMALIZADO_ORIGEM_DIVERGENTE')
})

test('identifica estrutura de documento Markdown com partes e capítulos', () => {
  const entrada = artefatoTexto('# Parte 1: Introdução\n\n## Capítulo 1: Fundamentos\n\nEste é um parágrafo autoral.', 'markdown')
  const normalizado = normalizarArtefatoExtraido({
    bytes: bytes(JSON.stringify(entrada)),
    hashArtefatoExtraido: '8'.repeat(64),
    hashOriginalEsperado: 'e'.repeat(64),
  })

  assert.equal(normalizado.ok, true)
  if (!normalizado.ok) return

  const estruturado = identificarEstruturaConteudo(normalizado.artefato, 'a'.repeat(64))
  assert.equal(estruturado.schema_version, 1)
  assert.equal(estruturado.metadados.total_partes, 1)
  assert.equal(estruturado.metadados.total_capitulos, 1)
  assert.equal(estruturado.metadados.contem_hierarquia_explicitada, true)
  assert.equal(estruturado.elementos.length, 3)
})

