defmodule Mix.Tasks.Gringotts.New do
  @shortdoc """
  Generates a barebones implementation for a gateway.
  """

  @moduledoc """
  Generates a barebones implementation for a gateway.

  It expects the (brand) name of the gateway as argument and we recommend that
  it be capitalized. *This will not necessarily be the module name*.

  ```
  mix gringotts.new NAME [-m, --module MODULE] [-f, --file FILENAME] [--url URL]
  ```

  A barebones implementation of the gateway will be created along with skeleton
  mock and integration tests in `lib/gringotts/gateways/`. The command will
  prompt for the module name, and other metadata.

  ## Options

  > ***Tip!***
  > You can supply the extra arguments to `gringotts.new` to skip (some of) the
  > prompts.

  * `-m` `--module` - The module name for the Gateway.
  * `-f` `--file` - The filename.
  * `--url` - The homepage of the gateway.

  ## Examples

      mix gringotts.new FooBar

  The prompts for this will be:
  ```
  MODULE = "Foobar"
  URL = "https://www.foobar.com"
  FILENAME = "foo_bar.ex"
  ```
  """

  use Mix.Task
  import Mix.Generator

  @long_msg ~s{
Comma separated list of required configuration keys:
(This can be skipped by hitting `Enter`)
> }

  def run(args) do
    {key_list, [name], []} =
      OptionParser.parse(
        args,
        switches: [module: :string, url: :string, file: :string],
        aliases: [m: :module, f: :file]
      )

    Mix.Shell.IO.info("Generating barebones implementation for #{name}.")
    Mix.Shell.IO.info("Hit enter to select the suggestion.")

    module_suggestion =
      name |> String.split() |> Enum.map(&String.capitalize(&1)) |> Enum.join("")

    module_name =
      case Keyword.fetch(key_list, :module) do
        :error ->
          prompt_with_suggestion("\nModule name", module_suggestion)

        {:ok, mod_name} ->
          mod_name
      end

    url =
      case Keyword.fetch(key_list, :url) do
        :error ->
          prompt_with_suggestion(
            "\nHomepage URL",
            "https://www.#{String.downcase(module_suggestion)}.com"
          )

        {:ok, url} ->
          url
      end

    file_name =
      case Keyword.fetch(key_list, :file) do
        :error ->
          prompt_with_suggestion("\nFilename", Macro.underscore(module_name) <> ".ex")

        {:ok, filename} ->
          filename
      end

    file_base_name = String.slice(file_name, 0..-4)

    required_keys =
      case Mix.Shell.IO.prompt(@long_msg) |> String.trim() do
        "" ->
          []

        keys ->
          String.split(keys, ",") |> Enum.map(&String.trim(&1)) |> Enum.map(&String.to_atom(&1))
      end

    bindings = [
      gateway: name,
      gateway_module: module_name,
      gateway_underscore: file_name,
      # The key :gateway_filename is not used in any template as of now.
      gateway_filename: "#{file_name}",
      required_config_keys: required_keys,
      gateway_url: url,
      mock_test_filename: "#{file_base_name}_test.exs",
      mock_response_filename: "#{file_base_name}_mock.exs"
    ]

    if Mix.Shell.IO.yes?(
         "\nDoes this look good?\n#{inspect(bindings, pretty: true, width: 40)}\n>"
       ) do
      gateway = EEx.eval_file("templates/gateway.eex", bindings)
      mock = EEx.eval_file("templates/test.eex", bindings)
      mock_response = EEx.eval_file("templates/mock_response.eex", bindings)
      integration = EEx.eval_file("templates/integration.eex", bindings)

      create_file("lib/gringotts/gateways/#{bindings[:gateway_filename]}", gateway)
      create_file("test/integration/gateways/#{bindings[:mock_test_filename]}", integration)

      if Mix.Shell.IO.yes?("\nAlso create empty mock test suite?\n>") do
        create_file("test/gateways/#{bindings[:mock_test_filename]}", mock)
        create_file("test/mocks/#{bindings[:mock_response_filename]}", mock_response)
      end
    else
      Mix.Shell.IO.info("Doing nothing, bye!")
    end
  end

  defp prompt_with_suggestion(message, suggestion) do
    decorated_message = "#{message} [#{suggestion}]"
    response = Mix.Shell.IO.prompt(decorated_message) |> String.trim()
    if response == "", do: suggestion, else: response
  end
end
