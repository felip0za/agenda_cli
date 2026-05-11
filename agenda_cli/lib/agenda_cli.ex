defmodule AgendaCli do
  alias AgendaCli.{Contacts, Store}

  @doc "Ponto de entrada da aplicação."
  def main(_args) do
    IO.puts("""
    ╔══════════════════════════════════╗
    ║      Agenda de Contatos CLI      ║
    ║  Digite 'help' para ver comandos ║
    ╚══════════════════════════════════╝
    """)

    contacts = Store.load()
    loop(contacts)
  end

  # Loop interativo com recursão de cauda
  defp loop(contacts) do
    input = IO.gets("agenda> ") |> String.trim()
    handle(input, contacts)
  end

  # Despacha cada comando via pattern matching
  defp handle("exit", _contacts) do
    IO.puts("Até logo!")
  end

  defp handle("help", contacts) do
    IO.puts("""
    Comandos disponíveis:
      add --name <nome> --company <empresa> --phone <tel> --email <email>
      edit <id> --name <nome> --phone <tel> --email <email> --company <empresa>
      del <id>
      show <id>
      list
      search --name <valor>
      search --phone <valor>
      search --email <valor>
      exit
    """)
    loop(contacts)
  end

  defp handle("list", contacts) do
    case contacts do
      [] ->
        IO.puts("Nenhum contato cadastrado.")

      _ ->
        header =
          String.pad_trailing("ID", 16) <>
          " | " <> String.pad_trailing("Nome", 20) <>
          " | " <> String.pad_trailing("Empresa", 20) <>
          " | " <> String.pad_trailing("Telefone", 15) <>
          " | " <> "E-mail"

        IO.puts("\n" <> header)
        IO.puts(String.duplicate("-", 100))

        contacts
        |> Enum.each(fn c ->
          line =
            String.pad_trailing(to_string(c.id), 16) <>
            " | " <> String.pad_trailing(c.name, 20) <>
            " | " <> String.pad_trailing(c.company, 20) <>
            " | " <> String.pad_trailing(c.phone, 15) <>
            " | " <> c.email

          IO.puts(line)
        end)

        IO.puts("")
    end

    loop(contacts)
  end

  defp handle("add" <> rest, contacts) do
    fields = parse_flags(rest)

    required = [:name, :company, :phone, :email]
    missing = Enum.reject(required, &Keyword.has_key?(fields, &1))

    if missing == [] do
      updated = Contacts.add(contacts, fields)
      Store.save(updated)
      IO.puts("Contato adicionado com sucesso!")
      loop(updated)
    else
      IO.puts("Campos obrigatórios faltando: #{Enum.join(missing, ", ")}")
      loop(contacts)
    end
  end

  defp handle("del " <> rest, contacts) do
    id = rest |> String.trim() |> parse_id()

    case id do
      nil ->
        IO.puts("ID inválido.")
        loop(contacts)

      id ->
        case Contacts.find_by_id(contacts, id) do
          {:error, :not_found} ->
            IO.puts("Contato não encontrado.")
            loop(contacts)

          {:ok, _} ->
            updated = Contacts.delete(contacts, id)
            Store.save(updated)
            IO.puts("Contato removido com sucesso!")
            loop(updated)
        end
    end
  end

  defp handle("show " <> rest, contacts) do
    id = rest |> String.trim() |> parse_id()

    case id do
      nil ->
        IO.puts("ID inválido.")

      id ->
        case Contacts.find_by_id(contacts, id) do
          {:error, :not_found} ->
            IO.puts("Contato não encontrado.")

          {:ok, c} ->
            IO.puts("""
            ┌─────────────────────────────────┐
            │ ID:      #{c.id}
            │ Nome:    #{c.name}
            │ Empresa: #{c.company}
            │ Telefone:#{c.phone}
            │ E-mail:  #{c.email}
            └─────────────────────────────────┘
            """)
        end
    end

    loop(contacts)
  end

  defp handle("edit " <> rest, contacts) do
    {id_str, flags_str} = split_id_and_flags(rest)
    id = parse_id(id_str)
    fields = parse_flags(flags_str)

    cond do
      id == nil ->
        IO.puts("ID inválido.")
        loop(contacts)

      fields == [] ->
        IO.puts("Nenhum campo para editar informado.")
        loop(contacts)

      true ->
        case Contacts.find_by_id(contacts, id) do
          {:error, :not_found} ->
            IO.puts("Contato não encontrado.")
            loop(contacts)

          {:ok, _} ->
            updated = Contacts.edit(contacts, id, fields)
            Store.save(updated)
            IO.puts("Contato atualizado com sucesso!")
            loop(updated)
        end
    end
  end

  defp handle("search " <> rest, contacts) do
    case parse_search(rest) do
      {:error, msg} ->
        IO.puts(msg)
        loop(contacts)

      criteria ->
        results = Contacts.search(contacts, criteria)

        case results do
          [] ->
            IO.puts("Nenhum contato encontrado.")

          _ ->
            IO.puts("\nResultados encontrados: #{length(results)}")
            IO.puts(String.duplicate("-", 85))

            results
            |> Enum.each(fn c ->
              IO.puts("ID: #{c.id} | Nome: #{c.name} | Empresa: #{c.company} | Tel: #{c.phone} | E-mail: #{c.email}")
            end)

            IO.puts("")
        end

        loop(contacts)
    end
  end

  defp handle("", contacts), do: loop(contacts)

  defp handle(unknown, contacts) do
    IO.puts("Comando desconhecido: '#{unknown}'. Digite 'help' para ver os comandos.")
    loop(contacts)
  end

  # Parse de flags no formato --key value --key2 value2
  defp parse_flags(str) do
    str
    |> String.trim()
    |> String.split(~r/\s+--/, trim: true)
    |> Enum.reduce([], fn part, acc ->
      part = String.trim_leading(part, "--")

      case String.split(part, " ", parts: 2) do
        [key, value] ->
          acc ++ [{String.to_atom(key), String.trim(value)}]

        _ ->
          acc
      end
    end)
  end

  @doc "Parse do comando search: retorna tupla {:campo, valor} ou {:error, msg}."
  def parse_search(str) do
    str = String.trim(str)

    cond do
      String.starts_with?(str, "--name ") ->
        {:name, String.trim_leading(str, "--name ")}

      String.starts_with?(str, "--phone ") ->
        {:phone, String.trim_leading(str, "--phone ")}

      String.starts_with?(str, "--email ") ->
        {:email, String.trim_leading(str, "--email ")}

      true ->
        {:error, "Flag inválida. Use --name, --phone ou --email."}
    end
  end

  # Converte string para integer, retorna nil se inválido
  defp parse_id(str) do
    case Integer.parse(String.trim(str)) do
      {id, ""} -> id
      _ -> nil
    end
  end

  # Separa o ID das flags no comando edit
  defp split_id_and_flags(str) do
    str = String.trim(str)

    case String.split(str, " ", parts: 2) do
      [id] -> {id, ""}
      [id, rest] -> {id, rest}
    end
  end
end
