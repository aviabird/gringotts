defmodule Mix.Tasks.Gringotts.New do
  @shortdoc """
  Generates a barebones implementation for a gateway.
  """
  
  @moduledoc """
  Generates a barebones implementation for a gateway.

  It expects the (brand) name of the gateway as argument. This will not
  necessarily be the module name, but we recommend the name be capitalized.

  mix gringotts.new NAME [-m, --module MODULE] [--url URL]

  A barebones implementation of the gateway will be created along with skeleton
  mock and integration tests in `lib/gringotts/gateways/`. The command will
  prompt for the module name, and other metadata.
  
  ## Options

  > ***Tip!***
  > You can supply the extra arguments to `gringotts.new` to skip (some of) the
  > prompts.
  
  * `-m` `--module` - The module name for the Gateway.
  * `--url` - The homepage of the gateway.

  ## Examples

      mix gringotts.new foobar

  The prompts for this will be:
  MODULE = `Foobar`
  URL = `https://www.foobar.com`
  REQUIRED_KEYS = []
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
        switches: [module: :string, url: :string],
        aliases: [m: :module]
      )

    Mix.Shell.IO.info("Generating barebones implementation for #{name}.")
    Mix.Shell.IO.info("Hit enter to select the suggestion.")

    module_name =
      case Keyword.fetch(key_list, :module) do
        :error -> prompt_with_suggestion("\nModule name", String.capitalize(name))
        {:ok, mod_name} -> mod_name
      end
    
    url =
      case Keyword.fetch(key_list, :url) do
        :error -> prompt_with_suggestion("\nHomepage URL", "https://www.#{String.Casing.downcase(name)}.com")
        {:ok, url} -> url
      end
    
    required_keys =
      case Mix.Shell.IO.prompt(@long_msg) |> String.trim do
        "" -> []
        keys -> String.split(keys, ",") |> Enum.map(&(String.trim(&1))) |>  Enum.map(&(String.to_atom(&1)))
      end

    bindings = [
      gateway: name,
      gateway_module: module_name,
      gateway_underscore: Macro.underscore(name),
      required_config_keys: required_keys,
      gateway_url: url
    ]

    if (Mix.Shell.IO.yes? "\nDoes this look good?\n#{inspect(bindings, pretty: true)}\n>") do
      gateway = EEx.eval_file("templates/gateway.eex", bindings)
      # mock = ""
      # integration = ""
      create_file("lib/gringotts/gateways/#{bindings[:gateway_underscore]}.ex", gateway)
    else
      Mix.Shell.IO.info("Doing nothing, bye!")
    end
  end

  defp prompt_with_suggestion(message, suggestion) do
    decorated_message = "#{message} [#{suggestion}]"
    response = Mix.Shell.IO.prompt(decorated_message) |> String.trim
    if response == "", do: suggestion, else: response
  end
end
