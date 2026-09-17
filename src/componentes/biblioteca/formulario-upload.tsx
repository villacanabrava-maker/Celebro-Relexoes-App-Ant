'use client'

import { useState, type FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import { createSHA256 } from 'hash-wasm'
import { Upload } from 'tus-js-client'
import { createClient } from '@/infraestrutura/supabase/client'

type Etapa = 'pronto' | 'hash' | 'upload' | 'registro' | 'concluido' | 'erro'

const TIPOS_OBRA = [
  ['livro', 'Livro'],
  ['capitulo', 'Capítulo'],
  ['artigo', 'Artigo'],
  ['carta', 'Carta'],
  ['reflexao', 'Reflexão'],
  ['ensaio', 'Ensaio'],
  ['relato', 'Relato'],
  ['mensagem', 'Mensagem'],
  ['anotacao', 'Anotação'],
  ['transcricao', 'Transcrição'],
  ['documento_profissional', 'Documento profissional'],
  ['material_metodologico', 'Material metodológico'],
  ['referencia_externa', 'Referência externa'],
  ['outro', 'Outro'],
] as const

function extensaoDoArquivo(nome: string) {
  const indice = nome.lastIndexOf('.')
  if (indice <= 0 || indice === nome.length - 1) return null
  return nome.slice(indice + 1).toLowerCase()
}

async function calcularSha256(
  arquivo: File,
  aoProgredir: (percentual: number) => void
) {
  const hash = await createSHA256()
  hash.init()

  const tamanhoBloco = 4 * 1024 * 1024
  let processado = 0

  for (let inicio = 0; inicio < arquivo.size; inicio += tamanhoBloco) {
    const fim = Math.min(inicio + tamanhoBloco, arquivo.size)
    const bloco = new Uint8Array(await arquivo.slice(inicio, fim).arrayBuffer())
    hash.update(bloco)
    processado = fim
    aoProgredir(arquivo.size === 0 ? 100 : Math.round((processado / arquivo.size) * 100))
  }

  if (arquivo.size === 0) aoProgredir(100)
  return hash.digest('hex') as string
}

async function enviarArquivoResumivel({
  arquivo,
  caminho,
  aoProgredir,
}: {
  arquivo: File
  caminho: string
  aoProgredir: (percentual: number) => void
}) {
  const supabase = createClient()
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY

  if (!supabaseUrl || !publishableKey) {
    throw new Error('Supabase não configurado neste ambiente.')
  }

  const {
    data: { session },
  } = await supabase.auth.getSession()

  if (!session?.access_token) {
    throw new Error('Sua sessão expirou. Entre novamente.')
  }

  const projectId = new URL(supabaseUrl).hostname.split('.')[0]
  if (!projectId) throw new Error('Não foi possível identificar o projeto Supabase.')

  await new Promise<void>((resolve, reject) => {
    const upload = new Upload(arquivo, {
      endpoint: `https://${projectId}.storage.supabase.co/storage/v1/upload/resumable`,
      retryDelays: [0, 3000, 5000, 10000, 20000],
      headers: {
        authorization: `Bearer ${session.access_token}`,
        apikey: publishableKey,
      },
      uploadDataDuringCreation: true,
      removeFingerprintOnSuccess: true,
      metadata: {
        bucketName: 'originais-biblioteca',
        objectName: caminho,
        contentType: arquivo.type || 'application/octet-stream',
        cacheControl: '3600',
      },
      chunkSize: 6 * 1024 * 1024,
      onError(error) {
        reject(error)
      },
      onProgress(bytesUploaded, bytesTotal) {
        const percentual = bytesTotal === 0 ? 100 : Math.round((bytesUploaded / bytesTotal) * 100)
        aoProgredir(percentual)
      },
      onSuccess() {
        resolve()
      },
    })

    // Retomada entre reloads só voltará quando os IDs da operação forem persistentes.
    // Os retries TUS desta operação continuam ativos.
    upload.start()
  })
}

export function FormularioUploadBiblioteca() {
  const router = useRouter()

  const [arquivo, setArquivo] = useState<File | null>(null)
  const [titulo, setTitulo] = useState('')
  const [tipoObra, setTipoObra] = useState('livro')
  const [autoria, setAutoria] = useState<'autoral' | 'externa'>('autoral')
  const [participacao, setParticipacao] = useState('autoral_prioritaria')
  const [autorOriginal, setAutorOriginal] = useState('')
  const [idioma, setIdioma] = useState('pt-BR')
  const [dataProducao, setDataProducao] = useState('')
  const [descricao, setDescricao] = useState('')
  const [etapa, setEtapa] = useState<Etapa>('pronto')
  const [progresso, setProgresso] = useState(0)
  const [mensagem, setMensagem] = useState<string | null>(null)

  const ocupado = etapa === 'hash' || etapa === 'upload' || etapa === 'registro'

  function alterarAutoria(valor: 'autoral' | 'externa') {
    setAutoria(valor)
    setParticipacao(valor === 'autoral' ? 'autoral_prioritaria' : 'externa_referencia')
  }

  async function enviar(evento: FormEvent<HTMLFormElement>) {
    evento.preventDefault()
    setMensagem(null)

    if (!arquivo || !titulo.trim()) {
      setEtapa('erro')
      setMensagem('Selecione um arquivo e informe um título.')
      return
    }

    const supabase = createClient()
    const obraId = crypto.randomUUID()
    const versaoId = crypto.randomUUID()
    const extensao = extensaoDoArquivo(arquivo.name)
    const nomeOriginalStorage = `original${extensao ? `.${extensao}` : ''}`
    let caminhoArquivo: string | null = null

    try {
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      const usuarioId = user?.id

      if (userError || !usuarioId) {
        throw new Error('Sua sessão não pôde ser validada. Entre novamente.')
      }

      caminhoArquivo = `${usuarioId}/${obraId}/${versaoId}/${nomeOriginalStorage}`

      setEtapa('hash')
      setProgresso(0)
      const hashSha256 = await calcularSha256(arquivo, setProgresso)

      setEtapa('upload')
      setProgresso(0)
      await enviarArquivoResumivel({
        arquivo,
        caminho: caminhoArquivo,
        aoProgredir: setProgresso,
      })

      setEtapa('registro')
      setProgresso(100)

      const { error: registroError } = await supabase
        .schema('aplicacao')
        .rpc('registrar_obra_arquivo', {
          p_obra_id: obraId,
          p_versao_id: versaoId,
          p_titulo: titulo.trim(),
          p_tipo_obra: tipoObra,
          p_autoria: autoria,
          p_participacao_cerebro: participacao,
          p_idioma: idioma.trim() || 'pt-BR',
          p_nome_arquivo: arquivo.name,
          p_caminho_arquivo: caminhoArquivo,
          p_tipo_mime: arquivo.type || 'application/octet-stream',
          p_tamanho_bytes: arquivo.size,
          p_hash_sha256: hashSha256,
          p_extensao: extensao,
          p_descricao: descricao.trim() || null,
          p_data_producao: dataProducao || null,
          p_autor_original: autoria === 'externa' ? autorOriginal.trim() || null : null,
        })

      if (registroError) {
        await supabase.storage.from('originais-biblioteca').remove([caminhoArquivo])

        if (registroError.message.includes('arquivo_duplicado_por_hash')) {
          throw new Error('Este arquivo já existe na sua Biblioteca. O upload duplicado foi descartado.')
        }

        throw new Error('O arquivo foi enviado, mas o registro da obra falhou e o upload foi revertido.')
      }

      setEtapa('concluido')
      setMensagem('Original preservado e obra registrada com sucesso.')
      router.push('/biblioteca?status=enviado')
      router.refresh()
    } catch (error) {
      setEtapa('erro')
      setMensagem(error instanceof Error ? error.message : 'Não foi possível concluir o envio.')
    }
  }

  return (
    <form onSubmit={enviar}>
      <section className="card card-padding">
        <div className="card-header">
          <div>
            <h2>Novo conteúdo</h2>
            <p>
              O original será preservado no Storage privado e registrado antes do futuro
              processamento documental.
            </p>
          </div>
          <span className="status status-neutro">Upload real</span>
        </div>

        <h3>1. Arquivo original</h3>
        <div className="vazio" style={{ padding: 28, marginBottom: 24 }}>
          <div className="icone-vazio">⇧</div>
          <h3>{arquivo ? arquivo.name : 'Selecione um arquivo'}</h3>
          <p>O arquivo original nunca será sobrescrito pelo processamento.</p>
          <input
            id="arquivo"
            type="file"
            disabled={ocupado}
            required
            onChange={(evento) => setArquivo(evento.target.files?.[0] ?? null)}
          />
          {arquivo ? (
            <small style={{ display: 'block', marginTop: 10, color: 'var(--text-muted)' }}>
              {(arquivo.size / 1024 / 1024).toFixed(2)} MB · {arquivo.type || 'tipo não informado'}
            </small>
          ) : null}
        </div>

        <div className="form-grid">
          <div className="grupo-campo full">
            <label htmlFor="titulo">Título</label>
            <input
              className="campo"
              id="titulo"
              value={titulo}
              onChange={(evento) => setTitulo(evento.target.value)}
              placeholder="Ex.: Reflexão sobre o futuro"
              required
              disabled={ocupado}
            />
          </div>

          <div className="grupo-campo">
            <label htmlFor="tipo">Tipo</label>
            <select id="tipo" value={tipoObra} onChange={(evento) => setTipoObra(evento.target.value)} disabled={ocupado}>
              {TIPOS_OBRA.map(([valor, rotulo]) => (
                <option key={valor} value={valor}>{rotulo}</option>
              ))}
            </select>
          </div>

          <div className="grupo-campo">
            <label htmlFor="autoria">Autoria</label>
            <select
              id="autoria"
              value={autoria}
              onChange={(evento) => alterarAutoria(evento.target.value as 'autoral' | 'externa')}
              disabled={ocupado}
            >
              <option value="autoral">Autoral</option>
              <option value="externa">Externa</option>
            </select>
          </div>

          <div className="grupo-campo">
            <label htmlFor="participacao">Participação no Cérebro</label>
            <select
              id="participacao"
              value={participacao}
              onChange={(evento) => setParticipacao(evento.target.value)}
              disabled={ocupado}
            >
              {autoria === 'autoral' ? (
                <>
                  <option value="autoral_prioritaria">Autoral prioritária</option>
                  <option value="excluida_cerebro">Excluída do Cérebro</option>
                </>
              ) : (
                <>
                  <option value="externa_referencia">Externa — referência</option>
                  <option value="excluida_cerebro">Excluída do Cérebro</option>
                </>
              )}
            </select>
          </div>

          <div className="grupo-campo">
            <label htmlFor="idioma">Idioma</label>
            <input className="campo" id="idioma" value={idioma} onChange={(evento) => setIdioma(evento.target.value)} disabled={ocupado} />
          </div>

          {autoria === 'externa' ? (
            <div className="grupo-campo full">
              <label htmlFor="autor-original">Autor original</label>
              <input
                className="campo"
                id="autor-original"
                value={autorOriginal}
                onChange={(evento) => setAutorOriginal(evento.target.value)}
                placeholder="Nome do autor ou fonte externa"
                disabled={ocupado}
              />
            </div>
          ) : null}

          <div className="grupo-campo">
            <label htmlFor="data-producao">Data de produção</label>
            <input
              className="campo"
              id="data-producao"
              type="date"
              value={dataProducao}
              onChange={(evento) => setDataProducao(evento.target.value)}
              disabled={ocupado}
            />
          </div>

          <div className="grupo-campo full">
            <label htmlFor="observacoes">Observações</label>
            <textarea
              id="observacoes"
              value={descricao}
              onChange={(evento) => setDescricao(evento.target.value)}
              placeholder="Contexto opcional sobre a origem ou importância deste material..."
              disabled={ocupado}
            />
          </div>
        </div>

        {etapa !== 'pronto' ? (
          <div className="login-seguranca" style={{ marginTop: 20 }} role={etapa === 'erro' ? 'alert' : 'status'}>
            {etapa === 'hash' ? `Verificando integridade — SHA-256 ${progresso}%` : null}
            {etapa === 'upload' ? `Enviando original de forma resumível — ${progresso}%` : null}
            {etapa === 'registro' ? 'Registrando obra e versão no banco…' : null}
            {etapa === 'concluido' || etapa === 'erro' ? mensagem : null}
          </div>
        ) : null}

        <button
          className="botao botao-primario botao-bloco"
          style={{ marginTop: 20 }}
          type="submit"
          disabled={ocupado || !arquivo || !titulo.trim()}
        >
          {ocupado ? 'Enviando…' : 'Preservar original e registrar obra'}
        </button>
      </section>
    </form>
  )
}
