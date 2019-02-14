defmodule AotJobs.DBManager do
  @moduledoc ""

  require Logger
  alias Aot.Repo

  @doc ""
  @spec delete_old_observations(binary()) :: :ok
  def delete_old_observations(interval) do
    _ = Logger.info("dropping observations older than #{interval}")

    sql = """
    SELECT drop_chunks(interval '#{interval}', table_name => 'observations');
    """

    _ = Repo.query!(sql)
    :ok
  end
end
