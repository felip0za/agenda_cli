defmodule AgendaCli.Contacts do
  @doc "Adiciona um novo contato à lista."
  def add(contacts, fields) do
    new_contact = %{
      id: System.os_time(:millisecond),
      name: Keyword.get(fields, :name, ""),
      company: Keyword.get(fields, :company, ""),
      phone: Keyword.get(fields, :phone, ""),
      email: Keyword.get(fields, :email, "")
    }

    contacts ++ [new_contact]
  end

  @doc "Remove um contato pelo ID."
  def delete(contacts, id) do
    contacts
    |> Enum.reject(fn c -> c.id == id end)
  end

  @doc "Edita campos de um contato existente pelo ID."
  def edit(contacts, id, fields) do
    contacts
    |> Enum.map(fn c ->
      if c.id == id do
        fields
        |> Enum.reduce(c, fn {key, value}, acc ->
          Map.put(acc, key, value)
        end)
      else
        c
      end
    end)
  end

  @doc "Busca um contato pelo ID. Retorna {:ok, contato} ou {:error, :not_found}."
  def find_by_id(contacts, id) do
    case Enum.find(contacts, fn c -> c.id == id end) do
      nil -> {:error, :not_found}
      contact -> {:ok, contact}
    end
  end

  @doc "Busca contatos por campo (case-insensitive, substring)."
  def search(contacts, {:name, value}) do
    contacts
    |> Enum.filter(fn c ->
      c.name
      |> String.downcase()
      |> String.contains?(String.downcase(value))
    end)
  end

  def search(contacts, {:phone, value}) do
    contacts
    |> Enum.filter(fn c ->
      String.contains?(c.phone, value)
    end)
  end

  def search(contacts, {:email, value}) do
    contacts
    |> Enum.filter(fn c ->
      c.email
      |> String.downcase()
      |> String.contains?(String.downcase(value))
    end)
  end
end
