defmodule Mix.Tasks.Compile.Leex do
  use Mix.Task.Compiler
  alias Mix.Compilers.Erlang

  @recursive true
  @manifest ".compile.leex"

  # These options can't be controlled with :leex_options.
  @forced_opts [report: true,
                return_errors: false,
                return_warnings: false]

  @moduledoc """
  Compiles Leex source files.

  When this task runs, it will check the modification time of every file, and
  if it has changed, the file will be compiled. Files will be
  compiled in the same source directory with a .erl extension.
  You can force compilation regardless of modification times by passing
  the `--force` option.

  ## Command line options

    * `--force` - forces compilation regardless of modification times

  ## Configuration

    * `:erlc_paths` - directories to find source files. Defaults to `["src"]`.

    * `:leex_options` - compilation options that apply
      to Leex's compiler.

      For a complete list of options,
      see [`:leex.file/2`](http://www.erlang.org/doc/man/leex.html#file-2).
      Note that the `:report`, `:return_errors`, and `:return_warnings` options
      are overridden by this compiler, thus setting them has no effect.

  """

  @doc """
  Runs this task.
  """
  @spec run(OptionParser.argv) :: :ok | :noop
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean, verbose: :boolean])

    project = Mix.Project.config

    source_paths = project[:erlc_paths]
    Mix.Compilers.Erlang.assert_valid_erlc_paths(source_paths)
    mappings = Enum.zip(source_paths, source_paths)

    options = project[:leex_options] || []
    unless is_list(options) do
      Mix.raise ":leex_options should be a list of options, got: #{inspect(options)}"
    end

    Erlang.compile(manifest(), mappings, :xrl, :erl, opts, fn
      input, output ->
        Erlang.ensure_application!(:parsetools, input)
        options = options ++ @forced_opts ++ [scannerfile: Erlang.to_erl_file(output)]
        :leex.file(Erlang.to_erl_file(input), options)
    end)
  end

  @doc """
  Returns Leex manifests.
  """
  def manifests, do: [manifest()]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  @doc """
  Cleans up compilation artifacts.
  """
  def clean do
    Erlang.clean(manifest())
  end
end
