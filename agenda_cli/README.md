# AgendaCLI — Agenda de Contatos em Elixir

Aplicação de linha de comando (CLI) para gerenciamento de uma agenda de contatos pessoais, desenvolvida em Elixir com paradigma funcional.

---

## Requisitos

- [Elixir](https://elixir-lang.org/install.html) >= 1.14
- [Mix](https://hexdocs.pm/mix/Mix.html) (incluído com Elixir)

---

## Instalação

```bash
# Clone o repositório
git clone <url-do-repositorio>
cd agenda_cli

# Instale as dependências
mix deps.get
```

---

## Execução

```bash
mix run -e "AgendaCli.main([])"
```

---

## Comandos disponíveis

| Comando | Exemplo | Descrição |
|---|---|---|
| `add` | `add --name Ana Lima --company Acme --phone 85912345678 --email ana@acme.com` | Adiciona contato |
| `edit <id>` | `edit 123 --phone 85999999999` | Edita campo(s) de um contato |
| `del <id>` | `del 123` | Remove um contato |
| `show <id>` | `show 123` | Exibe detalhes de um contato |
| `list` | `list` | Lista todos os contatos |
| `search` | `search --name ana` | Busca por nome, telefone ou e-mail |
| `exit` | `exit` | Encerra a aplicação |

### Flags do search

```
search --name <valor>    # busca parcial por nome (case-insensitive)
search --phone <valor>   # busca parcial por telefone
search --email <valor>   # busca parcial por e-mail
```

---

## Persistência

Os contatos são salvos automaticamente em `contacts.json` no diretório de execução. O arquivo é carregado ao iniciar a aplicação.

---

## Arquitetura

```
lib/
├── agenda_cli.ex              # Ponto de entrada, loop interativo, parse de comandos
└── agenda_cli/
    ├── contacts.ex            # Funções puras de manipulação da lista
    └── store.ex               # Leitura e escrita do arquivo JSON
```

### Decisões de implementação

- **Loop interativo**: implementado via recursão de cauda (`loop/1`) — sem bibliotecas externas.
- **Parse de comandos**: usa pattern matching em cláusulas de `handle/2` para cada comando.
- **Parse de flags**: função `parse_flags/1` divide a string por `--` e extrai pares chave/valor.
- **Imutabilidade**: nenhuma variável global ou estado mutável; o estado da lista é passado como argumento em cada chamada recursiva.
- **Serialização**: dependência `Jason` para encode/decode JSON.