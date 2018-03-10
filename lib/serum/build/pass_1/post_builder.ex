defmodule Serum.Build.Pass1.PostBuilder do
  @moduledoc """
  During Pass1, PostBuilder does the following:

  1. Scans `/path/to/project/posts/` directory for any post source files. All
    files which name ends with `.md` will be loaded.
  2. Parses headers of all scanned post source files.
  3. Reads the contents of each post source file and converts to HTML using
    Earmark.
  4. Generates `Serum.Post` object for each post and stores them for later
    use in the second pass.
  """

  import Serum.Util
  alias Serum.Result
  alias Serum.Post

  @doc "Starts the first pass of PostBuilder."
  @spec run(Build.mode(), map()) :: Result.t([Post.t()])

  def run(mode, proj) do
    files = load_file_list(proj.src)
    result = launch(mode, files, proj)
    Result.aggregate_values(result, :post_builder)
  end

  @spec load_file_list(binary()) :: [binary()]

  defp load_file_list(src) do
    IO.puts("Collecting posts information...")
    post_dir = (src == "." && "posts") || Path.join(src, "posts")

    if File.exists?(post_dir) do
      [post_dir, "*.md"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.sort()
    else
      warn("Cannot access `posts/'. No post will be generated.")
      []
    end
  end

  @spec launch(Build.mode(), [binary], map()) :: [Result.t(Post.t())]
  defp launch(mode, files, proj)

  defp launch(:parallel, files, proj) do
    files
    |> Task.async_stream(Post, :load, [proj])
    |> Enum.map(&elem(&1, 1))
  end

  defp launch(:sequential, files, proj) do
    files |> Enum.map(&Post.load(&1, proj))
  end
end
