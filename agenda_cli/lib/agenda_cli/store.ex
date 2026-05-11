defmodule AgendaCli.Store do
  @file_path "contacts.json"

  @doc "Carrega contatos do arquivo JSON. Retorna lista vazia se não existir."
  def load do
    case File.read(@file_path) do
      {:ok, content} ->
        content
        |> Jason.decode!()
        |> Enum.map(&atomize_keys/1)

      {:error, :enoent} ->
        []

      {:error, reason} ->
        IO.puts("Erro ao ler arquivo: #{reason}")
        []
    end
  end

  @doc "Salva a lista de contatos no arquivo JSON."
  def save(contacts) do
    contacts
    |> Jason.encode!(pretty: true)
    |> then(&File.write!(@file_path, &1))
  end

  # Converte chaves string do JSON para átomos
  defp atomize_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
  end
end
