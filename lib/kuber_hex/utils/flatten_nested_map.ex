defmodule Utils.Json do
  def flatten(map) when is_map(map) do
    map
    |> to_list_of_tuples
    |> Enum.into(%{})
  end

  defp to_list_of_tuples(m) do
    m
    |> Enum.map(&process/1)
    |> List.flatten
  end

  defp process({key, sub_map}) when is_map(sub_map) do
    for { sub_key, value } <- flatten(sub_map) do
      { "#{key}.#{sub_key}", value }
    end
  end

  defp process(next), do: next
end
